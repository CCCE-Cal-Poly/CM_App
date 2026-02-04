import 'package:ccce_application/common/collections/favoritable.dart';
import 'package:ccce_application/common/collections/job.dart';
import 'package:flutter/material.dart';
import 'package:ccce_application/common/collections/company.dart';
import 'package:ccce_application/common/collections/club.dart';
import 'package:ccce_application/common/collections/calevent.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ccce_application/services/error_logger.dart';

class AppState extends ChangeNotifier {
  Set<Company>? favoriteCompanies;
  Set<Job>? favoriteJobs;
  Set<Club>? joinedClubs;
  Set<String>? checkedInEventIds; 
  Set<CalEvent>? calendarEvents;
  bool _isLoadingCheckIns = false;
  bool _checkInsLoaded = false;
  bool _isLoadingFavorites = false;
  bool _favoritesLoaded = false;
  bool _isLoadingClubs = false;
  bool _clubsLoaded = false;
  
  bool get isCheckInsLoaded => _checkInsLoaded;
  bool get isFavoritesLoaded => _favoritesLoaded;
  bool get isClubsLoaded => _clubsLoaded;

  AppState({
    Set<Company>? favoriteCompanies,
    Set<Job>? favoriteJobs,
    Set<Club>? joinedClubs,
    Set<String>? checkedInEventIds,
    Set<CalEvent>? calendarEvents,
  })  : favoriteCompanies = favoriteCompanies ?? <Company>{},
        favoriteJobs = favoriteJobs ?? <Job>{},
        joinedClubs = joinedClubs ?? <Club>{},
        checkedInEventIds = checkedInEventIds ?? <String>{},
        calendarEvents = calendarEvents ?? <CalEvent>{} {
    _loadCheckIns();
    _loadFavoriteCompanies();
    _loadJoinedClubs();
  }

  Future<void> _loadCheckIns() async {
    if (_isLoadingCheckIns) return;
    _isLoadingCheckIns = true;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ErrorLogger.logWarning('AppState', 'No user logged in, skipping check-in load');
        _isLoadingCheckIns = false;
        return;
      }

      final checkInsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('checkedInEvents')
          .get();

      final Set<String> loadedEventIds = {};
      
      for (final doc in checkInsSnapshot.docs) {
        loadedEventIds.add(doc.id); 
      }

      checkedInEventIds = loadedEventIds;
      _checkInsLoaded = true;
      ErrorLogger.logInfo('AppState', 'Loaded ${loadedEventIds.length} check-ins from Firestore');
      notifyListeners();
    } catch (e) {
      ErrorLogger.logError('AppState', 'Error loading check-ins', error: e);
      _checkInsLoaded = true;
      notifyListeners();
    } finally {
      _isLoadingCheckIns = false;
    }
  }

  Future<void> _loadFavoriteCompanies() async {
    if (_isLoadingFavorites) return;
    _isLoadingFavorites = true;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ErrorLogger.logWarning('AppState', 'No user logged in, skipping favorites load');
        _isLoadingFavorites = false;
        return;
      }

      final favoritesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favoriteCompanies')
          .get();

      final Set<Company> loadedFavorites = {};
      
      for (final doc in favoritesSnapshot.docs) {
        final data = doc.data();
        loadedFavorites.add(Company(
          id: doc.id,
          name: data['name'] ?? '',
          location: data['location'] ?? '',
          aboutMsg: data['aboutMsg'] ?? '',
          msg: data['msg'] ?? '',
          recruiterName: data['recruiterName'] ?? '',
          recruiterTitle: data['recruiterTitle'] ?? '',
          recruiterEmail: data['recruiterEmail'] ?? '',
          logo: data['logo'],
          offeredJobs: {},
        ));
      }

      favoriteCompanies = loadedFavorites;
      _favoritesLoaded = true;
      ErrorLogger.logInfo('AppState', 'Loaded ${loadedFavorites.length} favorite companies from Firestore');
      notifyListeners();
    } catch (e) {
      ErrorLogger.logError('AppState', 'Error loading favorite companies', error: e);
      _favoritesLoaded = true;
      notifyListeners();
    } finally {
      _isLoadingFavorites = false;
    }
  }

  Future<void> _loadJoinedClubs() async {
    if (_isLoadingClubs) return;
    _isLoadingClubs = true;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ErrorLogger.logWarning('AppState', 'No user logged in, skipping clubs load');
        _isLoadingClubs = false;
        return;
      }

      final clubsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('joinedClubs')
          .get();

      final Set<Club> loadedClubs = {};
      
      for (final doc in clubsSnapshot.docs) {
        final data = doc.data();
        loadedClubs.add(Club(
          id: (data['clubId']?.toString() ?? doc.id.toString()),
          name: data['name'] ?? '',
          aboutMsg: data['aboutMsg'] ?? '',
          email: data['email'] ?? '',
          acronym: data['acronym'] ?? '',
          instagram: data['instagram'] ?? '',
          logo: data['logo'],
        ));
      }
      joinedClubs = loadedClubs;
      _clubsLoaded = true;
      ErrorLogger.logInfo('AppState', 'Loaded ${loadedClubs.length} joined clubs from Firestore');
      notifyListeners();
    } catch (e) {
      ErrorLogger.logError('AppState', 'Error loading joined clubs', error: e);
      _clubsLoaded = true;
      notifyListeners();
    } finally {
      _isLoadingClubs = false;
    }
  }

  Future<void> addFavorite(Favoritable item) async {
    if (item is Company) {
      ErrorLogger.logInfo('AppState', 'Adding favorite company: ${item.name}');
      
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          ErrorLogger.logWarning('AppState', 'No user logged in, cannot add favorite');
          return;
        }

        favoriteCompanies ??= <Company>{};
        favoriteCompanies!.add(item);
        notifyListeners();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favoriteCompanies')
            .doc(item.id)
            .set({
          'companyId': item.id,
          'name': item.name,
          'location': item.location,
          'aboutMsg': item.aboutMsg,
          'msg': item.msg,
          'recruiterName': item.recruiterName,
          'recruiterTitle': item.recruiterTitle,
          'recruiterEmail': item.recruiterEmail,
          'logo': item.logo,
          'favoritedAt': FieldValue.serverTimestamp(),
        });

        ErrorLogger.logInfo('AppState', 'Added favorite company: ${item.name}');
      } catch (e) {
        ErrorLogger.logError('AppState', 'Error adding favorite company', error: e);
        favoriteCompanies?.remove(item);
        notifyListeners();
      }
    }
    if (item is Job) {
      favoriteJobs ??= <Job>{};
      favoriteJobs!.add(item);
      notifyListeners();
    }
  }

  bool isFavorite(Favoritable item) {
     // ignore: curly_braces_in_flow_control_structures
     if (item is Company) return favoriteCompanies?.contains(item) ?? false;
     // ignore: curly_braces_in_flow_control_structures
     else return favoriteJobs?.contains(item) ?? false;
  }

  Future<void> removeFavorite(Favoritable item) async {
    if (item is Company) {
      ErrorLogger.logInfo('AppState', 'Removing favorite company: ${item.name}');
      
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          ErrorLogger.logWarning('AppState', 'No user logged in, cannot remove favorite');
          return;
        }

        favoriteCompanies?.remove(item);
        notifyListeners();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favoriteCompanies')
            .doc(item.id)
            .delete();

        ErrorLogger.logInfo('AppState', 'Removed favorite company: ${item.name}');
      } catch (e) {
        ErrorLogger.logError('AppState', 'Error removing favorite company', error: e);
        favoriteCompanies?.add(item);
        notifyListeners();
      }
    }
    if (item is Job) {
      favoriteJobs?.remove(item);
      notifyListeners();
    }
  }

  Future<void> addJoinedClub(Club club) async {
    ErrorLogger.logInfo('AppState', 'Joining club: ${club.name}');
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ErrorLogger.logWarning('AppState', 'No user logged in, cannot join club');
        return;
      }

      joinedClubs ??= <Club>{};
      joinedClubs!.add(club);
      notifyListeners();

      final clubData = {
        'clubId': club.id,
        'name': club.name,
        'aboutMsg': club.aboutMsg,
        'email': club.email,
        'acronym': club.acronym,
        'instagram': club.instagram,
        'logo': club.logo,
        'joinedAt': FieldValue.serverTimestamp(),
      };

      // Dual-write: Write to both user's joinedClubs AND club's members collection
      // This ensures club notifications can efficiently find all members
      // Get user's name from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      final userData = userDoc.data();
      final userName = userData?['name'] ?? 
          '${userData?['firstName'] ?? ''} ${userData?['lastName'] ?? ''}'.trim();

      await Future.wait([
        // User's personal club list (full club data)
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('joinedClubs')
            .doc(club.id?.toString())
            .set(clubData),
        
        // Club's member list (for notifications - minimal data)
        FirebaseFirestore.instance
            .collection('clubs')
            .doc(club.id?.toString())
            .collection('members')
            .doc(user.uid)
            .set({
          'uid': user.uid,
          'name': userName.isNotEmpty ? userName : user.email ?? 'Unknown',
          'joinedAt': FieldValue.serverTimestamp(),
        }),
      ]);

      ErrorLogger.logInfo('AppState', 'Joined club: ${club.name} (dual-write completed)');
    } catch (e) {
      ErrorLogger.logError('AppState', 'Error joining club', error: e);
      joinedClubs?.remove(club);
      notifyListeners();
    }
  }

  bool isJoined(Club club) {
    if (joinedClubs == null) return false;
    return joinedClubs!.any((c) => c.id.toString() == club.id.toString());
  }

  Future<void> removeJoinedClub(Club club) async {
    ErrorLogger.logInfo('AppState', 'Leaving club: ${club.name}');
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ErrorLogger.logWarning('AppState', 'No user logged in, cannot leave club');
        return;
      }

      joinedClubs?.remove(club);
      notifyListeners();

      // Dual-delete: Remove from both user's joinedClubs AND club's members collection
      await Future.wait([
        // User's personal club list
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('joinedClubs')
            .doc(club.id?.toString())
            .delete(),
        
        // Club's member list (for notifications)
        FirebaseFirestore.instance
            .collection('clubs')
            .doc(club.id?.toString())
            .collection('members')
            .doc(user.uid)
            .delete(),
      ]);

      ErrorLogger.logInfo('AppState', 'Left club: ${club.name} (dual-delete completed)');
    } catch (e) {
      ErrorLogger.logError('AppState', 'Error leaving club', error: e);
      joinedClubs?.add(club);
      notifyListeners();
    }
  }

  bool isCheckedIn(CalEvent session) {
    return checkedInEventIds?.contains(session.id) ?? false;
  }

  Future<void> checkInto(CalEvent session) async {
    ErrorLogger.logInfo('AppState', 'Checking into session: ${session.eventName}');
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ErrorLogger.logWarning('AppState', 'No user logged in, cannot check in');
        return;
      }

      checkedInEventIds ??= <String>{};
      checkedInEventIds!.add(session.id);
      notifyListeners();

      // Dual-write: Write to both user's checkedInEvents AND event's attending collection
      // This ensures notifications can query event attendees efficiently
      await Future.wait([
        // User's view (full event data)
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('checkedInEvents')
            .doc(session.id)
            .set({
          'eventId': session.id,
          'eventName': session.eventName,
          'checkedInAt': FieldValue.serverTimestamp(),
        }),
        // Event's attending list (for notifications - minimal data)
        FirebaseFirestore.instance
            .collection('events')
            .doc(session.id)
            .collection('attending')
            .doc(user.uid)
            .set({
          'uid': user.uid,
          'checkedInAt': FieldValue.serverTimestamp(),
        }),
      ]);

      ErrorLogger.logInfo('AppState', 'Checked in to ${session.eventName} (dual-write completed)');
    } catch (e) {
      ErrorLogger.logError('AppState', 'Error checking in', error: e);
      checkedInEventIds?.remove(session.id);
      notifyListeners();
    }
  }

  Future<void> checkOutOf(CalEvent session) async {
    ErrorLogger.logInfo('AppState', 'Checking out of session: ${session.eventName}');
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ErrorLogger.logWarning('AppState', 'No user logged in, cannot check out');
        return;
      }

      checkedInEventIds?.remove(session.id);
      notifyListeners();

      // Dual-delete: Remove from both user's checkedInEvents AND event's attending collection
      await Future.wait([
        // User's view
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('checkedInEvents')
            .doc(session.id)
            .delete(),
        // Event's attending list (for notifications)
        FirebaseFirestore.instance
            .collection('events')
            .doc(session.id)
            .collection('attending')
            .doc(user.uid)
            .delete(),
      ]);

      ErrorLogger.logInfo('AppState', 'Checked out of ${session.eventName} (dual-delete completed)');
    } catch (e) {
      ErrorLogger.logError('AppState', 'Error checking out', error: e);
      checkedInEventIds?.add(session.id);
      notifyListeners();
    }
  }
}
