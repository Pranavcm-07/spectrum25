import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/dashboard_screen.dart';
import 'package:flutter_application_1/screens/history_screen.dart';
import 'package:flutter_application_1/themes/theme_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  List<File> selectedFiles = [];

  // Function to Pick Files
  Future<void> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['txt', 'pdf', 'doc', 'png', 'jpg'],
      );

      if (result != null) {
        setState(() {
          selectedFiles
              .addAll(result.files.map((file) => File(file.path!)).toList());
        });
      } else {
        print("User canceled file picking.");
      }
    } catch (e) {
      print("File picking error: $e");
    }
  }

  // Function to Save History
  Future<void> saveToHistory(String fileName, Map<String, dynamic> data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('upload_history') ?? [];

    history.add(jsonEncode({
      "file_name": fileName,
      "data": data,
      "timestamp": DateTime.now().toIso8601String()
    }));

    await prefs.setStringList('upload_history', history);
  }

  // Function to Upload File to Backend
  Future<void> uploadFile() async {
    if (selectedFiles.isEmpty) {
      print("No files selected");
      return;
    }

    File firstFile = selectedFiles.first;
    String fileName = firstFile.path.split('/').last;
    String apiUrl = "http://172.16.45.135:8000/predict_file";
    String apiKey = "abc123secretXYZ";

    if (apiUrl.isEmpty || apiKey.isEmpty) {
      print("API URL or API Key is missing");
      return;
    }

    // Show Loading Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text("Processing file... Please wait"),
          ],
        ),
      ),
    );

    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl))
        ..headers.addAll({"X-API-Key": apiKey})
        ..files.add(await http.MultipartFile.fromPath('file', firstFile.path));

      var response = await request.send();
      Navigator.pop(context); // Close loading dialog

      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        Map<String, dynamic> jsonResponse = json.decode(responseBody);

        // Save result to history
        await saveToHistory(fileName, jsonResponse);

        // Navigate to Dashboard Screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(data: jsonResponse),
          ),
        );
      } else {
        print("Error: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed. Please try again.")),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      print("Upload error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred while uploading.")),
      );
    }
  }

  // Function to Remove a Selected File
  void removeFile(int index) {
    setState(() {
      selectedFiles.removeAt(index);
    });
  }

  // Function to Clear All Selected Files
  void clearAll() {
    setState(() {
      selectedFiles.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Title Section
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Upload Files!",
                        style: TextStyle(
                          color: Color.fromARGB(255, 51, 85, 255),
                          fontWeight: FontWeight.w900,
                          fontFamily: "Roboto",
                          fontSize: 30,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        "Select the files you want to upload.",
                        style: TextStyle(
                          fontFamily: "Roboto",
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    ],
                  )
                ],
              ),

              // Upload Icon & Text
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/images/upload_svg.svg',
                      height: 400,
                      width: 300,
                    ),
                    Text("Upload File",
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Text(
                      "Browse and choose the files\nyou want to upload",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // Upload Button
              Align(
                alignment: Alignment.bottomCenter,
                child: GestureDetector(
                  onTap: pickFile,
                  child: Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 51, 85, 255),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add, size: 30, color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Selected Files Section
              selectedFiles.isEmpty
    ? SizedBox.shrink()
    : Container(
        constraints: BoxConstraints(minHeight: 100.0, maxHeight: 300.0),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: selectedFiles.length,
          itemBuilder: (context, index) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              elevation: 4,
              color: Theme.of(context).colorScheme.tertiary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Icon(
                    Icons.insert_drive_file,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Text(
                  selectedFiles[index].path.split('/').last,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                  onPressed: () => removeFile(index),
                  tooltip: 'Remove file',
                ),
              ),
            );
          },
        ),
      ),
              SizedBox(height: 30),

              // Upload & History Buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: uploadFile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF3B55E6), // Custom blue
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50), // Rounded corners
                        ),
                        padding: EdgeInsets.symmetric(vertical: 16), // Optional: makes button taller
                      ),
                      child: Text(
                        "Send",
                        style: TextStyle(color: Colors.white), // Text color
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => HistoryScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF3B55E6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        "View History",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
