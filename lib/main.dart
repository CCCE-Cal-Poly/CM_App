import 'package:ccce_application/common/collections/calevent.dart';
import 'package:ccce_application/common/collections/club.dart';
import 'package:ccce_application/common/collections/company.dart';
import 'package:ccce_application/common/widgets/gold_app_bar.dart';
import 'package:ccce_application/rendered_page.dart';
import 'package:ccce_application/common/features/onboarding/onboarding_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';

// import 'package:isar/isar.dart';
// import 'package:ccce_application/src/screens/profile_screen.dart';
// import 'package:ccce_application/src/screens/home_screen.dart';
Future<void> _requestNotificationPermissions() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('User granted provisional permission');
  } else {
    print('User declined or has not granted permission');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Request notification permissions when the app starts
  _requestNotificationPermissions();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>(create: (_) => AppState()),
        ChangeNotifierProvider<EventProvider>(create: (_) => EventProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class EventProvider extends ChangeNotifier {
  final List<CalEvent> _allEvents = [];
  bool _isLoaded = false;

  

  List<CalEvent> get allEvents => _allEvents;
  bool get isLoaded => _isLoaded;
  
  EventProvider() {
    fetchAllEvents();
  }
  Future<void> fetchAllEvents() async {
    print("I AM WORKING");
    if (_isLoaded) return;

    try {
      final snapshot = await FirebaseFirestore.instance.collection('events').get();
      print("Fetched ${snapshot.docs.length} event docs");
      _allEvents.clear();

      for (final doc in snapshot.docs) {
        try {
          final event = CalEvent.fromSnapshot(doc);
          print("✅ Loaded event: ${event.eventName} (${event.eventType})");
          _allEvents.add(event);
        } catch (e) {
          print("⚠️ Failed to parse event doc ${doc.id}: $e");
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

class AppState extends ChangeNotifier {
  Set<Company>? favoriteCompanies;
  Set<Club>? joinedClubs;
  Set<CalEvent>? checkedInSessions;
  Set<CalEvent>? calendarEvents;

  AppState({Set<Company>? favoriteCompanies, Set<Club>? joinedClubs, Set<CalEvent>? checkedInSessions, Set<CalEvent>? calendarEvents})
      : favoriteCompanies = favoriteCompanies ?? <Company>{},
        joinedClubs = joinedClubs ?? <Club>{},
        checkedInSessions = checkedInSessions ?? <CalEvent>{},
        calendarEvents = calendarEvents ?? <CalEvent>{};

  void addFavorite(Company company) {
    favoriteCompanies ??= <Company>{};
    favoriteCompanies!.add(company);
    notifyListeners();
  }

  bool isFavorite(Company company) {
    return favoriteCompanies?.contains(company) ?? false;
  }

  void removeFavorite(Company company) {
    favoriteCompanies?.remove(company);
    notifyListeners();
  }

  void addJoinedClub(Club club) {
    joinedClubs ??= <Club>{};
    joinedClubs!.add(club);
    notifyListeners();
  }

  bool isJoined(Club club) {
    return joinedClubs?.contains(club) ?? false;
  }

  void removeJoinedClub(Club club) {
    joinedClubs?.remove(club);
    notifyListeners();
  }

  bool isCheckedIn(CalEvent session) {
    return checkedInSessions?.contains(session) ?? false;
  }

  void checkInto(CalEvent session) {
    print("Checking into session: ${session.id}");
    print("Existing sessions in checkedInSessions: ${checkedInSessions?.map((e) => e.id).toList()}");

    checkedInSessions ??= <CalEvent>{};
    checkedInSessions!.add(session);
    notifyListeners();
  }

  void checkOutOf(CalEvent session) {
    checkedInSessions?.remove(session);
    notifyListeners();
  }

  void addToCalendar(CalEvent event) {
    calendarEvents ??= <CalEvent>{};
    calendarEvents!.add(event);
    notifyListeners();
  }

  void removeFromCalendar(CalEvent event) {
    calendarEvents?.remove(event);
    notifyListeners();
  }

  bool isInCalendar(CalEvent event) {
    return calendarEvents?.contains(event) ?? false;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> _isTOSAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('TOS') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
        future: _isTOSAccepted(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const MaterialApp(
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
            );
          }
          final tosAccepted = snapshot.data!;
          if (!tosAccepted) {
            return const MaterialApp(
              home: Scaffold(
                  appBar: GoldAppBar(),
                  body: RenderedPage()), // Show TOS/Onboarding screen
            );
          }
          return StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const MaterialApp(
                  home: Scaffold(appBar: GoldAppBar(), body: RenderedPage()),
                );
              }
              return Consumer<EventProvider>(
                builder: (context, eventProvider, child) {
                  if (!eventProvider.isLoaded) {
                    return const MaterialApp(
                      home: Scaffold(body: Center(child: CircularProgressIndicator())),
                    );
                  }
                  
                  return const MaterialApp(
                    home: Scaffold(appBar: GoldAppBar(), body: RenderedPage()),
                  );
                },
              );
            },
          );
        },
    );
  }
}