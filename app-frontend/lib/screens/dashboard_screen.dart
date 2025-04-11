import 'package:flutter/material.dart';
import 'package:flutter_application_1/themes/theme_provider.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> data; // Accept JSON data

  const DashboardScreen({Key? key, required this.data}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    List<dynamic> predictions = widget.data["predictions"] ?? [];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Color.fromARGB(255, 51, 85, 255), size: 30),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
        const SizedBox(height: 5),
        IconButton(
          icon: const Icon(Icons.brightness_6),
          onPressed: () {
            Provider.of<ThemeProvider>(context, listen: false).toogleTheme();
          },
        ),
      ],
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                "Dashboard",
                style: TextStyle(
                  color: Color.fromARGB(255, 51, 85, 255),
                  fontWeight: FontWeight.w900,
                  fontFamily: "Roboto",
                  fontSize: 28,
                ),
              ),
              SizedBox(height: 5),
              Text(
                "Your data, your decisions",
                style: TextStyle(
                  // color: Colors.black87,
                  fontFamily: "Roboto",
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 20),

              // Prediction Table
              Text(
                "Predictions & Compliance Status",
                style: TextStyle(
                  // color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),

              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: predictions.map((prediction) {
                    return RuleItem(
                      ruleText: prediction["text"],
                      status: prediction["compliance_status"],
                      summary: prediction["related_articles"]!= null ? prediction["related_articles"][0]["article"] : "",
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Reusable Card Widget for Displaying Data
class DataCard extends StatelessWidget {
  final String title;
  final String content;
  final bool highlight;

  const DataCard({
    required this.title,
    required this.content,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? Color.fromARGB(255, 51, 85, 255) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color:
                  highlight ? Colors.white : Color.fromARGB(255, 51, 85, 255),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 16,
              color: highlight ? Colors.white : Colors.black87,
            ),
            softWrap: true,
          ),
        ],
      ),
    );
  }
}

// Rule Item Widget
class RuleItem extends StatelessWidget {
  final String ruleText;
  final String status;
  final String summary;

  const RuleItem({
    required this.ruleText,
    required this.status,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    bool isViolated = status.toLowerCase() == "violation";

    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Icon
          Icon(
            isViolated ? Icons.warning_amber_rounded : Icons.check_circle,
            color: isViolated ? Colors.redAccent : Colors.green,
            size: 24,
          ),
          SizedBox(width: 12),

          // Text Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ruleText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isViolated ? Colors.redAccent : Colors.green,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  summary,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
