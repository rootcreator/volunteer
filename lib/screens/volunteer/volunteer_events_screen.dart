import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'volunteer_event_detail_screen.dart';

class VolunteerEventsScreen extends StatefulWidget {
  const VolunteerEventsScreen({super.key});

  @override
  State<VolunteerEventsScreen> createState() => _VolunteerEventsScreenState();
}

class _VolunteerEventsScreenState extends State<VolunteerEventsScreen> {
  bool showOnlyJoined = false;
  final uid = FirebaseAuth.instance.currentUser?.uid;

  Future<void> joinEvent(String eventId, List<dynamic> currentVolunteers) async {
    if (uid != null && !currentVolunteers.contains(uid)) {
      await FirebaseFirestore.instance.collection('events').doc(eventId).update({
        'volunteers': FieldValue.arrayUnion([uid])
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Available Events"),
        actions: [
          Row(
            children: [
              const Text("Only Joined", style: TextStyle(fontSize: 12)),
              Switch(
                value: showOnlyJoined,
                onChanged: (val) {
                  setState(() {
                    showOnlyJoined = val;
                  });
                },
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('events').orderBy('date').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final allEvents = snapshot.data!.docs;
          final filteredEvents = allEvents.where((event) {
            final data = event.data() as Map<String, dynamic>;
            final volunteers = List<String>.from(data['volunteers'] ?? []);
            return !showOnlyJoined || (uid != null && volunteers.contains(uid));
          }).toList();

          if (filteredEvents.isEmpty) {
            return const Center(child: Text("No events found."));
          }

          return ListView.builder(
            itemCount: filteredEvents.length,
            itemBuilder: (context, index) {
              final event = filteredEvents[index];
              final data = event.data() as Map<String, dynamic>;
              final eventId = event.id;
              final title = data['title'] ?? '';
              final description = data['description'] ?? '';
              final location = data['location'] ?? '';
              final date = (data['date'] as Timestamp).toDate();
              final volunteers = List<String>.from(data['volunteers'] ?? []);
              final isJoined = uid != null && volunteers.contains(uid);

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(description),
                      const SizedBox(height: 6),
                      Text("📍 $location"),
                      Text("📅 ${date.toLocal().toString().split(' ')[0]}"),
                      Text("👥 Volunteers: ${volunteers.length}"),
                    ],
                  ),
                  trailing: ElevatedButton(
                    child: const Text("View"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VolunteerEventDetailScreen(eventId: eventId),
                        ),
                      );
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VolunteerEventDetailScreen(eventId: eventId),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
