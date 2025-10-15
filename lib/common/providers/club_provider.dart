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

  List<String> get clubAcronyms {
    if (_clubs.isEmpty) {
      return [];
    }
    return _clubs.map((club) => club.acronym.toString()).toList();
  }

  Future<void> loadClubs() async {
    if (_isLoaded || _isLoading) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _loadFromCache();

      final prefs = await SharedPreferences.getInstance();
      final lastFetch = prefs.getInt('clubs_last_fetch') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final cacheAge = now - lastFetch;

      if (cacheAge > 3600000 || _clubs.isEmpty) {
        await _fetchFromFirestore();
        await _saveToCache();
      }

      if (_clubs.isNotEmpty) {
        _isLoaded = true;
      }
    } catch (e) {
      // Handle error silently
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
                  id: data['id'] ?? '',
                  name: data['name'] ?? '',
                  aboutMsg: data['aboutMsg'] ?? '',
                  email: data['email'] ?? '',
                  acronym: data['acronym'] ?? '',
                  instagram: data['instagram'] ?? '',
                  logo: data['logo'],
                ))
            .toList();
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _fetchFromFirestore() async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      QuerySnapshot querySnapshot = await firestore.collection('clubs').get();
      // Use the Club.fromDocument factory so field name variants are handled consistently
      _clubs = querySnapshot.docs.map((doc) => Club.fromDocument(doc)).toList();
    } catch (e) {
      // Handle error silently
      rethrow;
    }
  }

  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final clubData = _clubs
          .map((club) => {
                'id': club.id,
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
      // Handle error silently
    }
  }

  Club? getClubByName(String name) {
    try {
      return _clubs.firstWhere((club) => club.name == name);
    } catch (e) {
      return null;
    }
  }

  Future<void> refreshClubs() async {
    _isLoaded = false;
    _clubs.clear();
    await _fetchFromFirestore();
    await _saveToCache();
    _isLoaded = true;
    notifyListeners();
  }

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
