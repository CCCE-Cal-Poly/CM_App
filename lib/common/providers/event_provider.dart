import 'package:flutter/material.dart';
import 'package:ccce_application/common/collections/calevent.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ccce_application/services/error_logger.dart';
import 'package:rrule/rrule.dart';
import 'dart:async';

class EventProvider extends ChangeNotifier {
  final List<CalEvent> _allEvents = [];
  bool _isLoaded = false;
  DateTime? _lastSyncTime;
  bool _needsLogoLinking = false;
  StreamSubscription<QuerySnapshot>? _eventListener;

  List<CalEvent> get allEvents => _allEvents;
  bool get isLoaded => _isLoaded;
  bool get needsLogoLinking => _needsLogoLinking;

  EventProvider() {
    _initializeAsync();
  }

  Future<void> _initializeAsync() async {
    await Future.delayed(const Duration(milliseconds: 50));
    fetchAllEvents();
    startRealtimeListening();
  }

  List<CalEvent> getEventsByType(String type) =>
      _allEvents.where((event) => event.eventType == type).toList();

  List<CalEvent> getEventsByTypes(List<String> types) =>
      _allEvents.where((event) => types.contains(event.eventType)).toList();

  void linkCompanyLogos(List<dynamic> companies) {
    final Map<String, String?> logosByName = {};
    final Map<String, String?> logosById = {};

    for (var company in companies) {
      if (company.id != null && company.id.isNotEmpty) logosById[company.id] = company.logo;
      if (company.name != null && company.name.isNotEmpty) logosByName[company.name.toLowerCase().trim()] = company.logo;
    }

    int linkedCount = 0;
    for (var event in _allEvents) {
      if (event.eventType == 'infoSession' &&
          (event.logo == null || event.logo!.isEmpty)) {
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
      ErrorLogger.logInfo('EventProvider',
          'Linked $linkedCount company logos to info sessions');
      _needsLogoLinking = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllEvents() async {
    try {
      final db = FirebaseFirestore.instance;
      Query query = db.collection('events');

      // Attempt to load from cache first for instant availability **********/

      if (!_isLoaded) {
        try {
          final cacheSnapshot = await FirebaseFirestore.instance
              .collection('events')
              .get(const GetOptions(source: Source.cache));

          if (cacheSnapshot.docs.isNotEmpty) {
            ErrorLogger.logInfo('EventProvider',
                'Loaded ${cacheSnapshot.docs.length} events from cache (instant)');
            _allEvents.clear();

            final now = DateTime.now();
            final windowStart = now.subtract(const Duration(days: 1));
            final windowEnd = now.add(const Duration(days: 90));

            for (final doc in cacheSnapshot.docs) {
              final data = doc.data();
              if (_hasRecurrence(data)) {
                _allEvents.addAll(_generateInstancesFromSeries(
                    doc, windowStart, windowEnd));
                ErrorLogger.logInfo('EventProvider',
                    'Expanded cached series ${doc.id} into instances');
              } else {
                try {
                  final event = CalEvent.fromSnapshot(doc);
                  _allEvents.add(event);
                } catch (e) {
                  ErrorLogger.logWarning(
                      'EventProvider', 'Failed to parse cached event: $e');
                }
              }
            }

            _isLoaded = true;
            notifyListeners();
          }
        } catch (cacheError) {
          ErrorLogger.logInfo(
              'EventProvider', 'Cache miss, fetching from server...');
        }
      }

      if (_lastSyncTime != null) {
        query = query.where('updatedAt',
            isGreaterThan: Timestamp.fromDate(_lastSyncTime!));
        ErrorLogger.logInfo('EventProvider',
            'Incremental sync: fetching events updated after ${_lastSyncTime!.toLocal()}');
      } else {
        ErrorLogger.logInfo('EventProvider', 'Full sync: fetching all events');
      }

      final snapshot = await query.get(const GetOptions(source: Source.server));

      List<CalEvent> updatedEvents = [];

      // Filter out deleted events only
      final eventDocs = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final status = (data['Status'] ?? data['status'] ?? 'approved')
            .toString()
            .toLowerCase();
        return status != 'deleted';
      }).toList();


      final nonRecurringDocs = eventDocs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return !_hasRecurrence(data);
      }).toList();
      ErrorLogger.logInfo('EventProvider',
          'Found ${nonRecurringDocs.length} non-recurring events to process for sync');

      final seriesDocs = eventDocs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _hasRecurrence(data);
      }).toList();
      ErrorLogger.logInfo('EventProvider',
          'Found ${seriesDocs.length} recurring series to expand for sync');

      for (final doc in nonRecurringDocs) {
        try {
          updatedEvents.add(CalEvent.fromSnapshot(doc));
        } catch (e) {
          ErrorLogger.logError(
              'EventProvider', 'Failed to parse non-recurring event ${doc.id}',
              error: e);
        }
      }
      /*********************************************************************************************************** */

      // Expand recurring series into instances
      final now = DateTime.now();
      final windowStart = now.subtract(const Duration(days: 1));
      final windowEnd = now.add(const Duration(days: 90)); // adjust as needed

      for (final sdoc in seriesDocs) {
        try {

          final instances = _generateInstancesFromSeries(
              sdoc, windowStart, windowEnd);

          updatedEvents.addAll(instances);
          ErrorLogger.logInfo('EventProvider',
              'Expanded series ${sdoc.id} into ${instances.length} instances');
        } catch (e) {
          ErrorLogger.logError(
              'EventProvider', 'Failed to expand series ${sdoc.id}',
              error: e);
        }
      }

      /*********************************************************************************************************** */

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
      ErrorLogger.logInfo('EventProvider',
          '${_lastSyncTime!.toLocal()}: Fetched and processed ${updatedEvents.length} events from server, now synced');
      _isLoaded = true;
      _needsLogoLinking = true;

      notifyListeners();
      ErrorLogger.logInfo('EventProvider',
          'Events fetched and expanded: ${_allEvents.length} total');
    } catch (e) {
      ErrorLogger.logError('EventProvider', 'Error fetching events', error: e);
    }
  }

  /// Fetch a single event by ID and add it to the provider (cost-efficient)
  Future<void> addEventById(String eventId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final isRecurring = _hasRecurrence(data);
        final eventWindowStart =
            DateTime.now().subtract(const Duration(days: 1));
        final eventWindowEnd = DateTime.now().add(const Duration(days: 90));
        List<CalEvent> newEvents;
        if (isRecurring) {
          newEvents = _generateInstancesFromSeries(
              doc, eventWindowStart, eventWindowEnd);
        } else {
          newEvents = [CalEvent.fromSnapshot(doc)];
        }

        _allEvents.removeWhere(
            (event) => event.id == eventId || event.seriesId == eventId);
        for (final newEvent in newEvents) {
          _allEvents.add(newEvent);
        }

        ErrorLogger.logInfo('EventProvider',
            'Added or updated ${newEvents.length} event occurrence(s) for $eventId');
        _needsLogoLinking = true;
        _allEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
        notifyListeners();
      }
    } catch (e) {
      ErrorLogger.logError('EventProvider', 'Error fetching single event',
          error: e);
    }
  }

  /// Start real-time listening to events collection for instant updates
  /// Call this after initial fetchAllEvents() to enable live event updates
  void startRealtimeListening() {
    if (_eventListener != null) {
      ErrorLogger.logWarning(
          'EventProvider', 'Real-time listener already active');
      return;
    }

    try {
      _eventListener = FirebaseFirestore.instance
          .collection('events')
          .where('Status',
              whereIn: ['approved', 'Approved', 'pending', 'Pending'])
          .snapshots()
          .listen(
            (snapshot) async {
              try {
                final updatedEvents = <CalEvent>[];
                final now = DateTime.now();
                final windowStart = now.subtract(const Duration(days: 1));
                final windowEnd = now.add(const Duration(days: 90));

                for (final doc in snapshot.docs) {
                  try {
                    final data = doc.data();
                    if (!_hasRecurrence(data)) {
                      updatedEvents.add(CalEvent.fromSnapshot(doc));
                      continue;
                    }

                    updatedEvents.addAll(_generateInstancesFromSeries(
                        doc, windowStart, windowEnd));
                  } catch (e) {
                    ErrorLogger.logError('EventProvider',
                        'Failed to parse real-time event ${doc.id}',
                        error: e);
                  }
                }

                _allEvents
                  ..clear()
                  ..addAll(updatedEvents);

                _allEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
                _needsLogoLinking = true;
                notifyListeners();

                ErrorLogger.logInfo('EventProvider',
                    'Real-time update: synced ${updatedEvents.length} events');
              } catch (e) {
                ErrorLogger.logError(
                    'EventProvider', 'Error processing real-time event update',
                    error: e);
              }
            },
            onError: (e) {
              ErrorLogger.logError('EventProvider', 'Real-time listener error',
                  error: e);
              // Attempt to restart listener after short delay
              _eventListener = null;
              Future.delayed(
                  const Duration(seconds: 5), startRealtimeListening);
            },
          );

      ErrorLogger.logInfo(
          'EventProvider', 'Real-time event listener activated');
    } catch (e) {
      ErrorLogger.logError('EventProvider', 'Error starting real-time listener',
          error: e);
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

  bool _hasRecurrence(Map<String, dynamic> data) {
    final recurrence = data['recurrence'];
    final rule = recurrence is Map ? recurrence['rrule'] : null;
    if (rule is String && rule.trim().isNotEmpty) return true;
    if (recurrence is Map &&
        recurrence['rdate'] is Iterable &&
        (recurrence['rdate'] as Iterable).isNotEmpty) {
      return true;
    }

    return false;


  }

  /// Expand recurring series into instances
  List<CalEvent> _generateInstancesFromSeries(
    DocumentSnapshot seriesDoc,
    DateTime windowStart,
    DateTime windowEnd,
  ) {
    final data = seriesDoc.data() as Map<String, dynamic>;
    final DateTime? seriesStart = _toDate(data['startTime']);
    if (seriesStart == null) return [];

    final DateTime seriesEnd = _toDate(data['endTime']) ?? seriesStart.add(const Duration(hours: 1));
    final duration = seriesEnd.difference(seriesStart);
    final rawRule = data['recurrence'];
    final ruleData = rawRule is Map ? Map<String, dynamic>.from(rawRule) : null;
    var recurrenceString = ruleData?['rrule'] as String?;
    final recurrenceDates = ruleData?['rdate'];
    if ((recurrenceString == null || recurrenceString.trim().isEmpty) &&
        (recurrenceDates is! Iterable || recurrenceDates.isEmpty)) {
      return [];
    }

    final dates = <DateTime>{};
    if (recurrenceString != null && recurrenceString.trim().isNotEmpty) {
      final recurrenceRule = RecurrenceRule.fromString(recurrenceString);
      final after =
          windowStart.isAfter(seriesStart) ? windowStart.toUtc() : null;
      dates.addAll(recurrenceRule.getInstances(
        start: seriesStart.toUtc(),
        after: after,
        includeAfter: true,
        before: windowEnd.toUtc(),
        includeBefore: true,
      ));
    }

    // add the additional dates that are part of the series but don't follow the pattern
    if (recurrenceDates is Iterable) {
      for (final recurrenceDate in recurrenceDates) {
        final date = _toDate(recurrenceDate);
        if (date != null &&
            !date.isBefore(seriesStart) &&
            !date.isBefore(windowStart) &&
            !date.isAfter(windowEnd)) {
          dates.add(date.toUtc());
        }
      }
    }

    final excludedDates = <int>{};
    final exceptionDates = ruleData?['exdate'];
    if (exceptionDates is Iterable) {
      for (final exceptionDate in exceptionDates) {
        final date = _toDate(exceptionDate);
        if (date != null) excludedDates.add(date.millisecondsSinceEpoch);
      }
    }
    dates.removeWhere((date) =>
        date.isBefore(seriesStart) ||
        date.isBefore(windowStart) ||
        date.isAfter(windowEnd) ||
        excludedDates.contains(date.millisecondsSinceEpoch));

    final List<CalEvent> instances = [];
    for (final dt in dates) {
      final ms = dt.millisecondsSinceEpoch;

      DateTime instanceStart = dt.toLocal();
      DateTime instanceEnd = instanceStart.add(duration);
      String eventName = '';
      String eventLocation = data['eventLocation'] ?? '';
      

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
        updatedAt: data['updatedAt'] is Timestamp
            ? (data['updatedAt'] as Timestamp).toDate()
            : null,
        isd: null,
        recurrence: ruleData,
        seriesId: seriesDoc.id,
        isInstance: true,
      ));
    }

    ErrorLogger.logInfo('EventProvider',
        'Generated ${instances.length} instances for series ${seriesDoc.id}');

    return instances;
  }

  /// Stop real-time listening and clean up resources
  void stopRealtimeListening() {
    _eventListener?.cancel();
    _eventListener = null;
    ErrorLogger.logInfo(
        'EventProvider', 'Real-time event listener deactivated');
  }

  @override
  void dispose() {
    stopRealtimeListening();
    super.dispose();
  }
}
