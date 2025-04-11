import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dashboard_screen.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> history = [];

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> historyData = prefs.getStringList('upload_history') ?? [];
    setState(() {
      history = historyData.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Upload History")),
      body: history.isEmpty
          ? Center(child: Text("No history available"))
          : ListView.builder(
        itemCount: history.length,
        itemBuilder: (context, index) {
          var item = history[index];
          return Card(
            child: ListTile(
              title: Text(item["file_name"]),
              subtitle: Text("Uploaded on: ${item["timestamp"]}"),
              onTap: () {
                // Open past result in DashboardScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DashboardScreen(data: item["data"]),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
