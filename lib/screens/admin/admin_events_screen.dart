import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:csv/csv.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

import 'create_event_screen.dart';

class AdminEventListScreen extends StatefulWidget {
  const AdminEventListScreen({super.key});

  @override
  State<AdminEventListScreen> createState() => _AdminEventListScreenState();
}

class _AdminEventListScreenState extends State<AdminEventListScreen> {
  bool showUpcoming = true;
  List<DocumentSnapshot> allEvents = [];

  void _deleteEvent(BuildContext context, String eventId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('events').doc(eventId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Event deleted")),
      );
    }
  }

  void _exportToCSV() {
    final rows = <List<dynamic>>[
      ["Title", "Location", "Date", "Volunteers"]
    ];

    for (var event in allEvents) {
      final data = event.data() as Map<String, dynamic>;
      final title = data['title'] ?? '';
      final location = data['location'] ?? '';
      final date = (data['date'] as Timestamp).toDate().toString().split(' ')[0];
      final volunteerCount = (data['volunteers'] as List?)?.length ?? 0;

      rows.add([title, location, date, volunteerCount]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    final bytes = utf8.encode(csvData);
    final stream = Stream<List<int>>.fromIterable([bytes]);

    Printing.sharePdf(bytes: bytes, filename: 'events.csv');
  }

  void _exportToPDF() async {
    final rows = <List<dynamic>>[
      ["Title", "Location", "Date", "Volunteers"]
    ];

    for (var event in allEvents) {
      final data = event.data() as Map<String, dynamic>;
      final title = data['title'] ?? '';
      final location = data['location'] ?? '';
      final date = (data['date'] as Timestamp).toDate().toString().split(' ')[0];
      final volunteerCount = (data['volunteers'] as List?)?.length ?? 0;

      rows.add([title, location, date, volunteerCount]);
    }

    final buffer = StringBuffer();
    for (var row in rows) {
      buffer.writeln(row.join('\t'));
    }

    final pdfData = utf8.encode(buffer.toString());
    await Printing.sharePdf(bytes: pdfData, filename: 'events.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("Not authenticated")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage My Events"),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: "Export as CSV",
            onPressed: _exportToCSV,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: "Export as PDF",
            onPressed: _exportToPDF,
          ),
          PopupMenuButton<bool>(
            onSelected: (val) {
              setState(() => showUpcoming = val);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: true, child: Text("Upcoming Events")),
              const PopupMenuItem(value: false, child: Text("Past Events")),
            ],
            icon: const Icon(Icons.filter_list),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .where('createdBy', isEqualTo: uid)
            .orderBy('date')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final now = DateTime.now();
          final events = (snapshot.data?.docs ?? []).where((doc) {
            final date = (doc['date'] as Timestamp).toDate();
            return showUpcoming ? date.isAfter(now) : date.isBefore(now);
          }).toList();

          allEvents = events;

          if (events.isEmpty) {
            return Center(
              child: Text(showUpcoming ? "No upcoming events." : "No past events."),
            );
          }

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final data = event.data() as Map<String, dynamic>;
              final eventDate = (data['date'] as Timestamp).toDate();
              final volunteerCount = (data['volunteers'] as List?)?.length ?? 0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(data['title']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("📍 ${data['location']}"),
                      Text("📅 ${eventDate.toLocal().toString().split(' ')[0]}"),
                      Text("👥 Volunteers: $volunteerCount"),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreateEventScreen(
                                editEventId: event.id,
                                existingData: data,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteEvent(context, event.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
