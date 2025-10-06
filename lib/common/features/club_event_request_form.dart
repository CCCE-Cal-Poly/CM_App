import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClubEventRequestForm extends StatefulWidget {
  final String clubId;
  final String clubName;
  final String? clubLogoUrl;

  const ClubEventRequestForm({
    required this.clubId,
    required this.clubName,
    this.clubLogoUrl,
    super.key,
  });

  @override
  State<ClubEventRequestForm> createState() => _ClubEventRequestFormState();
}

class _ClubEventRequestFormState extends State<ClubEventRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _eventNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _eventType = 'club';
  DateTime? _startDateTime;
  DateTime? _endDateTime;
  bool _submitting = false;

  Future<DateTime?> _pickDateTime(BuildContext context, DateTime? initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: initial != null ? TimeOfDay.fromDateTime(initial) : TimeOfDay.now(),
    );
    if (time == null) return DateTime(date.year, date.month, date.day);
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You must be signed in')));
      return;
    }
    if (_startDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please pick a start time')));
      return;
    }

    setState(() => _submitting = true);
    try {
      final doc = {
        'clubId': widget.clubId,
        'clubName': widget.clubName,
        'requestedByUid': user.uid,
        'requestedByName': user.displayName ?? '',
        'requestedByEmail': user.email ?? '',
        'eventName': _eventNameController.text.trim(),
        'startTime': Timestamp.fromDate(_startDateTime!),
        'endTime': _endDateTime != null ? Timestamp.fromDate(_endDateTime!) : null,
        'eventLocation': _locationController.text.trim(),
        'eventType': _eventType.trim().toLowerCase(),
        'description': _descriptionController.text.trim(),
        'logoUrl': widget.clubLogoUrl ?? '',
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance.collection('clubEventRequests').add(doc);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event request submitted')));
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submit failed: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Club Event')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text('Club: ${widget.clubName}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _eventNameController,
                decoration: const InputDecoration(labelText: 'Event Name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _eventType,
                items: const [
                  DropdownMenuItem(value: 'club', child: Text('Club Event')),
                  DropdownMenuItem(value: 'infosession', child: Text('Info Session')),
                  DropdownMenuItem(value: 'careerfair', child: Text('Career Fair')),
                ],
                onChanged: (v) => setState(() => _eventType = v ?? 'club'),
                decoration: const InputDecoration(labelText: 'Event Type'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 4,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final dt = await _pickDateTime(context, _startDateTime);
                      if (dt != null) setState(() => _startDateTime = dt);
                    },
                    child: Text(_startDateTime == null ? 'Pick Start' : 'Start: ${_startDateTime!.toLocal()}'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final dt = await _pickDateTime(context, _endDateTime ?? _startDateTime);
                      if (dt != null) setState(() => _endDateTime = dt);
                    },
                    child: Text(_endDateTime == null ? 'Pick End' : 'End: ${_endDateTime!.toLocal()}'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitting ? null : _submitRequest,
                child: _submitting ? const CircularProgressIndicator() : const Text('Submit Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}