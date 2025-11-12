import 'package:flutter/material.dart';
import 'package:ccce_application/common/collections/calevent.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  
  /// Link company logos to info sessions
  /// Supports two approaches:
  /// 1. NEW: companyId field (proper relational reference)
  /// 2. LEGACY: company name matching (for backward compatibility)
  void linkCompanyLogos(List<dynamic> companies) {
    // Build lookup maps by ID and by name
    final Map<String, String?> logosByName = {};
    final Map<String, String?> logosById = {};
    
    for (var company in companies) {
      // By ID (new approach)
      if (company.id != null && company.id.isNotEmpty) {
        logosById[company.id] = company.logo;
      }
      // By name (legacy approach)
      if (company.name != null && company.name.isNotEmpty) {
        final key = company.name.toLowerCase().trim();
        logosByName[key] = company.logo;
      }
    }
    
    int linkedCount = 0;
    for (var event in _allEvents) {
      if (event.eventType == 'infoSession' && 
          (event.logo == null || event.logo!.isEmpty)) {
        
        String? logo;
        
        // NEW APPROACH: Try companyId first (preferred)
        if (event.companyId != null && event.companyId!.isNotEmpty) {
          logo = logosById[event.companyId];
          if (logo != null && logo.isNotEmpty) {
            event.logo = logo;
            linkedCount++;
            continue;
          }
        }
        
        // LEGACY APPROACH: Fall back to name matching
        if (event.eventName.isNotEmpty) {
          final key = event.eventName.toLowerCase().trim();
          logo = logosByName[key];
          if (logo != null && logo.isNotEmpty) {
            event.logo = logo;
            linkedCount++;
          }
        }
      }
    }
    
    if (linkedCount > 0) {
      print('✅ Linked $linkedCount company logos to info sessions');
      _needsLogoLinking = false;
      notifyListeners();
    }
  }
  
  Future<void> fetchAllEvents() async {
    try {
      if (!_isLoaded) {
        try {
          final cacheSnapshot = await FirebaseFirestore.instance
              .collection('events')
              .get(const GetOptions(source: Source.cache));
          
          if (cacheSnapshot.docs.isNotEmpty) {
            print("📦 Loaded ${cacheSnapshot.docs.length} events from cache (instant)");
            _allEvents.clear();
            for (final doc in cacheSnapshot.docs) {
              try {
                final event = CalEvent.fromSnapshot(doc);
                _allEvents.add(event);
              } catch (e) {
                print('⚠️ Failed to parse cached event: $e');
              }
            }
            _isLoaded = true;
            notifyListeners();
          }
        } catch (cacheError) {
          print('💾 Cache miss, fetching from server...');
        }
      }
      
      Query query = FirebaseFirestore.instance.collection('events');
      
      if (_lastSyncTime != null) {
        query = query.where('updatedAt', isGreaterThan: Timestamp.fromDate(_lastSyncTime!));
        print("🔄 Incremental sync: fetching events updated after ${_lastSyncTime!.toLocal()}");
      } else {
        print("🌐 Full sync: fetching all events");
      }
      
      final snapshot = await query.get(const GetOptions(source: Source.server));
      
      if (_lastSyncTime != null) {
        int added = 0, updated = 0;
        
        for (final doc in snapshot.docs) {
          try {
            final newEvent = CalEvent.fromSnapshot(doc);
            final existingIndex = _allEvents.indexWhere((e) => e.id == newEvent.id);
            
            if (existingIndex >= 0) {
              _allEvents[existingIndex] = newEvent;
              updated++;
            } else {
              _allEvents.add(newEvent);
              added++;
            }
          } catch (e) {
            print('⚠️ Failed to parse event doc ${doc.id}: $e');
          }
        }
        
        print("✅ Incremental sync complete: $added new, $updated updated (${snapshot.docs.length} total changed)");
        
        // If new events were added, mark that we need to re-link logos
        if (added > 0 || updated > 0) {
          _needsLogoLinking = true;
        }
      } else {
        _allEvents.clear();
        for (final doc in snapshot.docs) {
          try {
            final event = CalEvent.fromSnapshot(doc);
            _allEvents.add(event);
          } catch (e) {
            print('⚠️ Failed to parse event doc ${doc.id}: $e');
          }
        }
        print("✅ Full sync complete: ${snapshot.docs.length} events loaded");
        _needsLogoLinking = true;
      }
      
      _lastSyncTime = DateTime.now();
      _isLoaded = true;
      notifyListeners();
      
    } catch (e) {
      print('❌ Error fetching events: $e');
    }
  }

  List<CalEvent> getEventsByType(String type) =>
      _allEvents.where((event) => event.eventType == type).toList();
}
