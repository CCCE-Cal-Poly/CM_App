// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:ccce_application/common/collections/calevent.dart';
import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/common/providers/app_state.dart';
import 'package:ccce_application/common/providers/event_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

Widget buildInfoSessionList(context) {
  final now = DateTime.now();
  final checkedInEventIds =
      Provider.of<AppState>(context, listen: true).checkedInEventIds ??
          <String>{};
  final allEvents = Provider.of<EventProvider>(context, listen: true).allEvents;
  final allCheckedIn = allEvents
      .where((event) => checkedInEventIds.contains(event.id))
      .toList();
  print("Checked-in sessions available: ${allCheckedIn.map((e) => e.id)}");
  final checkedInInfoSessions =
      allCheckedIn.where((event) => event.eventType == "infoSession").toList();
  final List<CalEvent> future = checkedInInfoSessions
      .where((event) =>
          (event.startTime.isAfter(now)) ||
          (event.startTime.isAtSameMomentAs(now)))
      .toList();
  final pastDays = DateTime.now().subtract(const Duration(days: 100));
  List<CalEvent> past = checkedInInfoSessions
      .where((event) =>
          (event.startTime.isBefore(now)) && event.startTime.isAfter(pastDays))
      .toList();
  future.sort((a, b) => a.startTime.compareTo(b.startTime));
  past.sort((a, b) => b.startTime.compareTo(a.startTime));

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

  Map<String, List<CalEvent>> groupInfoSessions(List<CalEvent> infoSessions) {
    Map<String, List<CalEvent>> grouped = {};
    for (CalEvent event in infoSessions) {
      String dateKey = DateFormat('yyyy-MM-dd').format(event.startTime);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(event);
    }
    return grouped;
  }

  Widget infoSessionRow(CalEvent event) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
        child: SizedBox(
          height: 65,
          child: Row(
            children: [
              Container(
                  height: 65,
                  width: 80,
                  decoration: const BoxDecoration(
                    color: Colors.white, // Match event display
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('MMM d').format(event.startTime),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontFamily: "AppFonts.sansProSemiBold",
                              fontSize: 11,
                              color: AppColors.darkGoldText),
                        ),
                        Text(
                          DateFormat('hh:mm a').format(event.startTime),
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
                        color: Colors.white, // Match event display
                      ),
                      child: Center(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.eventName,
                              style: const TextStyle(
                                  fontFamily: "AppFonts.sansProSemiBold",
                                  fontSize: 13)),
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
                                        32, // fits 2 lines, adjust as needed
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.vertical,
                                      child: Text(
                                        event.eventLocation,
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

  List<Widget> buildSection(String sectionTitle, List<CalEvent> items) {
    if (items.isEmpty)
      return [sectionHeader("No " + sectionTitle + " Info Sessions.")];
    final grouped = groupInfoSessions(items);
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));
    return [sectionHeader(sectionTitle, italic: true)] +
        [
          for (final dateKey in sortedKeys) ...[
            dateHeader(DateTime.parse(dateKey)),
            ...grouped[dateKey]!.map(infoSessionRow).toList(),
          ]
        ];
  }

  return (future.isNotEmpty || past.isNotEmpty)
      ? ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            ...buildSection('Future', future),
            const SizedBox(height: 12),
            const Divider(
              indent: 20,
              endIndent: 60,
              color: Colors.white,
              thickness: 1, // You can adjust the thickness
            ),
            ...buildSection('Past', past),
          ],
        )
      : sectionHeader("You are not checked in to any info sessions.");
}

Widget buildInfoSessionDisplay(context) {
  return buildInfoSessionList(context);
}
