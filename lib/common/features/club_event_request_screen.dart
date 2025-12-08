import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/common/widgets/cal_poly_menu_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ClubEventRequestScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const ClubEventRequestScreen({super.key, required this.scaffoldKey});

  @override
  ClubEventRequestScreenState createState() => ClubEventRequestScreenState();
}

class ClubEventRequestScreenState extends State<ClubEventRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _eventNameController = TextEditingController();
  final _clubNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  List<Map<String, dynamic>> _clubs = [];
  String? _selectedClubId;
  String? _selectedRecurrence;
  // recurrence details
  String? _recurrenceWeekday;
  int? _recurrenceMonthDay;
  String? _recurrenceInterval;
  // TimeOfDay? _recurrenceTime;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isSubmitting = false;

  DateTime? _startTime;
  DateTime? _endTime;
  DateTime? _recurrenceEndDate;

  @override
  void initState() {
    super.initState();
    _loadAdminClubs();
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _clubNameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminClubs() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception("User not logged in");

      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final clubIds = List<String>.from(userDoc.data()?['clubsAdminOf'] ?? []);

      if (clubIds.isEmpty) {
        setState(() {
          _isLoading = false;
          _clubs = [];
        });
        return;
      }

      final clubsSnapshot = await FirebaseFirestore.instance
          .collection('clubs')
          .where(FieldPath.documentId, whereIn: clubIds)
          .get();

      final clubs = clubsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'Acronym': data['Acronym'] ?? '',
          'Name': data['Name'] ?? '',
        };
      }).toList();

      setState(() {
        _clubs = clubs;
        _isLoading = false;
        if (_clubs.length == 1) {
          _selectedClubId = _clubs.first['id'];
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      debugPrint('Error loading clubs: $e');
    }
  }

  Future<void> _selectDateTime(BuildContext context, bool isStartTime) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          if (isStartTime) {
            _startTime = selectedDateTime;
          } else {
            _endTime = selectedDateTime;
          }
        });
      }
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end times')),
      );
      return;
    }

    if (_endTime!.isBefore(_startTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Not authenticated');
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      final userData = userDoc.data();
      final userName = userData != null 
          ? '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim()
          : currentUser.displayName ?? currentUser.email ?? 'Unknown';

      final selectedClub = _clubs.firstWhere(
        (club) => club['id'] == _selectedClubId,
        orElse: () => {'Acronym': ''},
      );
      final clubName = selectedClub['Acronym'] ?? '';

      await FirebaseFirestore.instance.collection('clubEventRequests').add({
        'clubId': _selectedClubId,
        'clubName': clubName,
        'eventName': _eventNameController.text.trim(),
        'eventType': 'club',
        'eventLocation': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'startTime': Timestamp.fromDate(_startTime!),
        'endTime': Timestamp.fromDate(_endTime!),
        'requestedByUid': currentUser.uid,
        'requestedByName': userName,
        'requestedByEmail': currentUser.email,
        'status': 'pending',
        // recurrence details
        'recurrenceType': _selectedRecurrence ?? 'Never',
        'recurrenceInterval': _recurrenceInterval,
        // 'recurrenceWeekday': _recurrenceWeekday, 
        // 'recurrenceMonthDay': _recurrenceMonthDay,
        // 'recurrenceIntervalDays': _recurrenceInterval,
        'recurrenceEndDate': _recurrenceEndDate != null ? Timestamp.fromDate(_recurrenceEndDate!) : null,

        'submittedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event request submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      _formKey.currentState!.reset();
      _eventNameController.clear();
      _clubNameController.clear();
      _locationController.clear();
      _descriptionController.clear();
      setState(() {
        _startTime = null;
        _endTime = null;
        _selectedRecurrence = null;
        _recurrenceWeekday = null;
        _recurrenceMonthDay = null;
        _recurrenceInterval = null;
        // _recurrenceTime = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.calPolyGreen,
      body:  _isLoading ? const Center(child: CircularProgressIndicator())
      : _hasError ? Column(
          children: [
            CalPolyMenuBar(scaffoldKey: widget.scaffoldKey),
            const Expanded(child: Center(child: Text('Error loading clubs. Please try again later.'))),
          ],
        )
      : _clubs.isEmpty ? Column(
          children: [
            CalPolyMenuBar(scaffoldKey: widget.scaffoldKey),
            const Expanded(child: Center(child: Text('You are not an admin of any clubs.'))),
          ],
        )
      : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CalPolyMenuBar(scaffoldKey: widget.scaffoldKey),
              const SizedBox(height: 30),
              const Text(
                'Request Club Event',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Submit your event for admin approval',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.zero,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_clubs.length == 1)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade100,
                          ),
                          child: Text(
                            '${_clubs.first['Acronym']} – ${_clubs.first['Name']}',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(fontSize: 16),
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          value: _selectedClubId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Select a club',
                          ),
                          items: _clubs.map((club) {
                            return DropdownMenuItem<String>(
                              value: club['id'],
                              child: Text(
                                '${club['Acronym']} – ${club['Name']}',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedClubId = value);
                          },
                          validator: (value) =>
                              value == null ? 'Please select a club' : null,
                        ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _eventNameController,
                        decoration: const InputDecoration(
                          labelText: 'Event Name *',
                          hintText: 'e.g., General Meeting',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the event name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location *',
                          hintText: 'e.g., Building XYZ, Room 101',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the event location';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description *',
                          hintText: 'Describe your event...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Start Time *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectDateTime(context, true),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.zero,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _startTime == null
                                    ? 'Select start date and time'
                                    : DateFormat('MMM dd, yyyy - hh:mm a')
                                        .format(_startTime!),
                                style: TextStyle(
                                  color: _startTime == null
                                      ? Colors.grey
                                      : Colors.black,
                                ),
                              ),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'End Time *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectDateTime(context, false),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _endTime == null
                                    ? 'Select end date and time'
                                    : DateFormat('MMM dd, yyyy - hh:mm a')
                                        .format(_endTime!),
                                style: TextStyle(
                                  color: _endTime == null
                                      ? Colors.grey
                                      : Colors.black,
                                ),
                              ),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Repeat Frequency *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                          value: _selectedRecurrence,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Choose how often this event occurs',
                          ),
                          items: ["Never", "Weekly", "Monthly", "Interval (days)"]
                              .map((type) => DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(type),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedRecurrence = value;
                              // clear recurrence details when type changes
                              _recurrenceWeekday = null;
                              _recurrenceMonthDay = null;
                              // _recurrenceTime = null;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Please specify how often the event will reccur' : null,
                      ),
                      const SizedBox(height: 16),

                      // Conditional UI: show recurrence-specific controls
                      if (_selectedRecurrence == 'Weekly') ...[
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _recurrenceWeekday,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Repeat weekly on',
                          ),
                          items: [
                            'Monday',
                            'Tuesday',
                            'Wednesday',
                            'Thursday',
                            'Friday',
                            'Saturday',
                            'Sunday',
                          ].map((d) => DropdownMenuItem<String>(value: d, child: Text(d))).toList(),
                          onChanged: (value) => setState(() => _recurrenceInterval = value),
                          validator: (value) => value == null ? 'Please choose a weekday' : null,
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                        onTap: () => _selectDateTime(context, false),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _recurrenceEndDate == null
                                    ? 'Select date to repeat until'
                                    : DateFormat('MMM dd, yyyy - hh:mm a')
                                        .format(_recurrenceEndDate!),
                                style: TextStyle(
                                  color: _recurrenceEndDate == null
                                      ? Colors.grey
                                      : Colors.black,
                                ),
                              ),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                        ),
                      ),
                      ] else if (_selectedRecurrence == 'Monthly') ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Day of month (1–31)',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) {
                            // final parsed = int.tryParse(v);
                            setState(() => _recurrenceInterval = v);
                          },
                          validator: (value) {
                            final n = int.tryParse(value ?? '');
                            if (n == null || n < 1 || n > 31) return 'Enter a valid day (1–31)';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                        onTap: () => _selectDateTime(context, false),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _recurrenceEndDate == null
                                    ? 'Select date to repeat until'
                                    : DateFormat('MMM dd, yyyy - hh:mm a')
                                        .format(_recurrenceEndDate!),
                                style: TextStyle(
                                  color: _recurrenceEndDate == null
                                      ? Colors.grey
                                      : Colors.black,
                                ),
                              ),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                        ),
                      ),
                      ] else if (_selectedRecurrence == 'Interval') ...[
                        const SizedBox(height: 8),
                          TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Time interval between events in days',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) {
                            // final parsed = int.tryParse(v);
                            setState(() => _recurrenceInterval = v);
                          },
                          validator: (value) {
                            final n = int.tryParse(value ?? '');
                            if (n == null || n < 1) return 'Enter a valid number of days';
                            return null;
                          },
                        ),
                        InkWell(
                        onTap: () => _selectDateTime(context, false),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _recurrenceEndDate == null
                                    ? 'Select date to repeat until'
                                    : DateFormat('MMM dd, yyyy - hh:mm a')
                                        .format(_recurrenceEndDate!),
                                style: TextStyle(
                                  color: _recurrenceEndDate == null
                                      ? Colors.grey
                                      : Colors.black,
                                ),
                              ),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                        ),
                      )
                      ],
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkGold,
                            disabledBackgroundColor: Colors.grey,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Submit Request',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}