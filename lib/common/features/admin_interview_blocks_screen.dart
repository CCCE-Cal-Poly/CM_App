import 'package:ccce_application/common/collections/calevent.dart';
import 'package:ccce_application/common/collections/company.dart';
import 'package:ccce_application/common/collections/interview.dart';
import 'package:ccce_application/common/providers/company_provider.dart';
import 'package:ccce_application/common/providers/event_provider.dart';
import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/services/error_logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

CollectionReference<Map<String, dynamic>> get _events =>
    FirebaseFirestore.instance.collection('events');

PreferredSizeWidget _greenAppBar(String title, {List<Widget>? actions}) =>
    AppBar(
      title: Text(title,
          style: const TextStyle(
              fontFamily: AppFonts.sansProSemiBold,
              color: AppColors.welcomeLightYellow,
              fontWeight: FontWeight.w600)),
      backgroundColor: AppColors.calPolyGreen,
      foregroundColor: Colors.white,
      actions: actions,
    );

String _blockWhen(CalEvent b) =>
    '${DateFormat('EEE, MMM d').format(b.startTime)} · '
    '${DateFormat('h:mm a').format(b.startTime)} – ${DateFormat('h:mm a').format(b.endTime)}';

/// Admin list of interview blocks, opened from the Admin Control Panel.
class AdminInterviewBlocksScreen extends StatelessWidget {
  const AdminInterviewBlocksScreen({super.key});

  void _openEditor(BuildContext context, [CalEvent? block]) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => InterviewBlockEditorScreen(existing: block)));
  }

  Future<void> _delete(BuildContext context, CalEvent block) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text('Delete interview block?'),
        content: Text(
            '${block.eventName}\n${_blockWhen(block)}\n\nAny students signed up will be notified that their interview was cancelled.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final eventProvider = context.read<EventProvider>();
    try {
      await _events.doc(block.id).delete();
      eventProvider.removeEventById(block.id);
      messenger.showSnackBar(const SnackBar(content: Text('Interview block deleted')));
    } catch (e) {
      ErrorLogger.logError('AdminInterviewBlocks', 'Delete failed', error: e);
      messenger.showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.calPolyGreen,
      appBar: _greenAppBar('Interview Blocks'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        backgroundColor: AppColors.yellowButton,
        foregroundColor: Colors.black,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        icon: const Icon(Icons.add),
        label: const Text('New Interview Block'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _events
            .where('eventType', isEqualTo: kInterviewBlockEventType)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
                child: Text('Error loading interview blocks',
                    style: TextStyle(color: Colors.white)));
          }
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          }
          final now = DateTime.now();
          final blocks = <CalEvent>[];
          for (final doc in snapshot.data!.docs) {
            try {
              blocks.add(CalEvent.fromSnapshot(doc));
            } catch (_) {}
          }
          final upcoming = blocks.where((b) => b.endTime.isAfter(now)).toList()
            ..sort((a, b) => a.startTime.compareTo(b.startTime));
          final past = blocks.where((b) => !b.endTime.isAfter(now)).toList()
            ..sort((a, b) => b.startTime.compareTo(a.startTime));

          if (blocks.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                    'No interview blocks yet.\nTap "New Interview Block" to add one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            );
          }

          Widget header(String text) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(text,
                    style: const TextStyle(
                        color: AppColors.lightGold, fontSize: 22)),
              );

          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              header('Upcoming'),
              if (upcoming.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('None', style: TextStyle(color: Colors.white)),
                ),
              ...upcoming.map((b) => _BlockTile(
                    block: b,
                    onEdit: () => _openEditor(context, b),
                    onDelete: () => _delete(context, b),
                  )),
              if (past.isNotEmpty) header('Past'),
              ...past.map((b) => _BlockTile(
                    block: b,
                    onEdit: () => _openEditor(context, b),
                    onDelete: () => _delete(context, b),
                  )),
            ],
          );
        },
      ),
    );
  }
}

class _BlockTile extends StatelessWidget {
  final CalEvent block;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BlockTile(
      {required this.block, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final ibd = block.ibd;
    final totalSlots = ibd == null
        ? 0
        : generateSlotStarts(block.startTime, block.endTime, ibd.slotMinutes)
                .length *
            ibd.interviewersPerSlot;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: Colors.white,
      child: ListTile(
        leading: eventLogoImage(block.logo, 40, 40),
        title: Text(block.eventName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_blockWhen(block)),
            if (block.eventLocation.isNotEmpty) Text(block.eventLocation),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _events
                  .doc(block.id)
                  .collection('interviewSlots')
                  .snapshots(),
              builder: (context, snap) {
                var booked = 0;
                for (final d in snap.data?.docs ?? const []) {
                  final n = d.data()['booked'];
                  if (n is int) booked += n;
                }
                final closed = ibd != null && !ibd.signupsOpen;
                return Text(
                    '$booked / $totalSlots booked${closed ? ' · sign-ups closed' : ''}',
                    style: const TextStyle(
                        color: AppColors.darkGoldText,
                        fontWeight: FontWeight.w600));
              },
            ),
          ],
        ),
        isThreeLine: true,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => InterviewRosterScreen(block: block))),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') onEdit();
            if (v == 'delete') onDelete();
            if (v == 'roster') {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => InterviewRosterScreen(block: block)));
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'roster', child: Text('View sign-ups')),
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }
}

/// Create or edit an interview block.
class InterviewBlockEditorScreen extends StatefulWidget {
  final CalEvent? existing;
  const InterviewBlockEditorScreen({super.key, this.existing});

  @override
  State<InterviewBlockEditorScreen> createState() =>
      _InterviewBlockEditorScreenState();
}

class _InterviewBlockEditorScreenState
    extends State<InterviewBlockEditorScreen> {
  final _locationController = TextEditingController();
  Company? _company;
  DateTime? _date;
  TimeOfDay? _start;
  TimeOfDay? _end;
  int _slotMinutes = 30;
  int _interviewers = 1;
  bool _signupsOpen = true;
  DateTime? _deadline;
  String? _linkedInfoSessionId;
  int _existingSignups = 0;
  int _originalInterviewers = 1;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;
  bool get _timesLocked => _isEditing && _existingSignups > 0;

  @override
  void initState() {
    super.initState();
    final b = widget.existing;
    if (b != null) {
      final ibd = b.ibd;
      _company = context
              .read<CompanyProvider>()
              .allCompanies
              .where((c) => c.id == b.companyId)
              .firstOrNull ??
          Company(
              id: b.companyId,
              name: b.companyName ?? b.eventName,
              logo: b.logo,
              offeredJobs: {});
      _date = DateTime(b.startTime.year, b.startTime.month, b.startTime.day);
      _start = TimeOfDay.fromDateTime(b.startTime);
      _end = TimeOfDay.fromDateTime(b.endTime);
      _locationController.text = b.eventLocation;
      if (ibd != null) {
        _slotMinutes = ibd.slotMinutes;
        _interviewers = ibd.interviewersPerSlot;
        _originalInterviewers = ibd.interviewersPerSlot;
        _signupsOpen = ibd.signupsOpen;
        _deadline = ibd.signupDeadline;
        _linkedInfoSessionId = ibd.linkedInfoSessionId;
      }
      _loadSignupCount(b.id);
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadSignupCount(String blockId) async {
    try {
      final agg = await _events
          .doc(blockId)
          .collection('interviewSignups')
          .count()
          .get();
      if (mounted) setState(() => _existingSignups = agg.count ?? 0);
    } catch (e) {
      ErrorLogger.logError('InterviewBlockEditor', 'Count failed', error: e);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  DateTime? _combine(TimeOfDay? t) => (_date == null || t == null)
      ? null
      : DateTime(_date!.year, _date!.month, _date!.day, t.hour, t.minute);

  List<CalEvent> _infoSessionsForCompany(Company? company) {
    if (company == null) return const [];
    final key = (company.name ?? '').toString().toLowerCase().trim();
    final cutoff = DateTime.now().subtract(const Duration(days: 120));
    final sessions = context
        .read<EventProvider>()
        .getEventsByType('infoSession')
        .where((e) =>
            e.startTime.isAfter(cutoff) &&
            ((company.id != null && e.companyId == company.id) ||
                e.eventName.toLowerCase().trim() == key))
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    return sessions;
  }

  Future<void> _pickCompany() async {
    final companies = context.read<CompanyProvider>().allCompanies;
    final picked = await showDialog<Company>(
      context: context,
      builder: (dialogContext) {
        var query = '';
        return StatefulBuilder(builder: (context, setDialogState) {
          final q = query.toLowerCase();
          final filtered = companies
              .where((c) => c.name.toString().toLowerCase().contains(q))
              .toList();
          return AlertDialog(
            shape:
                const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            title: const Text('Select company'),
            content: SizedBox(
              width: double.maxFinite,
              height: 420,
              child: Column(
                children: [
                  TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search companies',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.zero),
                    ),
                    onChanged: (v) => setDialogState(() => query = v),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('No matching companies'))
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final c = filtered[i];
                              return ListTile(
                                dense: true,
                                title: Text(c.name.toString()),
                                subtitle: c.isStub
                                    ? const Text('Placeholder entry')
                                    : null,
                                onTap: () => Navigator.pop(dialogContext, c),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel')),
            ],
          );
        });
      },
    );
    if (picked == null) return;
    setState(() {
      if (picked.id != _company?.id) _linkedInfoSessionId = null;
      _company = picked;
    });
    // Convenience: if this company has exactly one recent info session, link it.
    final sessions = _infoSessionsForCompany(picked);
    if (_linkedInfoSessionId == null && sessions.length == 1) {
      _linkSession(sessions.first);
    }
  }

  void _linkSession(CalEvent? session) {
    setState(() {
      _linkedInfoSessionId = session?.id;
      if (session == null) return;
      if (!_timesLocked && _date == null) {
        _date = DateTime(session.startTime.year, session.startTime.month,
            session.startTime.day);
      }
      final interviewLocation = session.isd?.interviewLocation ?? '';
      if (_locationController.text.trim().isEmpty &&
          interviewLocation.trim().isNotEmpty) {
        _locationController.text = interviewLocation.trim();
      }
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isStart ? _start : _end) ??
          (isStart
              ? const TimeOfDay(hour: 9, minute: 0)
              : const TimeOfDay(hour: 12, minute: 0)),
    );
    if (picked == null) return;
    setState(() => isStart ? _start = picked : _end = picked);
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? _date ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _deadline != null
          ? TimeOfDay.fromDateTime(_deadline!)
          : const TimeOfDay(hour: 17, minute: 0),
    );
    if (time == null) return;
    setState(() => _deadline =
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  String? _validationError() {
    if (_company == null) return 'Select a company';
    final start = _combine(_start);
    final end = _combine(_end);
    if (_date == null || start == null || end == null) {
      return 'Set the date, start time and end time';
    }
    if (!end.isAfter(start)) return 'End time must be after start time';
    if (generateSlotStarts(start, end, _slotMinutes).isEmpty) {
      return 'The block is shorter than one $_slotMinutes-minute interview';
    }
    if (_locationController.text.trim().isEmpty) return 'Enter a location';
    if (_deadline != null && !_deadline!.isBefore(end)) {
      return 'Sign-up deadline must be before the interviews end';
    }
    if (_timesLocked && _interviewers < _originalInterviewers) {
      return "Can't reduce interviewers per slot after students have signed up";
    }
    return null;
  }

  Future<void> _save() async {
    final error = _validationError();
    if (error != null) {
      _snack(error);
      return;
    }
    final company = _company!;
    final name = company.name.toString();
    final start = _combine(_start)!;
    final end = _combine(_end)!;
    final data = <String, dynamic>{
      'eventType': kInterviewBlockEventType,
      'Status': 'approved',
      'companyId': company.id,
      'company': name,
      'logo': company.logo ?? '',
      'eventName': '$name Interviews',
      'title': '$name Interviews',
      'startTime': Timestamp.fromDate(start),
      'endTime': Timestamp.fromDate(end),
      'mainLocation': _locationController.text.trim(),
      'slotMinutes': _slotMinutes,
      'interviewersPerSlot': _interviewers,
      'signupsOpen': _signupsOpen,
      'signupDeadline': _deadline == null ? null : Timestamp.fromDate(_deadline!),
      'linkedInfoSessionId': _linkedInfoSessionId,
      // Needed so EventProvider's incremental sync (updatedAt > lastSync) picks it up
      'updatedAt': FieldValue.serverTimestamp(),
    };

    setState(() => _saving = true);
    final eventProvider = context.read<EventProvider>();
    final navigator = Navigator.of(context);
    try {
      String id;
      if (_isEditing) {
        id = widget.existing!.id;
        await _events.doc(id).update(data);
      } else {
        data['createdBy'] = FirebaseAuth.instance.currentUser?.uid;
        data['createdAt'] = FieldValue.serverTimestamp();
        id = (await _events.add(data)).id;
      }
      await eventProvider.addEventById(id);
      if (!mounted) return;
      _snack(_isEditing ? 'Interview block updated' : 'Interview block created');
      navigator.pop();
    } catch (e) {
      ErrorLogger.logError('InterviewBlockEditor', 'Save failed', error: e);
      if (mounted) _snack('Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Text(text,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      );

  Widget _pickerField(String text, bool isSet, VoidCallback? onTap) => InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            color: onTap == null ? Colors.grey.shade200 : Colors.white,
          ),
          child: Text(text,
              style: TextStyle(color: isSet ? Colors.black : Colors.grey)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final start = _combine(_start);
    final end = _combine(_end);
    final slotCount = (start != null && end != null)
        ? generateSlotStarts(start, end, _slotMinutes).length
        : 0;
    final sessions = _infoSessionsForCompany(_company);
    final linkedStillListed =
        sessions.any((s) => s.id == _linkedInfoSessionId);

    return Scaffold(
      backgroundColor: AppColors.calPolyGreen,
      appBar: _greenAppBar(
          _isEditing ? 'Edit Interview Block' : 'New Interview Block'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_timesLocked)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      color: AppColors.welcomeLightYellow,
                      child: Text(
                          '$_existingSignups student(s) have signed up, so the date, times and interview length are locked. '
                          'Delete and recreate the block to change them.'),
                    ),
                  _label('Company *'),
                  _pickerField(
                      _company?.name?.toString() ?? 'Select a company',
                      _company != null,
                      _pickCompany),
                  if (sessions.isNotEmpty) ...[
                    _label('Linked info session (optional)'),
                    DropdownButtonFormField<String?>(
                      value: linkedStillListed ? _linkedInfoSessionId : null,
                      isExpanded: true,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.zero)),
                      items: [
                        const DropdownMenuItem<String?>(
                            value: null, child: Text('None')),
                        ...sessions.map((s) => DropdownMenuItem<String?>(
                              value: s.id,
                              child: Text(
                                  '${DateFormat('MMM d, yyyy h:mm a').format(s.startTime)} · ${s.eventLocation}',
                                  overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: (id) => _linkSession(id == null
                          ? null
                          : sessions.firstWhere((s) => s.id == id)),
                    ),
                  ],
                  _label('Date *'),
                  _pickerField(
                      _date == null
                          ? 'Select date'
                          : DateFormat('EEEE, MMM d, yyyy').format(_date!),
                      _date != null,
                      _timesLocked ? null : _pickDate),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Start *'),
                            _pickerField(
                                _start?.format(context) ?? 'Start time',
                                _start != null,
                                _timesLocked ? null : () => _pickTime(true)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('End *'),
                            _pickerField(
                                _end?.format(context) ?? 'End time',
                                _end != null,
                                _timesLocked ? null : () => _pickTime(false)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Interview length'),
                            DropdownButtonFormField<int>(
                              value: _slotMinutes,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.zero)),
                              items: {...kSlotLengthOptions, _slotMinutes}
                                  .map((m) => DropdownMenuItem(
                                      value: m, child: Text('$m min')))
                                  .toList(),
                              onChanged: _timesLocked
                                  ? null
                                  : (v) => setState(
                                      () => _slotMinutes = v ?? _slotMinutes),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Interviewers per slot'),
                            DropdownButtonFormField<int>(
                              value: _interviewers,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.zero)),
                              items: List.generate(8, (i) => i + 1)
                                  .map((n) => DropdownMenuItem(
                                      value: n, child: Text('$n')))
                                  .toList(),
                              onChanged: (v) => setState(
                                  () => _interviewers = v ?? _interviewers),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (slotCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                          '$slotCount time slots × $_interviewers = ${slotCount * _interviewers} interview openings',
                          style: const TextStyle(
                              color: AppColors.darkGoldText,
                              fontWeight: FontWeight.w600)),
                    ),
                  _label('Location *'),
                  TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      hintText: 'e.g., Bldg. 186-A213',
                      border:
                          OutlineInputBorder(borderRadius: BorderRadius.zero),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Sign-ups open'),
                    value: _signupsOpen,
                    activeColor: AppColors.calPolyGreen,
                    onChanged: (v) => setState(() => _signupsOpen = v),
                  ),
                  _label('Sign-up deadline (optional)'),
                  Row(
                    children: [
                      Expanded(
                        child: _pickerField(
                            _deadline == null
                                ? 'No deadline'
                                : DateFormat('MMM d, yyyy h:mm a')
                                    .format(_deadline!),
                            _deadline != null,
                            _pickDeadline),
                      ),
                      if (_deadline != null)
                        IconButton(
                          tooltip: 'Clear deadline',
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _deadline = null),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.yellowButton,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 48),
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEditing ? 'SAVE CHANGES' : 'CREATE INTERVIEW BLOCK',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sign-ups for one block, for admins (contains phone/email).
class InterviewRosterScreen extends StatefulWidget {
  final CalEvent block;
  const InterviewRosterScreen({super.key, required this.block});

  @override
  State<InterviewRosterScreen> createState() => _InterviewRosterScreenState();
}

class _InterviewRosterScreenState extends State<InterviewRosterScreen> {
  String _slotLabel(DateTime t) => DateFormat('EEE MMM d, h:mm a').format(t);

  Future<void> _copyCsv(List<InterviewSignup> signups) async {
    final csv = interviewSignupsToCsv(signups, _slotLabel);
    await Clipboard.setData(ClipboardData(text: csv));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Copied ${signups.length} sign-ups as CSV')));
  }

  Future<void> _launch(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _cancelFor(InterviewSignup s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text('Cancel this interview?'),
        content: Text(
            '${s.fullName} · ${_slotLabel(s.slotStart)}\n\nThe student will be notified.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Cancel interview',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await FirebaseFunctions.instance
          .httpsCallable('cancelInterviewSignup')
          .call(<String, dynamic>{'blockId': widget.block.id, 'uid': s.uid});
      messenger.showSnackBar(const SnackBar(content: Text('Interview cancelled')));
    } on FirebaseFunctionsException catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text(e.message ?? 'Could not cancel')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.calPolyGreen,
      appBar: _greenAppBar('Sign-ups'),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _events
            .doc(widget.block.id)
            .collection('interviewSignups')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
                child: Text('Error loading sign-ups',
                    style: TextStyle(color: Colors.white)));
          }
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          }
          final signups = snapshot.data!.docs
              .map(InterviewSignup.fromSnapshot)
              .toList()
            ..sort((a, b) => a.slotStart.compareTo(b.slotStart));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(widget.block.eventName,
                  style: const TextStyle(
                      color: AppColors.lightGold, fontSize: 22)),
              Text(_blockWhen(widget.block),
                  style: const TextStyle(color: Colors.white)),
              if (widget.block.eventLocation.isNotEmpty)
                Text(widget.block.eventLocation,
                    style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 12),
              if (signups.isEmpty)
                const Text('No sign-ups yet.',
                    style: TextStyle(color: Colors.white, fontSize: 16))
              else
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => _copyCsv(signups),
                    icon: const Icon(Icons.copy_all, size: 18),
                    label: Text('Copy ${signups.length} sign-ups as CSV'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              ...signups.map((s) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(DateFormat('h:mm a').format(s.slotStart),
                                  style: const TextStyle(
                                      color: AppColors.darkGoldText,
                                      fontWeight: FontWeight.bold)),
                              Text(s.fullName,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                              Text(s.minor.isEmpty
                                  ? s.major
                                  : '${s.major} · Minor: ${s.minor}'),
                              Text('Graduating ${s.graduation}'),
                              InkWell(
                                onTap: () => _launch(Uri(
                                    scheme: 'tel',
                                    path: s.localPhone
                                        .replaceAll(RegExp(r'\D'), ''))),
                                child: Text(s.localPhone,
                                    style: const TextStyle(
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline)),
                              ),
                              InkWell(
                                onTap: () => _launch(
                                    Uri(scheme: 'mailto', path: s.email)),
                                child: Text(s.email,
                                    style: const TextStyle(
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Cancel interview',
                          icon: const Icon(Icons.person_remove_outlined,
                              color: Colors.red),
                          onPressed: () => _cancelFor(s),
                        ),
                      ],
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}
