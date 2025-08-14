import 'package:ccce_application/common/collections/favoritable.dart';
import 'package:ccce_application/common/collections/job.dart';
import 'package:flutter/material.dart';
import 'package:ccce_application/common/collections/company.dart';
import 'package:ccce_application/common/collections/club.dart';
import 'package:ccce_application/common/collections/calevent.dart';

class AppState extends ChangeNotifier {
  Set<Company>? favoriteCompanies;
  Set<Job>? favoriteJobs;
  Set<Club>? joinedClubs;
  Set<CalEvent>? checkedInSessions;
  Set<CalEvent>? calendarEvents;

  AppState({
    Set<Company>? favoriteCompanies,
    Set<Job>? favoriteJobs,
    Set<Club>? joinedClubs,
    Set<CalEvent>? checkedInSessions,
    Set<CalEvent>? calendarEvents,
  })  : favoriteCompanies = favoriteCompanies ?? <Company>{},
        favoriteJobs = favoriteJobs ?? <Job>{},
        joinedClubs = joinedClubs ?? <Club>{},
        checkedInSessions = checkedInSessions ?? <CalEvent>{},
        calendarEvents = calendarEvents ?? <CalEvent>{};

  void addFavorite(Favoritable item) {
    if (item is Company) {
      favoriteCompanies ??= <Company>{};
      favoriteCompanies!.add(item);
    }
    if (item is Job) {
      favoriteJobs ??= <Job>{};
      favoriteJobs!.add(item);
    }
    notifyListeners();
  }

  bool isFavorite(Favoritable item) {
     // ignore: curly_braces_in_flow_control_structures
     if (item is Company) return favoriteCompanies?.contains(item) ?? false;
     // ignore: curly_braces_in_flow_control_structures
     else return favoriteJobs?.contains(item) ?? false;
  }

  void removeFavorite(Favoritable item) {
    if (item is Company) favoriteCompanies?.remove(item);
    if (item is Job) favoriteJobs?.remove(item);
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
    print("Checking into session: [32m");
    print(
        "Existing sessions in checkedInSessions: [32m");
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
