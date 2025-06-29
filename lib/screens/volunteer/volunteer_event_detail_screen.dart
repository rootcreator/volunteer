import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VolunteerEventDetailScreen extends StatefulWidget {
  final String eventId;

  const VolunteerEventDetailScreen({super.key, required this.eventId});

  @override
  State<VolunteerEventDetailScreen> createState() => _VolunteerEventDetailScreenState();
}

class _VolunteerEventDetailScreenState extends State<VolunteerEventDetailScreen> {
  Map<String, dynamic>? eventData;
  bool isJoined = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchEventData();
  }

  Future<void> _fetchEventData() async {
    final doc = await FirebaseFirestore.instance.collection('events').doc(widget.eventId).get();
    final data = doc.data();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (data != null && uid != null) {
      setState(() {
        eventData = data;
        isJoined = (data['volunteers'] as List).contains(uid);
        loading = false;
      });
    }
  }

  Future<void> _leaveEvent() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('events').doc(widget.eventId).update({
      'volunteers': FieldValue.arrayRemove([uid])
    });

    setState(() {
      isJoined = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You have left the event.")));
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final date = (eventData!['date'] as Timestamp).toDate();

    return Scaffold(
      appBar: AppBar(title: Text(eventData!['title'])),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text("📍 ${eventData!['location']}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text("📅 ${date.toLocal().toString().split(' ')[0]}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text("📝 Description:\n${eventData!['description']}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text("🎯 Skills Required: ${List<String>.from(eventData!['skillsRequired']).join(', ')}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            if (isJoined)
              ElevatedButton.icon(
                icon: const Icon(Icons.exit_to_app),
                label: const Text("Leave Event"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: _leaveEvent,
              )
            else
              const Text("You have not joined this event.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
