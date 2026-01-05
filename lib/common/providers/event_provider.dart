import 'package:flutter/material.dart';
import 'package:ccce_application/common/collections/calevent.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ccce_application/services/error_logger.dart';

class EventProvider extends ChangeNotifier {
  final List<CalEvent> _allEvents = [];
  bool _isLoaded = false;
  DateTime? _lastSyncTime;
  bool _needsLogoLinking = false;

  List<CalEvent> get allEvents => _allEvents;
  bool get isLoaded => _isLoaded;
  bool get needsLogoLinking => _needsLogoLinking;

  EventProvider() {
    _initializeAsync();
  }

  Future<void> _initializeAsync() async {
    await Future.delayed(const Duration(milliseconds: 50));
    fetchAllEvents();
  }

  List<CalEvent> getEventsByType(String type) =>
      _allEvents.where((event) => event.eventType == type).toList();


  void linkCompanyLogos(List<dynamic> companies) {
    final Map<String, String?> logosByName = {};
    final Map<String, String?> logosById = {};

    for (var company in companies) {
      if (company.id != null && company.id.isNotEmpty) logosById[company.id] = company.logo;
      if (company.name != null && company.name.isNotEmpty) logosByName[company.name.toLowerCase().trim()] = company.logo;
    }

    int linkedCount = 0;
    for (var event in _allEvents) {
      if (event.eventType == 'infoSession' && (event.logo == null || event.logo!.isEmpty)) {
        String? logo;
        if (event.companyId != null && event.companyId!.isNotEmpty) {
          logo = logosById[event.companyId];
          if (logo != null && logo.isNotEmpty) {
            event.logo = logo;
            linkedCount++;
            continue;
          }
        }

        final key = event.eventName.toLowerCase().trim();
        logo = logosByName[key];
        if (logo != null && logo.isNotEmpty) {
          event.logo = logo;
          linkedCount++;
        }
      }
    }

    if (linkedCount > 0) {
      _needsLogoLinking = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllEvents() async {
    try {
      final db = FirebaseFirestore.instance;
      Query query = db.collection('events');

      /********** Attempt to load from cache first for instant availability **********/

      if (!_isLoaded) {
        try {
          final cacheSnapshot = await FirebaseFirestore.instance
              .collection('events')
              .get(const GetOptions(source: Source.cache));
          
          if (cacheSnapshot.docs.isNotEmpty) {
            ErrorLogger.logInfo('EventProvider', 'Loaded ${cacheSnapshot.docs.length} events from cache (instant)');
            _allEvents.clear();

            final now = DateTime.now();
            final windowStart = now.subtract(const Duration(days: 1));
            final windowEnd = now.add(const Duration(days: 90));

            final List<CalEvent> expanded = [];

            for (final doc in cacheSnapshot.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final recurrenceType = data['recurrenceType'];

              if (recurrenceType != null && recurrenceType != 'Never') {
                expanded.addAll(
                  _generateInstancesFromSeries(doc, windowStart, windowEnd, {})
                );
              } else {
                try {
                  final event = CalEvent.fromSnapshot(doc);
                  _allEvents.add(event);
                } catch (e) {
                  ErrorLogger.logWarning('EventProvider', 'Failed to parse cached event: $e');
                }
              }
            }
            _allEvents.addAll(expanded);
            
            _isLoaded = true;
            notifyListeners();
          }
        } catch (cacheError) {
          ErrorLogger.logInfo('EventProvider', 'Cache miss, fetching from server...');
        }
      }

      /***************************************************************************************************/

      if (_lastSyncTime != null) {
        query = query.where('updatedAt', isGreaterThan: Timestamp.fromDate(_lastSyncTime!));
      }

      final snapshot = await query.get(const GetOptions(source: Source.server));

      List<CalEvent> updatedEvents = [];

      // Partition into series vs non-recurring events
      final nonRecurringDocs = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['recurrenceType'] == null || data['recurrenceType'] == 'Never';
      }).toList();

      final seriesDocs = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final recurrenceType = data['recurrenceType'] as String?;
        return recurrenceType != null && recurrenceType != 'Never';
      }).toList();

      // Non-recurring events
      for (final doc in nonRecurringDocs) {
        try {
          updatedEvents.add(CalEvent.fromSnapshot(doc));
        } catch (e) {
          print('⚠️ Failed to parse non-recurring event ${doc.id}: $e');
        }
      }

      // Expand recurring series into instances
      final now = DateTime.now();
      final windowStart = now.subtract(const Duration(days: 1));
      final windowEnd = now.add(const Duration(days: 90)); // adjust as needed

      for (final sdoc in seriesDocs) {
        try {
          // Fetch exceptions
          final excSnap = await db
              .collection('events')
              .doc(sdoc.id)
              .collection('exceptions')
              .get();

          final Map<int, Map<String, dynamic>> exceptionsByMs = {};
          for (final exc in excSnap.docs) {
            final ed = exc.data() as Map<String, dynamic>;
            if (ed['date'] is Timestamp) {
              exceptionsByMs[(ed['date'] as Timestamp).toDate().millisecondsSinceEpoch] = ed;
            }
          }

          final instances = _generateInstancesFromSeries(sdoc, windowStart, windowEnd, exceptionsByMs);
          updatedEvents.addAll(instances);
        } catch (e) {
          print('⚠️ Failed to expand series ${sdoc.id}: $e');
        }
      }

      // Replace old events if incremental sync, else clear
      if (_lastSyncTime != null) {
        for (final newEvent in updatedEvents) {
          final index = _allEvents.indexWhere((e) => e.id == newEvent.id);
          if (index >= 0) {
            _allEvents[index] = newEvent;
          } else {
            _allEvents.add(newEvent);
          }
        }
      } else {
        _allEvents
          ..clear()
          ..addAll(updatedEvents);
      }

      _allEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
      _lastSyncTime = DateTime.now();
      _isLoaded = true;
      _needsLogoLinking = true;

      notifyListeners();
      print("✅ Events fetched and expanded: ${_allEvents.length} total");
    } catch (e) {
      print('❌ Error fetching events: $e');
    }
  }

  /// Convert Firestore types to DateTime
  DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  /// Expand recurring series into instances
  List<CalEvent> _generateInstancesFromSeries(
    DocumentSnapshot seriesDoc,
    DateTime windowStart,
    DateTime windowEnd,
    Map<int, Map<String, dynamic>> exceptionsByMs,
  ) {
    final data = seriesDoc.data() as Map<String, dynamic>;
    final DateTime? seriesStart = _toDate(data['startTime']) ?? _toDate(data['startDate']);
    if (seriesStart == null) return [];

    final DateTime seriesEnd = _toDate(data['recurrenceEndDate']) ?? seriesStart.add(const Duration(hours: 1));
    final duration = seriesEnd.difference(seriesStart);
    final recurrenceType = (data['recurrenceType'] ?? 'Never').toString();
    if (recurrenceType == 'Never') return [];

    final repeatUntil = _toDate(data['recurrenceEndDate']) ?? windowEnd;
    final List<DateTime> dates = [];

    // Interval (days) recurrence
    if (recurrenceType == 'Interval (days)') {
      final intervalDays = (int.tryParse((data['recurrenceInterval'] ?? '1').toString()) ?? 1).clamp(1, 3650);
      for (DateTime dt = seriesStart; dt.isBefore(windowEnd) && dt.isBefore(repeatUntil); dt = dt.add(Duration(days: intervalDays))) {
        if (!dt.isBefore(windowStart)) dates.add(dt);
      }
    }

    // Weekly recurrence
    else if (recurrenceType == 'Weekly') {
      final daysRaw = data['recurrenceDays'];
      List<int>? days;
      if (daysRaw is List) {
        days = daysRaw.map((d) => int.tryParse(d.toString()) ?? -1).where((d) => d >= 0 && d <= 6).toList();
      }
      if (days != null && days.isNotEmpty) {
        for (DateTime dt = seriesStart; dt.isBefore(windowEnd) && dt.isBefore(repeatUntil); dt = dt.add(const Duration(days: 1))) {
          final w = dt.weekday % 7;
          if (days.contains(w) && !dt.isBefore(windowStart)) dates.add(dt);
        }
      }
    }

    // Monthly recurrence
    else if (recurrenceType == 'Monthly') {
      final intervalMonths = (int.tryParse((data['recurrenceInterval'] ?? '1').toString()) ?? 1).clamp(1, 120);
      final dayOfMonth = (int.tryParse((data['recurrenceDayOfMonth'] ?? seriesStart.day).toString()) ?? seriesStart.day);
      DateTime dt = DateTime(seriesStart.year, seriesStart.month, dayOfMonth, seriesStart.hour, seriesStart.minute, seriesStart.second);
      while (dt.isBefore(seriesStart)) {
        final nextMonth = dt.month + intervalMonths;
        dt = DateTime(dt.year + ((nextMonth - 1) ~/ 12), ((nextMonth - 1) % 12) + 1, dayOfMonth, seriesStart.hour, seriesStart.minute, seriesStart.second);
      }
      while (!dt.isAfter(windowEnd) && !dt.isAfter(repeatUntil)) {
        if (!dt.isBefore(windowStart) && dt.day == dayOfMonth) dates.add(dt);
        final nextMonth = dt.month + intervalMonths;
        dt = DateTime(dt.year + ((nextMonth - 1) ~/ 12), ((nextMonth - 1) % 12) + 1, dayOfMonth, seriesStart.hour, seriesStart.minute, seriesStart.second);
      }
    }

    // Build instances applying exceptions
    final List<CalEvent> instances = [];
    for (final dt in dates) {
      final ms = dt.millisecondsSinceEpoch;
      final exc = exceptionsByMs[ms];
      if (exc != null && exc['type'] == 'cancelled') continue;

      DateTime instanceStart = dt;
      DateTime instanceEnd = dt.add(duration);
      String eventName = '';
      String eventLocation = data['mainLocation'] ?? data['eventLocation'] ?? '';

      if (exc != null && exc['type'] == 'modified' && exc['changes'] is Map<String, dynamic>) {
        final changes = Map<String, dynamic>.from(exc['changes']);
        if (changes['startTime'] is Timestamp) instanceStart = (changes['startTime'] as Timestamp).toDate();
        if (changes['endTime'] is Timestamp) instanceEnd = (changes['endTime'] as Timestamp).toDate();
        if (changes['eventName'] != null) eventName = changes['eventName'].toString();
        if (changes['eventLocation'] != null) eventLocation = changes['eventLocation'].toString();
      }

      final clubName = data['clubName'] ?? data['company'] ?? '';
      final baseEventName = data['eventName'] ?? '';
      final displayName = (eventName.isNotEmpty)
          ? eventName
          : (clubName.isNotEmpty && baseEventName.isNotEmpty)
              ? "$clubName - $baseEventName"
              : (baseEventName.isNotEmpty ? baseEventName : clubName);

      instances.add(CalEvent(
        id: '${seriesDoc.id}-$ms',
        eventName: displayName,
        startTime: instanceStart,
        endTime: instanceEnd,
        eventLocation: eventLocation,
        eventType: data['eventType'] ?? 'club',
        logo: data['logo'],
        status: data['status'] ?? 'approved',
        companyId: data['companyId'],
        updatedAt: data['updatedAt'] is Timestamp ? (data['updatedAt'] as Timestamp).toDate() : null,
        isd: null,
        seriesId: seriesDoc.id,
        isInstance: true,
      ));
    }

    return instances;
  }
}
