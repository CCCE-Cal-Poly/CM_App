import 'package:flutter/material.dart';
import 'package:ccce_application/common/collections/calevent.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventProvider extends ChangeNotifier {
  final List<CalEvent> _allEvents = [];
  bool _isLoaded = false;

  List<CalEvent> get allEvents => _allEvents;
  bool get isLoaded => _isLoaded;

  EventProvider() {
    fetchAllEvents();
  }
  Future<void> fetchAllEvents() async {
    if (_isLoaded) return;

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('events').get();
      print("Fetched");
      _allEvents.clear();

      for (final doc in snapshot.docs) {
        try {
          final event = CalEvent.fromSnapshot(doc);
          print("✅ Loaded event");
          _allEvents.add(event);
        } catch (e) {
          print(e);
          print("⚠️ Failed to parse event doc");
        }
      }

      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      print('Error fetching events: $e');
    }
  }

  List<CalEvent> getEventsByType(String type) =>
      _allEvents.where((event) => event.eventType == type).toList();
}
