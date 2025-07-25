import 'package:flutter/material.dart';
import 'package:ccce_application/common/collections/company.dart';
import 'package:ccce_application/common/collections/club.dart';
import 'package:ccce_application/common/collections/calevent.dart';

class AppState extends ChangeNotifier {
  Set<Company>? favoriteCompanies;
  Set<Club>? joinedClubs;
  Set<CalEvent>? checkedInSessions;
  Set<CalEvent>? calendarEvents;

  AppState({
    Set<Company>? favoriteCompanies,
    Set<Club>? joinedClubs,
    Set<CalEvent>? checkedInSessions,
    Set<CalEvent>? calendarEvents,
  })  : favoriteCompanies = favoriteCompanies ?? <Company>{},
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
