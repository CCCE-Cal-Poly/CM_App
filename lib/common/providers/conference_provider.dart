import 'dart:async';

import 'package:ccce_application/common/collections/conference_session.dart';
import 'package:ccce_application/services/error_logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class ConferenceProvider extends ChangeNotifier {
  final String conferenceId;

  final List<ConferenceSession> _sessions = [];
  bool _isLoaded = false;
  String? _errorMessage;
  StreamSubscription<QuerySnapshot>? _sessionListener;

  ConferenceProvider({this.conferenceId = 'asc_2026'}) {
    _initializeAsync();
  }

  List<ConferenceSession> get sessions => List.unmodifiable(_sessions);
  bool get isLoaded => _isLoaded;
  String? get errorMessage => _errorMessage;

  int get missingPresentationCount =>
      _sessions.where((session) => session.isPresentationMissing).length;

  Future<void> _initializeAsync() async {
    await Future.delayed(const Duration(milliseconds: 50));
    await fetchSessions();
    startRealtimeListening();
  }

  CollectionReference<Map<String, dynamic>> get _sessionsRef {
    return FirebaseFirestore.instance
        .collection('conferences')
        .doc(conferenceId)
        .collection('sessions');
  }

  Future<void> fetchSessions({bool forceServer = false}) async {
    _errorMessage = null;

    try {
      if (!_isLoaded && !forceServer) {
        try {
          final cacheSnapshot = await _sessionsRef
              .orderBy('startTime')
              .get(const GetOptions(source: Source.cache));
          if (cacheSnapshot.docs.isNotEmpty) {
            _applySnapshot(cacheSnapshot);
            _isLoaded = true;
            notifyListeners();
          }
        } catch (_) {
          // Cache miss is expected for first load.
        }
      }

      final serverSnapshot = await _sessionsRef
          .orderBy('startTime')
          .get(const GetOptions(source: Source.server));
      _applySnapshot(serverSnapshot);
      _isLoaded = true;
      notifyListeners();
      ErrorLogger.logInfo('ConferenceProvider',
          'Loaded ${_sessions.length} conference sessions');
    } catch (e) {
      _errorMessage = 'Unable to load conference sessions right now.';
      _isLoaded = true;
      notifyListeners();
      ErrorLogger.logError('ConferenceProvider', 'Error fetching sessions',
          error: e);
    }
  }

  void _applySnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final loaded = <ConferenceSession>[];
    for (final doc in snapshot.docs) {
      try {
        loaded.add(ConferenceSession.fromSnapshot(doc));
      } catch (e) {
        ErrorLogger.logWarning(
            'ConferenceProvider', 'Skipping invalid session ${doc.id}: $e');
      }
    }

    loaded.sort((a, b) {
      final timeCompare = a.startTime.compareTo(b.startTime);
      if (timeCompare != 0) {
        return timeCompare;
      }
      return a.sessionNumber.compareTo(b.sessionNumber);
    });

    _sessions
      ..clear()
      ..addAll(loaded);
  }

  void startRealtimeListening() {
    if (_sessionListener != null) {
      return;
    }

    try {
      _sessionListener = _sessionsRef.orderBy('startTime').snapshots().listen(
        (snapshot) {
          _errorMessage = null;
          _applySnapshot(snapshot);
          _isLoaded = true;
          notifyListeners();
        },
        onError: (e) {
          _errorMessage = 'Live session updates paused. Pull to refresh.';
          notifyListeners();
          ErrorLogger.logError('ConferenceProvider', 'Realtime listener failed',
              error: e);
        },
      );
    } catch (e) {
      ErrorLogger.logError('ConferenceProvider', 'Failed to start listener',
          error: e);
    }
  }

  Future<String?> getPresentationLaunchUrl(ConferenceSession session) async {
    if (session.presentationUrl != null &&
        session.presentationUrl!.isNotEmpty) {
      return session.presentationUrl;
    }

    final path = session.presentationStoragePath;
    if (path == null || path.isEmpty) {
      return null;
    }

    return FirebaseStorage.instance.ref(path).getDownloadURL();
  }

  Future<String?> getPaperLaunchUrl(ConferenceSession session) async {
    if (session.paperUrl != null && session.paperUrl!.isNotEmpty) {
      return session.paperUrl;
    }

    final path = session.paperStoragePath;
    if (path == null || path.isEmpty) {
      return null;
    }

    return FirebaseStorage.instance.ref(path).getDownloadURL();
  }

  @override
  void dispose() {
    _sessionListener?.cancel();
    super.dispose();
  }
}
