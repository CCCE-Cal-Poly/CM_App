import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:ccce_application/common/collections/club.dart';

class ClubProvider with ChangeNotifier {
  List<Club> _clubs = [];
  bool _isLoaded = false;
  bool _isLoading = false;

  ClubProvider();

  List<Club> get clubs => _clubs;
  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;

  // Get list of club names for dropdowns
  List<String> get clubAcronyms {
    if (_clubs.isEmpty) {
      return [];
    }
    return _clubs.map((club) => club.acronym.toString()).toList();
  }

  Future<void> loadClubs() async {
    if (_isLoaded || _isLoading) {
      return; // Prevent duplicate loading
    }

    _isLoading = true;
    notifyListeners();

    try {
      // First, try to load from cache
      await _loadFromCache();

      // Check if we need to refresh from server
      final prefs = await SharedPreferences.getInstance();
      final lastFetch = prefs.getInt('clubs_last_fetch') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final cacheAge = now - lastFetch;

      // Refresh if cache is older than 1 hour (3600000 ms) or if we have no clubs
      if (cacheAge > 3600000 || _clubs.isEmpty) {
        await _fetchFromFirestore();
        await _saveToCache();
      }

      // Only mark as loaded if we actually have clubs
      if (_clubs.isNotEmpty) {
        _isLoaded = true;
      }
    } catch (e) {
      // Handle error silently or log if needed
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_clubs');

      if (cachedData != null) {
        final List<dynamic> clubList = jsonDecode(cachedData);
        _clubs = clubList
            .map((data) => Club(
                  data['name'] ?? '',
                  data['aboutMsg'] ?? '',
                  data['email'] ?? '',
                  data['acronym'] ?? '',
                  data['instagram'] ?? '',
                  data['logo'],
                ))
            .toList();
      }
    } catch (e) {
      // Handle error silently or log if needed
    }
  }

  Future<void> _fetchFromFirestore() async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      QuerySnapshot querySnapshot = await firestore.collection('clubs').get();

      _clubs = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Club(
          data['name'] ?? '',
          data['aboutMsg'] ?? '',
          data['email'] ?? '',
          data['acronym'] ?? '',
          data['instagram'] ?? '',
          data['logo'],
        );
      }).toList();
    } catch (e) {
      // Handle error silently or log if needed
      rethrow;
    }
  }

  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final clubData = _clubs
          .map((club) => {
                'name': club.name,
                'aboutMsg': club.aboutMsg,
                'email': club.email,
                'acronym': club.acronym,
                'instagram': club.instagram,
                'logo': club.logo,
              })
          .toList();

      await prefs.setString('cached_clubs', jsonEncode(clubData));
      await prefs.setInt(
          'clubs_last_fetch', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // Handle error silently or log if needed
    }
  }

  // Method to get club by name
  Club? getClubByName(String name) {
    try {
      return _clubs.firstWhere((club) => club.name == name);
    } catch (e) {
      return null;
    }
  }

  // Method to force refresh data
  Future<void> refreshClubs() async {
    _isLoaded = false;
    _clubs.clear();
    await _fetchFromFirestore();
    await _saveToCache();
    _isLoaded = true;
    notifyListeners();
  }

  // Method to clear cache
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_clubs');
    await prefs.remove('clubs_last_fetch');
    _clubs.clear();
    _isLoaded = false;
    _isLoading = false;
    notifyListeners();
  }
}
