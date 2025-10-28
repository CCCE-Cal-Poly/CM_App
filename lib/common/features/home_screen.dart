import 'package:ccce_application/common/collections/calevent.dart';
import 'package:ccce_application/common/collections/club.dart';
import 'package:ccce_application/common/providers/event_provider.dart';
import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/common/widgets/cal_poly_menu_bar.dart';
import 'package:ccce_application/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:collection';
import 'package:intl/intl.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:ccce_application/common/providers/user_provider.dart';

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

List<NotificationItem> mockNotifications = [
  NotificationItem(
    title: 'Jeong Woo',
    message: 'Remember to bring hard hats on February 23rd!',
    dateTime: DateTime(2025, 7, 14, 9, 0),
  ),
  NotificationItem(
    title: 'Jeong Woo',
    message:
        'Do not bring hard hats on February 23rd! Do not bring hard hats on February 23rd!Do not bring hard hats on February 23rd! Do not bring hard hats on February 23rd!',
    dateTime: DateTime(2025, 7, 14, 8, 0),
  ),
  NotificationItem(
    title: 'HITT Info Session',
    message: 'Please submit all senior photos by this Friday!',
    dateTime: DateTime(2025, 6, 14, 10, 0),
  ),
  NotificationItem(
    title: 'Emma Blair',
    message: 'Pick up keycards for Construction Management room.',
    dateTime: DateTime(2025, 8, 13, 8, 0),
  ),
  NotificationItem(
    title: 'Jeong Woo',
    message: 'Bring graduation cords Tuesday.',
    dateTime: DateTime(2025, 6, 13, 11, 0),
  ),
];

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
  List _selectedEvents = [];
  bool _screenBool = false;

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
        print('Error fetching club: $e');
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
      _selectedEvents = _eventLoader(selectedDay);
    });
  }

  List<CalEvent> _eventLoader(DateTime day) {
    final events = _getEventsForDay(day);
    //print('${day} ${events}');
    return events;
  }

  List<CalEvent> _getEventsForDay(DateTime day) {
    return eventMap.putIfAbsent(day, () => <CalEvent>[]);
    //return events.values.expand((list) => list).where((event) => isSameDay(event.startTime, day)).toList();
  }

  List<Widget> _getNextEvents(DateTime day) {
    List<CalEvent> nextEvents = [];
    List<Widget> eventContainers = [];
    List<MapEntry<DateTime, List<CalEvent>>> sortedEntries =
        eventMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    for (var events in sortedEntries) {
      final eventDate = events.key;
      if (eventDate.isAfter(day) && nextEvents.length < 3) {
        nextEvents.addAll(events.value);
      }
      if (nextEvents.length >= 3) {
        break;
      }
    }
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
                          "${DateFormat('hh:mm a').format(ev.startTime)}-${DateFormat('hh:mm a').format(ev.endTime)}",
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
  List<CalEvent> evs = eventMap[day] ?? [];
  
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
                  height: 65,
                  width: 80,
                  decoration: BoxDecoration(
                    color: boxColor,
                  ),
                  child: Center(
                    child: Text(
                      "${DateFormat('hh:mm a').format(ev.startTime)}\n-\n${DateFormat('hh:mm a').format(ev.endTime)}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: "SansSerifPro",
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 1),
                Expanded(
                  child: Container(
                    height: 65,
                    padding: const EdgeInsets.all(16.0),
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

  Widget buildAnnouncementList(context) {
    final userProvider = Provider.of<UserProvider>(context);
    final uid = userProvider.user?.uid;

    if (uid == null) {
      // Fallback to local mockNotifications if user not loaded
      final now = DateTime.now();
      List<NotificationItem> upcoming = mockNotifications
          .where((n) =>
              !n.dateTime.isBefore(DateTime(now.year, now.month, now.day)))
          .toList();
      final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
      List<NotificationItem> past = mockNotifications
          .where((n) =>
              n.dateTime.isBefore(DateTime(now.year, now.month, now.day)) &&
              n.dateTime.isAfter(oneMonthAgo))
          .toList();
      upcoming.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      past.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      Widget sectionHeader(String text, {bool italic = false}) => Padding(
            padding: const EdgeInsets.only(left: 16, top: 12, bottom: 8),
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontFamily: italic ? "SansSerifProItalic" : "SansSerifPro",
                fontSize: 24,
                fontStyle: italic ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          );

      Widget dateHeader(DateTime date) => Padding(
            padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
            child: Text(
              DateFormat('EEEE, MMMM d').format(date),
              style: const TextStyle(
                color: AppColors.tanText,
                fontFamily: "SansSerifPro",
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          );

      Widget notificationRow(NotificationItem n) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
            child: SizedBox(
              height: 65,
              child: Row(
                children: [
                  Container(
                      height: 65,
                      width: 80,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('MMM d').format(n.dateTime),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontFamily: "AppFonts.sansProSemiBold",
                                  fontSize: 11,
                                  color: AppColors.darkGoldText),
                            ),
                            Text(
                              DateFormat('hh:mm a').format(n.dateTime),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontFamily: "SansSerifPro",
                                  fontSize: 10,
                                  color: AppColors.darkGoldText),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(width: 1),
                  Expanded(
                      child: Container(
                          padding: const EdgeInsets.only(left: 12.0, top: 6.0),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                          ),
                          child: Center(
                              child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.title,
                                  style: const TextStyle(
                                    fontFamily: "AppFonts.sansProSemiBold",
                                    fontSize: 13)
                                  ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2.0),
                                    child: Icon(Icons.notifications,
                                        size: 10, color: AppColors.darkGoldText),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 2.0),
                                      child: SizedBox(
                                        height:
                                            32, 
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.vertical,
                                          child: Text(
                                            n.message,
                                            style: const TextStyle(
                                                fontFamily: "SansSerifPro",
                                                fontSize: 10,
                                                color: AppColors.darkGoldText),
                                            softWrap: true,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ))))
                ],
              ),
            ),
          );

      List<Widget> buildSection(
          String sectionTitle, List<NotificationItem> items) {
        if (items.isEmpty) return [sectionHeader(sectionTitle, italic: true)];
        final grouped = groupNotifications(items);
        final sortedKeys = grouped.keys.toList()
          ..sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));
        return [sectionHeader(sectionTitle, italic: true)] +
            [
              for (final dateKey in sortedKeys) ...[
                dateHeader(DateTime.parse(dateKey)),
                ...grouped[dateKey]!.map(notificationRow).toList(),
              ]
            ];
      }

      return ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const Divider(
            color: Colors.white,
            thickness: 1,
            indent: 20,
            endIndent: 60,
          ),
          ...buildSection('Upcoming', upcoming),
          const SizedBox(height: 12),
          const Divider(
            indent: 20,
            endIndent: 60,
            color: Colors.white,
            thickness: 1,
          ),
          ...buildSection('Past', past),
        ],
      );
    }

    // If user is signed in, stream notifications from Firestore
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('uid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        final List<NotificationItem> items = docs.map((d) {
          final data = d.data() as Map<String, dynamic>;
          final title = data['title'] ?? 'Notification';
          final message = data['message'] ?? '';
          final ts = data['createdAt'];
          DateTime dateTime;
          if (ts is Timestamp) {
            dateTime = ts.toDate();
          } else {
            dateTime = DateTime.now();
          }
          return NotificationItem(title: title, message: message, dateTime: dateTime);
        }).toList();

        final now = DateTime.now();
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
          if (list.isEmpty) return [Padding(padding: EdgeInsets.all(12), child: Text('No $title notifications', style: TextStyle(color: Colors.white)) )];
          final grouped = groupNotifications(list);
          final sortedKeys = grouped.keys.toList()..sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));
          final widgets = <Widget>[];
          widgets.add(Padding(padding: const EdgeInsets.only(left: 16, top: 12, bottom: 8), child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 24))));
          for (final key in sortedKeys) {
            widgets.add(Padding(
                padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                child: Text(
                    DateFormat('EEEE, MMMM d').format(DateTime.parse(key)),
                    style: const TextStyle(color: AppColors.tanText, fontSize: 18))));

            final mapped = grouped[key]!.map((n) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
                  child: SizedBox(
                    height: 65,
                    child: Row(
                      children: [
                        Container(
                          height: 65,
                          width: 80,
                          decoration:
                              const BoxDecoration(color: Colors.white),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                    DateFormat('MMM d')
                                        .format(n.dateTime),
                                    style: const TextStyle(
                                        fontFamily:
                                            "AppFonts.sansProSemiBold",
                                        fontSize: 11,
                                        color: AppColors.darkGoldText)),
                                Text(
                                    DateFormat('hh:mm a')
                                        .format(n.dateTime),
                                    style: const TextStyle(
                                        fontFamily: "SansSerifPro",
                                        fontSize: 10,
                                        color: AppColors.darkGoldText)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 1),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.only(
                                left: 12.0, top: 6.0),
                            decoration:
                                const BoxDecoration(color: Colors.white),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(n.title,
                                    style: const TextStyle(
                                        fontFamily:
                                            "AppFonts.sansProSemiBold",
                                        fontSize: 13)),
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
                                          height: 32,
                                          child: SingleChildScrollView(
                                              scrollDirection:
                                                  Axis.vertical,
                                              child: Text(n.message,
                                                  style: const TextStyle(
                                                      fontFamily:
                                                          "SansSerifPro",
                                                      fontSize: 10,
                                                      color: AppColors
                                                          .darkGoldText)))),
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

        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const Divider(color: Colors.white, thickness: 1, indent: 20, endIndent: 60),
            ...sectionWidgets('Upcoming', upcoming),
            const SizedBox(height: 12),
            const Divider(indent: 20, endIndent: 60, color: Colors.white, thickness: 1),
            ...sectionWidgets('Past', past),
          ],
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
                child: Text(
                  _screenBool ? "Notifications" : "Calendar",
                  style: const TextStyle(
                      color: AppColors.tanText,
                      fontWeight: FontWeight.w600,
                      fontSize: 26),
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
                        child: Text(_name.isEmpty ? "Hi!" : "Hi $_name!",
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w300,
                                color: Colors.white))),
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Text(dateFormatter(_focusedMonth, _focusedYear),
                          style: const TextStyle(
                            fontFamily: "AppFonts.sansProSemiBold",
                            fontSize: 20,
                            color: AppColors.tanText,
                          )),
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
