import 'package:ccce_application/common/collections/calevent.dart';
import 'package:ccce_application/common/providers/event_provider.dart';
import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/common/widgets/cal_poly_menu_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Asc2026Agenda extends StatefulWidget {
  const Asc2026Agenda({super.key});

  @override
  State<Asc2026Agenda> createState() => _Asc2026AgendaState();
}

class _Asc2026AgendaState extends State<Asc2026Agenda> {
  bool _isTextEntered = false;

  List<CalEvent> ascEvents = [];
  List<CalEvent> filteredAscEvents = [];

  Map<String, bool> buttonStates = {
    'Chronological': false,
    'Hiring': false,
    'Future': false,
  };

  @override
  void initState() {
    super.initState();
  }

  bool _isValidInfoSession(CalEvent event) {
    if (event.eventName.isEmpty || event.eventName.trim().isEmpty) {
      return false;
    }
    return true;
  }

  List<CalEvent> _sortInfoSessions(List<CalEvent> sessions) {
    var sorted = List<CalEvent>.from(sessions);

    // Filter for future events if that button is active
    if (buttonStates['Future']!) {
      final now = DateTime.now();
      sorted = sorted.where((event) => event.startTime.isAfter(now)).toList();
    }


    // Sort chronologically or alphabetically
    if (buttonStates['Chronological']!) {
      sorted.sort((a, b) => a.startTime.compareTo(b.startTime));
    } else {
      sorted.sort((a, b) =>
          a.eventName.toLowerCase().compareTo(b.eventName.toLowerCase()));
    }

    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;

    OutlinedButton createButtonSorter(
        String txt, VoidCallback sortingFunction) {
      bool isActive = buttonStates[txt] ?? false;
      return OutlinedButton(
        onPressed: () {
          setState(() {
            sortingFunction();
            buttonStates[txt] = !isActive;
          });
        },
        style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            textStyle: const TextStyle(fontSize: 13),
            side: const BorderSide(color: Colors.black, width: 1),
            minimumSize: const Size(75, 25),
            backgroundColor:
                !isActive ? Colors.transparent : AppColors.welcomeLightYellow),
        child: Text(txt,
            style: TextStyle(
                fontSize: 14,
                color: !isActive
                    ? AppColors.welcomeLightYellow
                    : AppColors.calPolyGreen,
                fontWeight: FontWeight.w600)),
      );
    }

    return Consumer<EventProvider>(builder: (context, eventProvider, child) {
      final allASCEvents = eventProvider.isLoaded
          ? eventProvider.getEventsByType('asc2026')
          : <CalEvent>[];

      // Filter out info sessions with no meaningful data
      // final validInfoSessions =
      //     allInfoSessions.where(_isValidInfoSession).toList();
      final ascEvents = _sortInfoSessions(allASCEvents);

      return Scaffold(
        backgroundColor: AppColors.calPolyGreen,
        appBar: AppBar(
          backgroundColor: AppColors.calPolyGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.only(right: 20.0, left: 20.0, top: 20.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                // child: CalPolyMenuBar(scaffoldKey: widget.scaffoldKey),
              ),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.info,
                      color: AppColors.welcomeLightYellow, size: 20),
                  SizedBox(width: 6),
                  Text(
                    "Events",
                    style: TextStyle(
                      fontFamily: 'SansSerifProSemiBold',
                      fontSize: 21,
                      color: AppColors.welcomeLightYellow,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.all(screenHeight * 0.015),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (text) {
                          setState(() {
                            _isTextEntered = text.isNotEmpty;
                            filteredAscEvents.clear();

                            if (_isTextEntered) {
                              for (CalEvent ascEvent in ascEvents) {
                                if (ascEvent.eventName
                                    .toLowerCase()
                                    .startsWith(text.toLowerCase())) {
                                  filteredAscEvents.add(ascEvent);
                                }
                              }
                            }
                          });
                        },
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(
                              color: Colors.black,
                              width: 2.0,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(
                              color: Colors.black,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(
                              color: Colors.black,
                            ),
                          ),
                          hintText: 'ASC 2026 Agenda',
                          fillColor: Colors.white,
                          filled: true,
                        ),
                      ),
                    )
                  ],
                ),
              ),
              // Padding(
              //   padding: const EdgeInsets.only(top: 2, left: 12, right: 12),
              //   child: SingleChildScrollView(
              //     scrollDirection: Axis.horizontal,
              //     child: Row(
              //       children: [
              //         createButtonSorter('Chronological', () {}),
              //         const Padding(
              //             padding: EdgeInsets.symmetric(horizontal: 6)),
              //         createButtonSorter('Hiring', () {}),
              //         const Padding(
              //             padding: EdgeInsets.symmetric(horizontal: 6)),
              //         createButtonSorter('Future', () {}),
              //       ],
              //     ),
              //   ),
              // ),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: _isTextEntered
                      ? filteredAscEvents.length
                      : ascEvents.length,
                  itemBuilder: (context, index) {
                    final List<CalEvent> displayList =
                        _isTextEntered ? filteredAscEvents : ascEvents;
                    return GestureDetector(
                      onTap: () {
                        CalEvent ascEventData = displayList[index];
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return ascEventPopUp(
                              ascEvent: ascEventData,
                              onClose: () => Navigator.pop(context),
                            );
                          },
                        );
                      },
                      child: AscEventItem(displayList[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
