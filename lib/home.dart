import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final List<Map<String, dynamic>> _historicalData = [];

  @override
  void initState() {
    super.initState();
    _loadHistoricalData();
  }

  Future<void> _loadHistoricalData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    DateTime now = DateTime.now();
    List<Map<String, dynamic>> data = [];

    // Iterate over the last 30 days to fetch historical data
    for (int i = 0; i < 30; i++) {
      DateTime date = now.subtract(Duration(days: i));
      String key = _getKeyForDate(date);
      int? count = prefs.getInt(key);

      if (count != null) {
        data.add({
          'date': date,
          'steps': count,
        });
        // Sync data if it's not today's date
        if (!_isToday(date)) {
          await _syncDataWithAPI(date, count);
        }
      }
    }

    setState(() {
      _historicalData
          .addAll(data.reversed.toList()); // Display most recent data first
    });
  }

  bool _isToday(DateTime date) {
    DateTime now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _getKeyForDate(DateTime date) {
    return 'step_count_${date.year}_${date.month}_${date.day}';
  }

  String _getSyncedKeyForDate(DateTime date) {
    return 'synced_${date.year}_${date.month}_${date.day}';
  }

  Future<void> _syncDataWithAPI(DateTime date, int steps) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String syncedKey = _getSyncedKeyForDate(date);

    // Check if the data for this date has already been synced
    bool isSynced = prefs.getBool(syncedKey) ?? false;

    if (!isSynced) {
      // API request to post the data
      try {
        final response = await http.post(
          Uri.parse(
              'https://health.tixcash.org/api/account/updatestepdata'), // Replace with your API endpoint
          body: jsonEncode({
            "walletid": 6,
            "kcal": 100.0,
            "steps": '$steps',
            "min": 100.0,
          }),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          // Data sent successfully, mark this date as synced
          await prefs.setBool(syncedKey, true);
          print('Data for $date synced successfully.');
        } else {
          print('Failed to sync data for $date.');
        }
      } catch (error) {
        print('Error syncing data for $date: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historical Data'),
      ),
      body: ListView.builder(
        itemCount: _historicalData.length,
        itemBuilder: (context, index) {
          final entry = _historicalData[index];
          final date = entry['date'] as DateTime;
          final dateString =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

          return ListTile(
            title: Text(
              '$dateString: ${entry['steps']} steps',
            ),
          );
        },
      ),
    );
  }
}
