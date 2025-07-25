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

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;

    return Consumer<EventProvider>(builder: (context, eventProvider, child) {
      // Update infoSessions whenever the provider changes
      final infoSessions = eventProvider.isLoaded
          ? eventProvider.getEventsByType('infoSession')
          : <CalEvent>[];

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
                        //controller: _searchController,
                        onChanged: (text) {
                          setState(() {
                            _isTextEntered = text.isNotEmpty;
                            // Clear the previously filtered companies
                            filteredInfoSessions.clear();

                            // Iterate through the original list of companies if text is entered
                            if (_isTextEntered) {
                              for (CalEvent infoSession in infoSessions) {
                                // Check if the company name starts with the entered text substring
                                if (infoSession.eventName
                                    .toLowerCase()
                                    .startsWith(text.toLowerCase())) {
                                  // If it does, add the company to the filtered list
                                  filteredInfoSessions.add(infoSession);
                                }
                              }
                            }
                          });
                        },
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                          // contentPadding: EdgeInsets.all(2.0),
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
                          // border: OutlineInputBorder(
                          //   borderRadius: BorderRadius.circular(10.0),
                          // ),
                          fillColor: Colors.white,
                          filled: true,
                          // Add Container with colored background for the button
                        ),
                      ),
                    )
                  ],
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
                                  Navigator.pop(context), // Close popup on tap
                            );
                          },
                        );
                      },
                      child: InfoSessionItem(
                          displayList[index]), // Existing CompanyItem widget
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
