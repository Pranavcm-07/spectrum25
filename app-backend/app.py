import pandas as pd
import numpy as np
import torch
import os
import logging
import shap
from fastapi import FastAPI, HTTPException, Header, Depends
from fastapi.responses import JSONResponse
from dotenv import load_dotenv
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from xgboost import XGBClassifier
from sentence_transformers import SentenceTransformer
from sklearn.metrics import accuracy_score, log_loss
from neo4j import GraphDatabase
from pydantic import BaseModel
import google.generativeai as genai  # Gemini API Integration
from fastapi import File, UploadFile

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# --- API Key Management ---
API_KEY = os.getenv("API_KEY")
API_KEY_NAME = "X-API-Key"

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if GEMINI_API_KEY is None:
    raise ValueError("Gemini API key not set")

genai.configure(api_key=GEMINI_API_KEY)
gemini_model = genai.GenerativeModel('gemini-1.5-pro')

def get_api_key(x_api_key: str = Header(...)):
    if x_api_key != API_KEY:
        raise HTTPException(status_code=403, detail="Invalid API Key")
    return x_api_key

# --- FastAPI App ---
app = FastAPI(title="GDPR Compliance API", version="2.0")

# --- Connect to Neo4j ---
NEO4J_URI = "bolt://localhost:7687"
NEO4J_USER = "neo4j"
NEO4J_PASSWORD = "gdprgdpr"  # Replace with actual credentials

driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASSWORD))

# --------------------------------------
# Load & Preprocess Data
# --------------------------------------
def load_and_preprocess_data():
    df1 = pd.read_csv("gdpr_violations_noisy.csv")
    df2 = pd.read_csv("gdpr_text_noisy.csv")
    dataset = pd.concat([df1, df2]).drop_duplicates()
    dataset['summary'] = dataset['summary'].fillna('')

    le = LabelEncoder()
    dataset['condition'] = le.fit_transform(dataset['condition'])  # 0 = Violation, 1 = Compliant

    return dataset, le

# --------------------------------------
# Train-Test Split
# --------------------------------------
def train_test_split_data(dataset):
    return train_test_split(
        dataset['summary'], dataset['condition'], test_size=0.2, random_state=42, stratify=dataset['condition']
    )

# --------------------------------------
# Load LegalBERT Model
# --------------------------------------
def load_legalbert_model():
    device = "cuda" if torch.cuda.is_available() else "cpu"
    model = SentenceTransformer("nlpaueb/legal-bert-base-uncased", device=device)
    return model

# --------------------------------------
# Train XGBoost Model
# --------------------------------------
def train_xgb_model(X_train_embeddings, y_train):
    model = XGBClassifier(eval_metric='logloss', random_state=42)
    model.fit(X_train_embeddings, y_train)
    return model

# --------------------------------------
# Explain Model Predictions with SHAP
# --------------------------------------
def explain_prediction(model, X_sample, feature_map):
    explainer = shap.Explainer(model)
    shap_values = explainer(X_sample)

    # Get top features contributing to the prediction
    importance = np.abs(shap_values.values).mean(axis=0)
    top_indices = np.argsort(importance)[-5:][::-1]  # Top 5 influential features

    # Convert indices to words and ensure JSON serialization
    return {feature_map.get(i, f"Feature_{i}"): float(importance[i]) for i in top_indices}  # Ensure float

# --------------------------------------
# Query Knowledge Graph for GDPR Articles
# --------------------------------------
def get_related_articles(text):
    query = """
    MATCH (e:Entity)-[:MENTIONED_IN]->(a:Article)
    WHERE toLower($text) CONTAINS toLower(e.name)
    RETURN a.name AS article, COLLECT(e.name) AS related_entities
    """
    with driver.session() as session:
        result = session.run(query, text=text)
        articles = [{"article": record["article"], "related_entities": record["related_entities"]} for record in result]
    return articles if articles else None

# --------------------------------------
# Initialize Models
# --------------------------------------
logger.info("Initializing models...")

try:
    dataset, le = load_and_preprocess_data()
    X_train, X_test, y_train, y_test = train_test_split_data(dataset)

    logger.info("Loading LegalBERT model...")
    legalbert_model = load_legalbert_model()
    logger.info("LegalBERT model loaded successfully!")

    logger.info("Encoding training and test data...")
    X_train_embeddings = np.array(legalbert_model.encode(X_train.tolist(), batch_size=16, convert_to_numpy=True))
    X_test_embeddings = np.array(legalbert_model.encode(X_test.tolist(), batch_size=16, convert_to_numpy=True))

    logger.info("Training XGBoost model...")
    xgb_model = train_xgb_model(X_train_embeddings, y_train)
    logger.info("XGBoost model trained successfully!")

    # Store the trained models
    app.state.legalbert_model = legalbert_model
    app.state.xgb_model = xgb_model

    # Store tokenized words
    tokenized_summaries = [text.split() for text in X_train.tolist()]
    feature_names = list(set(word for words in tokenized_summaries for word in words))  # Unique words
    app.state.feature_map = {i: word for i, word in enumerate(feature_names)}  # Index -> Word map

except Exception as e:
    logger.error(f"❌ Error during model initialization: {e}")
    raise RuntimeError("Model initialization failed.")

# --------------------------------------
# Prediction Endpoint
# --------------------------------------
class TextInput(BaseModel):
    text: str

@app.post("/predict_file")
async def predict_file(file: UploadFile = File(...)):
    """
    Accepts a file upload, reads its content sentence by sentence,
    and predicts GDPR compliance for each sentence separately.
    """
    content = await file.read()
    sentences = content.decode("utf-8").strip().split(".")

    results = []
    for sentence in sentences:
        sentence = sentence.strip()
        if sentence:  # Ignore empty sentences
            X_input = np.array(app.state.legalbert_model.encode([sentence], batch_size=1, convert_to_numpy=True))
            prediction = int(app.state.xgb_model.predict(X_input)[0])
            prediction_proba = app.state.xgb_model.predict_proba(X_input)[0]

            shap_explanation = explain_prediction(app.state.xgb_model, X_input, app.state.feature_map)
            compliance_status = "Violation" if prediction == 0 else "Compliant"
            related_articles = get_related_articles(sentence)

            # Gemini Explanation
            prompt = (
                f"Analyze the following text and explain why it is considered in 2 lines '{compliance_status}' "
                f"under GDPR guidelines. Provide a summary and any suggestions for improvement in another 2 lines:\n\n{sentence}"
            )
            try:
                gemini_response = gemini_model.generate_content(prompt)
                gemini_summary = gemini_response.text if gemini_response else "No response from Gemini API."
            except Exception as e:
                logger.error(f"Error with Gemini API: {e}")
                gemini_summary = "Gemini API unavailable."

            results.append({
                "text": sentence,
                "compliance_status": compliance_status,
                "confidence": float(max(prediction_proba)),
                "related_articles": related_articles,
                "shap_values": shap_explanation,
                "gemini_summary": gemini_summary
            })

    return JSONResponse(content={"predictions": results})

# --------------------------------------
# Root Endpoint
# --------------------------------------
@app.get("/")
def read_root(api_key: str = Depends(get_api_key)):
    return {"message": "Welcome to the GDPR Compliance API! Send a text to /predict for analysis."}

# Run the app: uvicorn main:app --reload
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)