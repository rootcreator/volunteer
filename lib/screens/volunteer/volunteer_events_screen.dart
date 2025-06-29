import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VolunteerEventsScreen extends StatelessWidget {
  const VolunteerEventsScreen({super.key});

  Future<void> joinEvent(String eventId, List<dynamic> currentVolunteers) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && !currentVolunteers.contains(uid)) {
      await FirebaseFirestore.instance.collection('events').doc(eventId).update({
        'volunteers': FieldValue.arrayUnion([uid])
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Available Events")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('events').orderBy('date').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final events = snapshot.data!.docs;

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final data = event.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(data['title']),
                  subtitle: Text(data['description']),
                  trailing: ElevatedButton(
                    onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => VolunteerEventDetailScreen(eventId: event.id),
    ),
  );
},

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
