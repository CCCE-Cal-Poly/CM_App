import 'package:ccce_application/common/collections/calevent.dart';
import 'package:ccce_application/common/collections/interview.dart';
import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/services/error_logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Student-facing sign-up for an interview block (replaces Microsoft Bookings).
/// Opened from the calendar, an info session's popup, or "My Interviews".
class InterviewSignUpScreen extends StatefulWidget {
  final CalEvent block;
  const InterviewSignUpScreen({super.key, required this.block});

  @override
  State<InterviewSignUpScreen> createState() => _InterviewSignUpScreenState();
}

class _InterviewSignUpScreenState extends State<InterviewSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _majorController = TextEditingController();
  final _minorController = TextEditingController();
  String? _gradTerm;
  int? _gradYear;
  DateTime? _selectedSlot;
  bool _loading = true;
  bool _busy = false;
  InterviewSignup? _existing;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> get _blockRef =>
      FirebaseFirestore.instance.collection('events').doc(widget.block.id);

  InterviewBlockData get _ibd =>
      widget.block.ibd ??
      const InterviewBlockData(
          slotMinutes: 30, interviewersPerSlot: 1, signupsOpen: true);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _majorController.dispose();
    _minorController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = _uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final results = await Future.wait([
        _blockRef.collection('interviewSignups').doc(uid).get(),
        FirebaseFirestore.instance.collection('users').doc(uid).get(),
      ]);
      final signupDoc = results[0];
      final user = results[1].data() ?? {};
      if (_nameController.text.isEmpty) {
        _nameController.text =
            '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
      }
      if (_emailController.text.isEmpty) {
        _emailController.text = (user['email'] ??
                FirebaseAuth.instance.currentUser?.email ??
                '')
            .toString();
      }
      if (!mounted) return;
      setState(() {
        _existing =
            signupDoc.exists ? InterviewSignup.fromSnapshot(signupDoc) : null;
        _loading = false;
      });
    } catch (e) {
      ErrorLogger.logError('InterviewSignUp', 'Error loading sign-up',
          error: e);
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (_selectedSlot == null) {
      _snack('Choose an interview time');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _busy = true);
    try {
      await FirebaseFunctions.instance
          .httpsCallable('signUpForInterview')
          .call(<String, dynamic>{
        'blockId': widget.block.id,
        'slotStartMs': _selectedSlot!.millisecondsSinceEpoch,
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'localPhone': _phoneController.text.trim(),
        'major': _majorController.text.trim(),
        'minor': _minorController.text.trim(),
        'gradTerm': _gradTerm,
        'gradYear': _gradYear,
      });
      _snack("You're signed up!");
      await _load();
    } on FirebaseFunctionsException catch (e) {
      _snack(e.message ?? 'Sign-up failed. Please try again.');
    } catch (e) {
      ErrorLogger.logError('InterviewSignUp', 'Sign-up failed', error: e);
      _snack('Sign-up failed. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text('Cancel interview?'),
        content: const Text(
            'Your time slot will be released so another student can take it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel interview',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await FirebaseFunctions.instance
          .httpsCallable('cancelInterviewSignup')
          .call(<String, dynamic>{'blockId': widget.block.id});
      if (!mounted) return;
      setState(() {
        _existing = null;
        _selectedSlot = null;
      });
      _snack('Interview cancelled');
    } on FirebaseFunctionsException catch (e) {
      _snack(e.message ?? 'Could not cancel. Please try again.');
    } catch (e) {
      ErrorLogger.logError('InterviewSignUp', 'Cancel failed', error: e);
      _snack('Could not cancel. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------------------------------------------------------------------------
  // UI

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final block = widget.block;

    final List<Widget> content;
    if (_uid == null) {
      content = [_message('Sign in to sign up for interviews.')];
    } else if (_existing != null) {
      content = [_confirmation(_existing!, now)];
    } else if (!block.endTime.isAfter(now)) {
      content = [_message('This interview block has ended.')];
    } else if (!_ibd.acceptingSignups(now)) {
      content = [_message('Sign-ups for these interviews are closed.')];
    } else {
      content = [
        _sectionTitle('Choose a time'),
        _slotPicker(now),
        const SizedBox(height: 20),
        _sectionTitle('Your information'),
        _form(now),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _busy ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.yellowButton,
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 48),
            shape:
                const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
          child: _busy
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('SIGN UP',
                  style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ];
    }

    return Scaffold(
      backgroundColor: AppColors.calPolyGreen,
      appBar: AppBar(
        title: const Text('Interview Sign-Up',
            style: TextStyle(
                fontFamily: AppFonts.sansProSemiBold,
                color: AppColors.welcomeLightYellow,
                fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.calPolyGreen,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white))
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _header(),
                  const SizedBox(height: 20),
                  ...content,
                ],
              ),
            ),
    );
  }

  Widget _header() {
    final block = widget.block;
    final company = (block.companyName ?? '').isNotEmpty
        ? block.companyName!
        : block.eventName;
    final deadline = _ibd.signupDeadline;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          eventLogoImage(block.logo, 56, 56),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(company,
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(DateFormat('EEEE, MMM d').format(block.startTime),
                    style: const TextStyle(fontSize: 14)),
                Text(
                    '${DateFormat('h:mm a').format(block.startTime)} – ${DateFormat('h:mm a').format(block.endTime)}'
                    ' · ${_ibd.slotMinutes}-min interviews',
                    style: const TextStyle(fontSize: 14)),
                if (block.eventLocation.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 14, color: AppColors.darkGoldText),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(block.eventLocation,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.darkGoldText)),
                        ),
                      ],
                    ),
                  ),
                if (deadline != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                        'Sign up by ${DateFormat('MMM d, h:mm a').format(deadline)}',
                        style: const TextStyle(
                            fontSize: 12, fontStyle: FontStyle.italic)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                color: AppColors.lightGold,
                fontSize: 22,
                fontWeight: FontWeight.w400)),
      );

  Widget _message(String text) => Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Text(text, style: const TextStyle(fontSize: 15)),
      );

  Widget _slotPicker(DateTime now) {
    final block = widget.block;
    final slots =
        generateSlotStarts(block.startTime, block.endTime, _ibd.slotMinutes);
    if (slots.isEmpty) return _message('No interview times are available.');

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _blockRef.collection('interviewSlots').snapshots(),
      builder: (context, snapshot) {
        final bookedByMs = <int, int>{};
        for (final doc in snapshot.data?.docs ?? const []) {
          final ms = int.tryParse(doc.id);
          final booked = doc.data()['booked'];
          if (ms != null && booked is int) bookedByMs[ms] = booked;
        }
        final capacity = _ibd.interviewersPerSlot;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: slots.map((slot) {
            final left = capacity - (bookedByMs[slot.millisecondsSinceEpoch] ?? 0);
            final disabled = left <= 0 || !slot.isAfter(now);
            var label = DateFormat('h:mm a').format(slot);
            if (left <= 0) {
              label += ' · Full';
            } else if (capacity > 1) {
              label += ' · $left left';
            }
            return ChoiceChip(
              label: Text(label),
              selected: _selectedSlot == slot,
              onSelected:
                  disabled ? null : (_) => setState(() => _selectedSlot = slot),
              selectedColor: AppColors.welcomeLightYellow,
              backgroundColor: Colors.white,
              disabledColor: Colors.grey.shade400,
              showCheckmark: false,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero),
              labelStyle: TextStyle(
                  color: disabled ? Colors.black45 : Colors.black,
                  fontWeight: _selectedSlot == slot
                      ? FontWeight.bold
                      : FontWeight.normal),
            );
          }).toList(),
        );
      },
    );
  }

  InputDecoration _decoration(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
      );

  String? _required(String? value, String field) =>
      (value == null || value.trim().isEmpty) ? 'Please enter your $field' : null;

  Widget _form(DateTime now) {
    final years = List<int>.generate(8, (i) => now.year - 1 + i);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: _decoration('Full Name *'),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().length < 2)
                  ? 'Please enter your full name'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailController,
              decoration: _decoration('Email *'),
              keyboardType: TextInputType.emailAddress,
              validator: validateEmail,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneController,
              decoration: _decoration('Local Phone *', hint: '(805) 555-1234'),
              keyboardType: TextInputType.phone,
              validator: validateUsPhone,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _majorController,
              decoration: _decoration('Major *'),
              textCapitalization: TextCapitalization.words,
              validator: (v) => _required(v, 'major'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _minorController,
              decoration: _decoration('Minor (optional)'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _gradTerm,
                    isExpanded: true,
                    decoration: _decoration('Grad Term *'),
                    items: kGradTerms
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() => _gradTerm = v),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _gradYear,
                    isExpanded: true,
                    decoration: _decoration('Grad Year *'),
                    items: years
                        .map((y) =>
                            DropdownMenuItem(value: y, child: Text('$y')))
                        .toList(),
                    onChanged: (v) => setState(() => _gradYear = v),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _confirmation(InterviewSignup signup, DateTime now) {
    final canCancel =
        signup.slotStart.difference(now) >= kStudentCancelCutoff;
    final slotEnd = signup.slotEnd ??
        signup.slotStart.add(Duration(minutes: _ibd.slotMinutes));
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.calPolyGreen),
              SizedBox(width: 8),
              Text("You're signed up",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
              '${DateFormat('EEEE, MMM d').format(signup.slotStart)}\n'
              '${DateFormat('h:mm a').format(signup.slotStart)} – ${DateFormat('h:mm a').format(slotEnd)}',
              style: const TextStyle(fontSize: 15)),
          if (widget.block.eventLocation.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(widget.block.eventLocation,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.darkGoldText)),
            ),
          const SizedBox(height: 10),
          Text('${signup.fullName} · ${signup.email} · ${signup.localPhone}',
              style: const TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 14),
          if (signup.slotStart.isAfter(now))
            canCancel
                ? OutlinedButton(
                    onPressed: _busy ? null : _cancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero),
                    ),
                    child: const Text('Cancel interview'),
                  )
                : const Text(
                    'Interviews can’t be cancelled within 2 hours of the start time. '
                    'Please contact the CM department.',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}
