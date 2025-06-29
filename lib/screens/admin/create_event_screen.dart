import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreateEventScreen extends StatefulWidget {
  final String? editEventId;
  final Map<String, dynamic>? existingData;

  const CreateEventScreen({super.key, this.editEventId, this.existingData});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _skillController = TextEditingController();

  final List<String> _skills = [];
  DateTime? _selectedDate;
  int _maxVolunteers = 10;

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _titleController.text = widget.existingData!['title'] ?? '';
      _descController.text = widget.existingData!['description'] ?? '';
      _locationController.text = widget.existingData!['location'] ?? '';
      _skills.addAll(List<String>.from(widget.existingData!['skillsRequired'] ?? []));
      _maxVolunteers = widget.existingData!['maxVolunteers'] ?? 10;
      _selectedDate = (widget.existingData!['date'] as Timestamp).toDate();
    }
  }

  Future<void> _submitEvent() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _selectedDate == null) return;

    final data = {
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'location': _locationController.text.trim(),
      'skillsRequired': _skills,
      'date': Timestamp.fromDate(_selectedDate!),
      'maxVolunteers': _maxVolunteers,
    };

    if (widget.editEventId != null) {
      // Update existing
      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.editEventId)
          .update(data);
    } else {
      // Create new
      await FirebaseFirestore.instance.collection('events').add({
        ...data,
        'createdBy': uid,
        'volunteers': [],
      });
    }

    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editEventId != null ? "Edit Event" : "Create Event"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                  initialDate: _selectedDate ?? DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              child: Text(_selectedDate == null
                  ? "Pick Date"
                  : _selectedDate!.toLocal().toString().split(' ')[0]),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _skillController,
                    decoration: const InputDecoration(labelText: 'Skill'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (_skillController.text.isNotEmpty) {
                      setState(() {
                        _skills.add(_skillController.text.trim());
                        _skillController.clear();
                      });
                    }
                  },
                ),
              ],
            ),
            Wrap(
              spacing: 6.0,
              children: _skills
                  .map(
                    (skill) => Chip(
                      label: Text(skill),
                      onDeleted: () => setState(() => _skills.remove(skill)),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 10),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Max Volunteers'),
              onChanged: (val) {
                final parsed = int.tryParse(val);
                if (parsed != null) {
                  setState(() => _maxVolunteers = parsed);
                }
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitEvent,
              child: Text(widget.editEventId != null ? "Update Event" : "Create Event"),
            ),
          ],
        ),
      ),
    );
  }
}
