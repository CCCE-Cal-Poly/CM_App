import 'package:flutter/material.dart';
import 'package:ccce_application/common/collections/calevent.dart';
import 'package:ccce_application/common/constants/app_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ccce_application/services/error_logger.dart';
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
  }

  List<CalEvent> getEventsByType(String type) =>
      _allEvents.where((event) => event.eventType == type).toList();

  void linkCompanyLogos(List<dynamic> companies) {
    final Map<String, String?> logosByName = {};
    final Map<String, String?> logosById = {};

    for (var company in companies) {
      if (company.id != null && company.id.isNotEmpty)
        logosById[company.id] = company.logo;
      if (company.name != null && company.name.isNotEmpty)
        logosByName[company.name.toLowerCase().trim()] = company.logo;
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
      // Retry logic for auth token propagation (handles fresh sign-in edge case)
      int retries = 0;
      const maxRetries = 3;
      Exception? lastError;

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

            for (final doc in cacheSnapshot.docs) {
              final data = doc.data() as Map<String, dynamic>;
              try {
                final event = CalEvent.fromSnapshot(doc);
                _allEvents.add(event);
              } catch (e) {
                ErrorLogger.logWarning(
                    'EventProvider', 'Failed to parse cached event: $e');
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

      for (final doc in eventDocs) {
        try {
          updatedEvents.add(CalEvent.fromSnapshot(doc));
        } catch (e) {
          ErrorLogger.logError(
              'EventProvider', 'Failed to parse non-recurring event ${doc.id}',
              error: e);
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
        final newEvent = CalEvent.fromSnapshot(doc);

        // Check if event already exists and update, otherwise add
        final existingIndex = _allEvents.indexWhere((e) => e.id == newEvent.id);
        if (existingIndex >= 0) {
          _allEvents[existingIndex] = newEvent;
          ErrorLogger.logInfo(
              'EventProvider', 'Updated existing event: ${newEvent.eventName}');
        } else {
          _allEvents.add(newEvent);
          ErrorLogger.logInfo('EventProvider',
              'Added new event to calendar: ${newEvent.eventName}');
        }

        _needsLogoLinking = true;
        notifyListeners();
      }
    } catch (e) {
      ErrorLogger.logError('EventProvider', 'Error fetching single event',
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
            (snapshot) {
              try {
                final updatedEvents = <CalEvent>[];

                for (final doc in snapshot.docs) {
                  try {
                    updatedEvents.add(CalEvent.fromSnapshot(doc));
                  } catch (e) {
                    ErrorLogger.logError('EventProvider',
                        'Failed to parse real-time event ${doc.id}',
                        error: e);
                  }
                }

                // Merge new events with existing ones, updating if already present
                for (final newEvent in updatedEvents) {
                  final index =
                      _allEvents.indexWhere((e) => e.id == newEvent.id);
                  if (index >= 0) {
                    _allEvents[index] = newEvent;
                  } else {
                    _allEvents.add(newEvent);
                  }
                }

                // Remove deleted events
                _allEvents.removeWhere((event) =>
                    !updatedEvents.any((updated) => updated.id == event.id));

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
