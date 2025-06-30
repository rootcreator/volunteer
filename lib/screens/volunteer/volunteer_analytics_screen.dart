import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VolunteerAnalyticsScreen extends StatefulWidget {
  const VolunteerAnalyticsScreen({super.key});

  @override
  State<VolunteerAnalyticsScreen> createState() => _VolunteerAnalyticsScreenState();
}

class _VolunteerAnalyticsScreenState extends State<VolunteerAnalyticsScreen> {
  int totalEvents = 0;
  double totalHours = 0.0;
  List<Map<String, dynamic>> attendanceLogs = [];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('events')
        .where('volunteers', arrayContains: uid)
        .get();

    int joinedCount = 0;
    double totalHoursSum = 0.0;
    List<Map<String, dynamic>> logs = [];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final duration = (data['durationHours'] ?? 2).toDouble(); // Default to 2 hours
      final date = (data['date'] as Timestamp).toDate();

      joinedCount++;
      totalHoursSum += duration;

      logs.add({
        'title': data['title'],
        'date': date,
        'duration': duration,
      });
    }

    logs.sort((a, b) => b['date'].compareTo(a['date'])); // most recent first

    setState(() {
      totalEvents = joinedCount;
      totalHours = totalHoursSum;
      attendanceLogs = logs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Analytics")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: ListTile(
                title: const Text("Events Joined"),
                trailing: Text('$totalEvents'),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text("Total Hours Volunteered"),
                trailing: Text('${totalHours.toStringAsFixed(1)} hrs'),
              ),
            ),
            const SizedBox(height: 10),
            const Text("Attendance History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: attendanceLogs.isEmpty
                  ? const Center(child: Text("No attendance yet."))
                  : ListView.builder(
                itemCount: attendanceLogs.length,
                itemBuilder: (context, index) {
                  final log = attendanceLogs[index];
                  return ListTile(
                    title: Text(log['title']),
                    subtitle: Text("📅 ${log['date'].toLocal().toString().split(' ')[0]}"),
                    trailing: Text("${log['duration']}h"),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
