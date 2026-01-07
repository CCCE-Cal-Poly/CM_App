import 'package:ccce_application/common/collections/calevent.dart';
import 'package:ccce_application/common/providers/event_provider.dart';
import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/common/widgets/cal_poly_menu_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InfoSessionsScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const InfoSessionsScreen({super.key, required this.scaffoldKey});

  @override
  State<InfoSessionsScreen> createState() => _InfoSessionsState();
}

class _InfoSessionsState extends State<InfoSessionsScreen> {
  bool _isTextEntered = false;

  List<CalEvent> infoSessions = [];
  List<CalEvent> filteredInfoSessions = [];

  Map<String, bool> buttonStates = {
    'Chronological': false,
    'Hiring': false,
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
    final sorted = List<CalEvent>.from(sessions);
    
    // If both buttons active, prioritize chronological
    if (buttonStates['Chronological']! && buttonStates['Hiring']!) {
      sorted.sort((a, b) => a.startTime.compareTo(b.startTime));
    }
    // If only chronological
    else if (buttonStates['Chronological']!) {
      sorted.sort((a, b) => a.startTime.compareTo(b.startTime));
    }
    // If only hiring
    else if (buttonStates['Hiring']!) {
      sorted.sort((a, b) {
        final aHiring = a.isd?.openPositions?.isNotEmpty == true;
        final bHiring = b.isd?.openPositions?.isNotEmpty == true;
        if (aHiring && !bHiring) return -1;
        if (!aHiring && bHiring) return 1;
        return a.eventName.toLowerCase().compareTo(b.eventName.toLowerCase());
      });
    }
    else {
      sorted.sort((a, b) => a.eventName.toLowerCase().compareTo(b.eventName.toLowerCase()));
    }
    
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;

    OutlinedButton createButtonSorter(String txt, VoidCallback sortingFunction) {
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
            backgroundColor: !isActive ? Colors.transparent : AppColors.welcomeLightYellow),
        child: Text(txt,
            style: TextStyle(
                fontSize: 14,
                color: !isActive ? AppColors.welcomeLightYellow : AppColors.calPolyGreen,
                fontWeight: FontWeight.w600)),
      );
    }

    return Consumer<EventProvider>(builder: (context, eventProvider, child) {
            final allInfoSessions = eventProvider.isLoaded
          ? eventProvider.getEventsByType('infoSession')
          : <CalEvent>[];
      
      // Filter out info sessions with no meaningful data
      final validInfoSessions = allInfoSessions.where(_isValidInfoSession).toList();
      final infoSessions = _sortInfoSessions(validInfoSessions);

      return Scaffold(
        backgroundColor: AppColors.calPolyGreen,
        body: Padding(
          padding: const EdgeInsets.only(right: 20.0, left: 20.0, top: 20.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: CalPolyMenuBar(scaffoldKey: widget.scaffoldKey),
              ),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.info,
                      color: AppColors.welcomeLightYellow, size: 20),
                  SizedBox(width: 6),
                  Text(
                    "Info Sessions",
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
                            filteredInfoSessions.clear();

                            if (_isTextEntered) {
                              for (CalEvent infoSession in infoSessions) {
                                if (infoSession.eventName
                                    .toLowerCase()
                                    .startsWith(text.toLowerCase())) {
                                  filteredInfoSessions.add(infoSession);
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
                          hintText: 'Info Session Directory',
                          fillColor: Colors.white,
                          filled: true,
                        ),
                      ),
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2, left: 20, right: 20),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      createButtonSorter('Chronological', () {}),
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 6)),
                      createButtonSorter('Hiring', () {}),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: _isTextEntered
                      ? filteredInfoSessions.length
                      : infoSessions.length,
                  itemBuilder: (context, index) {
                    final List<CalEvent> displayList =
                        _isTextEntered ? filteredInfoSessions : infoSessions;
                    return GestureDetector(
                      onTap: () {
                        CalEvent infoSessionData = displayList[index];
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return InfoSessionPopUp(
                              infoSession: infoSessionData,
                              onClose: () =>
                                  Navigator.pop(context), 
                            );
                          },
                        );
                      },
                      child: InfoSessionItem(
                          displayList[index]),
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
