import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/common/widgets/cal_poly_menu_bar.dart';
import 'package:flutter/material.dart';
import 'package:ccce_application/common/collections/club.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ccce_application/services/error_logger.dart';

class ClubDirectory extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const ClubDirectory({super.key, required this.scaffoldKey});

  final String title = "Club Directory";
  @override
  State<ClubDirectory> createState() => _ClubDirectoryState();
}

class _ClubDirectoryState extends State<ClubDirectory> {
  Future<List<Club>> fetchDataFromFirestore() async {
    List<Club> clubs = [];

      try {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    QuerySnapshot querySnapshot = await firestore.collection('clubs').get();

    querySnapshot.docs.forEach((doc) {
      Club newClub = Club.fromDocument(doc);
      clubs.add(newClub);
    });
  } catch (e) {
    ErrorLogger.logError('ClubDirectory', 'Error fetching data', error: e);
  }

    return clubs;
  }
  bool _isTextEntered = false;

  static List<Club> clubs = [];
  static List<Club> filteredClubs = [];
  @override
  void initState() {
    super.initState();

    fetchDataFromFirestore().then((clubData) {
      setState(() {
        clubs = clubData;
        clubs.sort();
      });
    });

    // Fetch company data from a source (e.g., API call, database)
    // and populate the companies list
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight=MediaQuery.of(context).size.height;

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
                Icon(Icons.hub, color: AppColors.welcomeLightYellow, size: 20),
                SizedBox(width: 6),
                Text(
                  "Club Directory",
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
                          filteredClubs.clear();

                          // Iterate through the original list of companies if text is entered
                          if (_isTextEntered) {
                            for (Club club in clubs) {
                              // Check if the company name starts with the entered text substring
                              if (club.name
                                  .toLowerCase()
                                  .startsWith(text.toLowerCase())) {
                                // If it does, add the company to the filtered list
                                filteredClubs.add(club);
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
                        hintText: 'Club Directory',
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
                itemCount: _isTextEntered ? filteredClubs.length : clubs.length,
                itemBuilder: (context, index) {
                  final List<Club> displayList =
                      _isTextEntered ? filteredClubs : clubs;
                  return GestureDetector(
                    onTap: () {
                      Club clubData = displayList[index];
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return ClubPopUp(
                            club: clubData,
                            onClose: () =>
                                Navigator.pop(context), // Close popup on tap
                          );
                        },
                      );
                    },
                    child: ClubItem(
                        displayList[index]), // Existing CompanyItem widget
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
