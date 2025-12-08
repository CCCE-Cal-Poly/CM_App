import 'package:ccce_application/common/collections/calevent.dart';
import 'package:ccce_application/common/collections/club.dart';
import 'package:ccce_application/common/providers/event_provider.dart';
import 'package:ccce_application/common/providers/app_state.dart';
import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/common/widgets/cal_poly_menu_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:collection';
import 'package:intl/intl.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:ccce_application/common/providers/user_provider.dart';
import 'package:ccce_application/services/error_logger.dart';

class HomeScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const HomeScreen({super.key, required this.scaffoldKey});
  @override
  CalendarScreenState createState() => CalendarScreenState();
}

HashMap<DateTime, List<CalEvent>> getEventsGroupedByDate(
    EventProvider provider) {
  final HashMap<DateTime, List<CalEvent>> events = HashMap();

  for (final event in provider.allEvents) {
    final start = event.startTime;
    final date = DateTime.utc(start.year, start.month, start.day);

    events.update(date, (value) {
      value.add(event);
      return value;
    }, ifAbsent: () => [event]);
  }

  return events;
}

class NotificationItem {
  final String title;
  final String message;
  final DateTime dateTime;
  NotificationItem(
      {required this.title, required this.message, required this.dateTime});
}

Map<String, List<NotificationItem>> groupNotifications(
    List<NotificationItem> notifications) {
  Map<String, List<NotificationItem>> grouped = {};
  for (var n in notifications) {
    String dateKey = DateFormat('yyyy-MM-dd').format(n.dateTime);
    if (!grouped.containsKey(dateKey)) {
      grouped[dateKey] = [];
    }
    grouped[dateKey]!.add(n);
  }
  return grouped;
}

class CalendarScreenState extends State<HomeScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  String _name = "";
  DateTime _focusedDay = DateTime.now();
  int _focusedMonth = DateTime.now().month;
  int _focusedYear = DateTime.now().year;
  DateTime? _selectedDay;
  late HashMap<DateTime, List<CalEvent>> eventMap = HashMap();
  bool _screenBool = false;
  
  // Track notifications for refresh
  Future<List<QuerySnapshot>>? _notificationsFuture;
  String? _lastUid;
  List<String>? _lastEventIds;
  List<String>? _lastClubIds;

  @override
  void initState() {
    super.initState();
    _focusedMonth = _focusedDay.month;
    _focusedYear = _focusedDay.year;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<EventProvider>(context, listen: false);
      if (provider.isLoaded) {
        setState(() {
                eventMap = getEventsGroupedByDate(provider);
      });
    }
  });
  }

  Future<void> _handleEventTap(CalEvent event) async {
    if (event.eventType.toLowerCase() == "club") {
      try {
        final clubName = event.eventName.split(' - ').first;
        
        final clubQuery = await FirebaseFirestore.instance
            .collection('clubs')
            .where('Acronym', isEqualTo: clubName)
            .limit(1)
            .get();
        
        if (clubQuery.docs.isNotEmpty) {
          final club = Club.fromDocument(clubQuery.docs.first);
          
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ClubPopUp(
                club: club,
                onClose: () => Navigator.of(context).pop(),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Club details not found')),
          );
        }
      } catch (e) {
        ErrorLogger.logError('HomeScreen', 'Error fetching club', error: e);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading club details')),
        );
      }
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => InfoSessionPopUp(
            infoSession: event,
            onClose: () => Navigator.of(context).pop(),
          ),
        ),
      );
    }
  }


  void updateFocusedDates(day) {
    _focusedDay = day;
    _focusedMonth = _focusedDay.month;
    _focusedYear = _focusedDay.year;
    return;
  }

  void updateEventsForDay(DateTime selectedDay) {
    setState(() {
      _selectedDay = selectedDay;
      updateFocusedDates(selectedDay);
      // Events are loaded via _getEventsForDay when needed
    });
  }

  List<CalEvent> _eventLoader(DateTime day) {
    final events = _getEventsForDay(day);
    return events;
  }

  List<CalEvent> _getEventsForDay(DateTime day) {
    final utcDay = DateTime.utc(day.year, day.month, day.day);
    return eventMap.putIfAbsent(utcDay, () => <CalEvent>[]);
  }

  List<Widget> _getNextEvents(DateTime day) {
    List<CalEvent> nextEvents = [];
    List<Widget> eventContainers = [];
    final utcDay = DateTime.utc(day.year, day.month, day.day);
    List<MapEntry<DateTime, List<CalEvent>>> sortedEntries =
        eventMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    for (var events in sortedEntries) {
      final eventDate = events.key;
      if (eventDate.isAfter(utcDay) && nextEvents.length < 3) {
        nextEvents.addAll(events.value);
      }
      if (nextEvents.length >= 3) {
        break;
      }
    }
    
    // Sort events by start time
    nextEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
    
    for (var ev in nextEvents) {
    Color boxColor = Colors.white;
    eventContainers.add(
      InkWell(
        onTap: () => _handleEventTap(ev),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 3.0),
          child: SizedBox(
            height: 65,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 65,
                  width: 80,
                  decoration: BoxDecoration(
                    color: boxColor,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('MMM d').format(ev.startTime),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontFamily: "AppFonts.sansProSemiBold",
                              fontSize: 11),
                        ),
                        Text(
                          "${DateFormat('h:mm a').format(ev.startTime)}-${DateFormat('h:mm a').format(ev.endTime)}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontFamily: "SansSerifPro", fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 1),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(color: boxColor),
                    child: Center(
                      child: Column(
                        children: [
                          AutoSizeText(
                            ev.eventName,
                            style: const TextStyle(
                                fontFamily: "AppFonts.sansProSemiBold",
                                fontSize: 13),
                            minFontSize: 10,
                            maxLines: 1,
                          ),
                          AutoSizeText(
                            ev.eventLocation,
                            style: const TextStyle(
                                fontFamily: "SansSerifPro", fontSize: 10),
                            minFontSize: 8,
                            maxLines: 1,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
    return eventContainers;
  }

  List<Widget> _getDayEvents(DateTime day) {
  List<Widget> eventContainers = [];
  final utcDay = DateTime.utc(day.year, day.month, day.day);
  List<CalEvent> evs = eventMap[utcDay] ?? [];
  
  // Sort events by start time
  evs.sort((a, b) => a.startTime.compareTo(b.startTime));
  
  for (var ev in evs) {
    Color boxColor = Colors.white;
    eventContainers.add(
      InkWell(
        onTap: () => _handleEventTap(ev),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 3.0),
          child: SizedBox(
            height: 65,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: MediaQuery.of(context).size.height * 0.027,
                  width: MediaQuery.of(context).size.width * 0.074,
                  decoration: BoxDecoration(
                    color: boxColor,
                  ),
                  child: Center(
                    child: AutoSizeText(
                      "${DateFormat('h:mm a').format(ev.startTime)}\n-\n${DateFormat('h:mm a').format(ev.endTime)}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: "SansSerifPro",
                        fontSize: 11,
                      ),
                      minFontSize: 8,
                      maxLines: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 1),
                Expanded(
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.027,
                    padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.015),
                    decoration: BoxDecoration(
                      color: boxColor,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AutoSizeText(
                            ev.eventName,
                            style: const TextStyle(
                                fontFamily: "AppFonts.sansProSemiBold",
                                fontSize: 13),
                            minFontSize: 10,
                            maxLines: 1,
                          ),
                          AutoSizeText(
                            ev.eventLocation,
                            style: const TextStyle(
                                fontFamily: "SansSerifPro", fontSize: 10),
                            minFontSize: 8,
                            maxLines: 1,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  return eventContainers;
}

  Widget buildCalendar(context) {
    return TableCalendar<CalEvent>(
      firstDay: DateTime.utc(2010, 10, 16),
      lastDay: DateTime.utc(2030, 3, 14),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },
      onDaySelected: (selectedDay, focusedDay) {
        updateEventsForDay(selectedDay);
      },
      calendarStyle: const CalendarStyle(
        defaultTextStyle: TextStyle(color: Colors.white),
        weekendTextStyle: TextStyle(color: Colors.white),
        markerSize: 6,
        markerDecoration:
            BoxDecoration(color: Color(0xFFE4E2D4), shape: BoxShape.circle),
        selectedDecoration:
            BoxDecoration(color: Color(0xFFA9A887), shape: BoxShape.circle),
        todayDecoration:
            BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
      ),
      daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: Colors.white),
          weekendStyle: TextStyle(color: Colors.white)),
      headerVisible: false,
      availableGestures: AvailableGestures.horizontalSwipe,
      startingDayOfWeek: StartingDayOfWeek.monday,
      onFormatChanged: (format) {
        if (_calendarFormat != format) {
          setState(() {
            _calendarFormat = format;
          });
        }
      },
      onPageChanged: (focusedDay) {
        setState(() {
          _selectedDay = focusedDay;
          updateFocusedDates(focusedDay);
        });
      },
      eventLoader: (day) => _eventLoader(day),
    );
  }

  String dateFormatter(monthInt, year) {
    switch (monthInt) {
      case 1:
        return "January ${year.toString()}";
      case 2:
        return "Feburary ${year.toString()}";
      case 3:
        return "March ${year.toString()}";
      case 4:
        return "April ${year.toString()}";
      case 5:
        return "May ${year.toString()}";
      case 6:
        return "June ${year.toString()}";
      case 7:
        return "July ${year.toString()}";
      case 8:
        return "August ${year.toString()}";
      case 9:
        return "September ${year.toString()}";
      case 10:
        return "October ${year.toString()}";
      case 11:
        return "November ${year.toString()}";
      case 12:
        return "December ${year.toString()}";
      default:
        return year.toString();
    }
  }

  String fullDateFormatter(monthInt, year, day) {
    switch (monthInt) {
      case 1:
        return "January $day, ${year.toString()}";
      case 2:
        return "Feburary $day, ${year.toString()}";
      case 3:
        return "March $day, ${year.toString()}";
      case 4:
        return "April $day, ${year.toString()}";
      case 5:
        return "May $day, ${year.toString()}";
      case 6:
        return "June $day, ${year.toString()}";
      case 7:
        return "July $day, ${year.toString()}";
      case 8:
        return "August $day, ${year.toString()}";
      case 9:
        return "September $day, ${year.toString()}";
      case 10:
        return "October $day, ${year.toString()}";
      case 11:
        return "November $day, ${year.toString()}";
      case 12:
        return "December $day, ${year.toString()}";
      default:
        return year.toString();
    }
  }

  List<Widget> buildEventList(context) {
    final screenHeight = MediaQuery.of(context).size.height;
    var eventContainers = _getDayEvents(_focusedDay);

    if (eventContainers.isEmpty) {
      return [
        SizedBox(height: screenHeight * 0.02),
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Text(
              fullDateFormatter(_focusedMonth, _focusedYear, _focusedDay.day),
              style: const TextStyle(
                  color: AppColors.tanText,
                  fontFamily: "SansSerifPro",
                  fontSize: 20)),
        ),
        SizedBox(height: screenHeight * 0.01),
        Container(
          height: screenHeight * 0.08,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                "There are no events today.\nCheckout upcoming events below:",
                textAlign: TextAlign.center,
                style: TextStyle(
                fontFamily: "SansSerifProItalic", fontSize: 14
                )
              )
            )
          )
        ),
        const SizedBox(height: 3.0),
        ..._getNextEvents(_focusedDay),
        const SizedBox(height: 20.0),
      ];
    }

    return [
      SizedBox(height: screenHeight * 0.02),
      Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: Text(
            fullDateFormatter(_focusedMonth, _focusedYear, _focusedDay.day),
            style: const TextStyle(
                color: AppColors.tanText,
                fontFamily: "SansSerifPro",
                fontSize: 20)),
      ),
      SizedBox(height: screenHeight * 0.01),
      ...eventContainers,
      const SizedBox(height: 20.0),
    ];
  }

  Widget buildEventDisplay(context) {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: buildEventList(context)),
      ),
    );
  }

  // Fetch notifications using one-time reads for efficiency
  Future<List<QuerySnapshot>> _fetchNotifications(
    String uid,
    List<String> checkedInEventIds,
    List<String> joinedClubIds,
  ) async {
    final List<Future<QuerySnapshot>> queries = [];
    
    // 1. Broadcast notifications (for all users)
    queries.add(
      FirebaseFirestore.instance
          .collection('notifications')
          .where('targetType', isEqualTo: 'broadcast')
          .where('status', whereIn: ['sent', 'pending'])
          .get(),
    );

    // 2. User-specific notifications
    queries.add(
      FirebaseFirestore.instance
          .collection('notifications')
          .where('targetType', isEqualTo: 'user')
          .where('targetId', isEqualTo: uid)
          .where('status', whereIn: ['sent', 'pending'])
          .get(),
    );

    // 3. Event notifications for checked-in events (batched to avoid limit)
    if (checkedInEventIds.isNotEmpty) {
      for (int i = 0; i < checkedInEventIds.length; i += 10) {
        final batch = checkedInEventIds.skip(i).take(10).toList();
        if (batch.isNotEmpty) {
          queries.add(
            FirebaseFirestore.instance
                .collection('notifications')
                .where('targetType', isEqualTo: 'event')
                .where('targetId', whereIn: batch)
                .where('status', whereIn: ['sent', 'pending'])
                .get(),
          );
        }
      }
    }

    // 4. Club notifications for joined clubs (batched to avoid limit)
    if (joinedClubIds.isNotEmpty) {
      for (int i = 0; i < joinedClubIds.length; i += 10) {
        final batch = joinedClubIds.skip(i).take(10).toList();
        if (batch.isNotEmpty) {
          queries.add(
            FirebaseFirestore.instance
                .collection('notifications')
                .where('targetType', isEqualTo: 'club')
                .where('targetId', whereIn: batch)
                .where('status', whereIn: ['sent', 'pending'])
                .get(),
          );
        }
      }
    }

    // Execute all queries in parallel
    return await Future.wait(queries);
  }

  Widget buildAnnouncementList(context) {
    final userProvider = Provider.of<UserProvider>(context);
    final uid = userProvider.user?.uid;
    final appState = Provider.of<AppState>(context);

    if (uid == null) {
      // User not loaded - show empty state
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Sign in to view notifications',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

    // Get user's checked-in event IDs for efficient querying
    final checkedInEventIds = appState.checkedInEventIds?.toList() ?? [];

    // Get joined club IDs
    final joinedClubIds = appState.joinedClubs?.map((c) => c.id).whereType<String>().toList() ?? [];

    // Initialize or refresh future if parameters changed
    if (_notificationsFuture == null || 
        _lastUid != uid || 
        _lastEventIds?.join(',') != checkedInEventIds.join(',') || 
        _lastClubIds?.join(',') != joinedClubIds.join(',')) {
      _notificationsFuture = _fetchNotifications(uid, checkedInEventIds, joinedClubIds);
      _lastUid = uid;
      _lastEventIds = checkedInEventIds;
      _lastClubIds = joinedClubIds;
    }

    return FutureBuilder<List<QuerySnapshot>>(
      future: _notificationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Error loading notifications',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          );
        }
        
        // Combine all documents from multiple queries
        final allDocs = <QueryDocumentSnapshot>[];
        if (snapshot.hasData) {
          for (final querySnapshot in snapshot.data!) {
            allDocs.addAll(querySnapshot.docs);
          }
        }
        
        // Remove duplicates (same notification ID)
        final seenIds = <String>{};
        final uniqueDocs = allDocs.where((doc) {
          if (seenIds.contains(doc.id)) return false;
          seenIds.add(doc.id);
          return true;
        }).toList();
        
        // Filter for pending notifications scheduled within the next week
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final oneWeekFromNow = today.add(const Duration(days: 7));
        
        final eligibleDocs = uniqueDocs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final status = data['status'];
          
          // For pending notifications, only show if sendAt is within the next week
          if (status == 'pending') {
            final sendAt = data['sendAt'];
            if (sendAt is Timestamp) {
              final sendDate = sendAt.toDate();
              // Only show pending notifications with sendAt within the next 7 days
              return !sendDate.isBefore(today) && sendDate.isBefore(oneWeekFromNow);
            }
            return false;
          }
          
          return true; // Show all 'sent' notifications
        }).toList();
        
        final List<NotificationItem> items = eligibleDocs.map((d) {
          final data = d.data() as Map<String, dynamic>;
          final title = data['title'] ?? 'Notification';
          final message = data['message'] ?? '';
          
          // Priority: eventData.startTime (actual event time) > sendAt > createdAt
          DateTime dateTime;
          final eventData = data['eventData'] as Map<String, dynamic>?;
          final eventStartTime = eventData?['startTime'];
          final sendAt = data['sendAt'];
          
          if (eventStartTime is Timestamp) {
            // For event reminders, use the actual event start time
            dateTime = eventStartTime.toDate();
          } else if (sendAt is Timestamp) {
            // For scheduled notifications, use sendAt + 1 hour to get event time
            dateTime = sendAt.toDate().add(const Duration(hours: 1));
          } else {
            // Fallback to createdAt
            final ts = data['createdAt'];
            if (ts is Timestamp) {
              dateTime = ts.toDate();
            } else {
              dateTime = DateTime.now();
            }
          }
          
          return NotificationItem(title: title, message: message, dateTime: dateTime);
        }).toList();

        List<NotificationItem> upcoming = items
            .where((n) => !n.dateTime.isBefore(DateTime(now.year, now.month, now.day)))
            .toList();
        final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
        List<NotificationItem> past = items
            .where((n) => n.dateTime.isBefore(DateTime(now.year, now.month, now.day)) && n.dateTime.isAfter(oneMonthAgo))
            .toList();
        upcoming.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        past.sort((a, b) => b.dateTime.compareTo(a.dateTime));

        List<Widget> sectionWidgets(String title, List<NotificationItem> list) {
          if (list.isEmpty) return [Padding(padding: EdgeInsets.all(12), child: AutoSizeText('No $title notifications', style: TextStyle(color: Colors.white), minFontSize: 12, maxLines: 1) )];
          final grouped = groupNotifications(list);
          final sortedKeys = grouped.keys.toList()..sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));
          final widgets = <Widget>[];
          widgets.add(Padding(padding: const EdgeInsets.only(left: 16, top: 12, bottom: 8), child: AutoSizeText(title, style: const TextStyle(color: Colors.white, fontSize: 24), minFontSize: 18, maxLines: 1)));
          for (final key in sortedKeys) {
            widgets.add(Padding(
                padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                child: AutoSizeText(
                    DateFormat('EEEE, MMMM d').format(DateTime.parse(key)),
                    style: const TextStyle(color: AppColors.tanText, fontSize: 18),
                    minFontSize: 14,
                    maxLines: 1)));

            final mapped = grouped[key]!.map((n) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.027,
                    child: Row(
                      children: [
                        Container(
                          height: MediaQuery.of(context).size.height * 0.027,
                          width: MediaQuery.of(context).size.width * 0.074,
                          decoration:
                              const BoxDecoration(color: Colors.white),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AutoSizeText(
                                    DateFormat('MMM d')
                                        .format(n.dateTime),
                                    style: const TextStyle(
                                        fontFamily:
                                            "AppFonts.sansProSemiBold",
                                        fontSize: 11,
                                        color: AppColors.darkGoldText),
                                    minFontSize: 8,
                                    maxLines: 1),
                                AutoSizeText(
                                    DateFormat('h:mm a')
                                        .format(n.dateTime),
                                    style: const TextStyle(
                                        fontFamily: "SansSerifPro",
                                        fontSize: 10,
                                        color: AppColors.darkGoldText),
                                    minFontSize: 7,
                                    maxLines: 1),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 1),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.only(
                                left: MediaQuery.of(context).size.width * 0.011, top: MediaQuery.of(context).size.height * 0.0025),
                            decoration:
                                const BoxDecoration(color: Colors.white),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AutoSizeText(n.title,
                                    style: const TextStyle(
                                        fontFamily:
                                            "AppFonts.sansProSemiBold",
                                        fontSize: 13),
                                    minFontSize: 10,
                                    maxLines: 1),
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                        padding: EdgeInsets.only(top: 2.0),
                                        child: Icon(Icons.notifications,
                                            size: 10,
                                            color: AppColors.darkGoldText)),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            left: 2.0),
                                        child: SizedBox(
                                          height: MediaQuery.of(context).size.height * 0.013,
                                          child: SingleChildScrollView(
                                              scrollDirection:
                                                  Axis.vertical,
                                              child: AutoSizeText(n.message,
                                                  style: const TextStyle(
                                                      fontFamily:
                                                          "SansSerifPro",
                                                      fontSize: 10,
                                                      color: AppColors
                                                          .darkGoldText),
                                                  minFontSize: 7,
                                                  maxLines: 3)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )).toList();

            widgets.addAll(mapped);
          }
          return widgets;
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Force refresh notifications
            setState(() {
              _notificationsFuture = _fetchNotifications(uid, checkedInEventIds, joinedClubIds);
            });
            // Wait for fetch to complete
            await _notificationsFuture;
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const Divider(color: Colors.white, thickness: 1, indent: 20, endIndent: 60),
              ...sectionWidgets('Upcoming', upcoming),
              const SizedBox(height: 12),
              const Divider(indent: 20, endIndent: 60, color: Colors.white, thickness: 1),
              ...sectionWidgets('Past', past),
            ],
          ),
        );
      },
    );
  }

  Widget buildAnnouncementDisplay(context) {
    return Expanded(
      child: buildAnnouncementList(context),
    );
    //child: Column(
    //  children: <Widget>[const Text("HI"), buildEventList()])));
  }

  final WidgetStateProperty<Icon?> thumbIcon =
      WidgetStateProperty.resolveWith<Icon?>(
    (Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        return const Icon(
          Icons.circle_notifications,
          size: 24,
        );
      }
      return const Icon(Icons.calendar_month, color: Colors.black);
    },
  );

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    Widget calWidget = buildCalendar(context);
    Widget eventDisplayWidget = buildEventDisplay(context);
    Widget announcementDisplayWidget = buildAnnouncementDisplay(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20),
        child: Column(mainAxisSize: MainAxisSize.max, children: <Widget>[
          CalPolyMenuBar(scaffoldKey: widget.scaffoldKey),
          SizedBox(height: screenHeight * 0.04),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: AutoSizeText(
                  _screenBool ? "Notifications" : "Calendar",
                  style: const TextStyle(
                      color: AppColors.tanText,
                      fontWeight: FontWeight.w600,
                      fontSize: 26),
                  minFontSize: 20,
                  maxLines: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      color: Colors.white,
                      size: 20,
                    ),
                    Switch(
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.grey,
                      activeTrackColor: Colors.grey,
                      value: _screenBool,
                      onChanged: (value) {
                        setState(() {
                          _screenBool = value;
                        });
                      },
                    ),
                    const Icon(
                      Icons.circle_notifications,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              )
            ],
          ),
          _screenBool
              ? Container()
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: AutoSizeText(_name.isEmpty ? "Hi!" : "Hi $_name!",
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w300,
                                color: Colors.white),
                            minFontSize: 16,
                            maxLines: 1)),
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: AutoSizeText(dateFormatter(_focusedMonth, _focusedYear),
                          style: const TextStyle(
                            fontFamily: "AppFonts.sansProSemiBold",
                            fontSize: 20,
                            color: AppColors.tanText,
                          ),
                          minFontSize: 16,
                          maxLines: 1),
                    ),
                  ],
                ),
          SizedBox(
              height:
                  _screenBool ? (screenHeight * 0.02) : (screenHeight * 0.04)),
          _screenBool ? announcementDisplayWidget : calWidget,
          _screenBool ? Container() : eventDisplayWidget
        ]),
      ),
      backgroundColor: AppColors.calPolyGreen,
    );
  }
}
