import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/common/widgets/cal_poly_menu_bar.dart';
import 'package:flutter/material.dart';
import 'package:ccce_application/common/collections/club.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      // Get a reference to the Firestore database
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Query the "companies" collection
      QuerySnapshot querySnapshot = await firestore.collection('clubs').get();

      // Iterate through the documents in the query snapshot
      querySnapshot.docs.forEach((doc) {
        // Convert each document to a Map and add it to the list
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        Map<String, String> clubData = {};
        data.forEach((key, value) {
          // Convert each value to String and add it to companyData
          clubData[key] = value.toString();
        });
        Club newClub = Club(
            clubData['Name'],
            clubData['About'],
            clubData['Email'],
            clubData['Acronym'],
            clubData['Instagram'],
            clubData['Logo']);
        clubs.add(newClub);
      });
    } catch (e) {
      // Handle any errors that occur
      print('Error fetching data: $e');
    }

    return clubs;
  }

  final TextEditingController _searchController = TextEditingController();
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
    void sortAlphabetically() {
      setState(() {
        clubs = clubs.reversed.toList();
      });
    }

    OutlinedButton createButtonSorter(String txt, VoidCallback sortingFunction,
        {bool colorFlag = true}) {
      bool _colorFlag = colorFlag;
      return OutlinedButton(
        onPressed: () {
          setState(() {
            sortingFunction(); // Call your sorting function
            print(_colorFlag);
            _colorFlag = !_colorFlag; // Flip the boolean
            print(_colorFlag);
          });
        },
        style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero, // Rounded corners
            ),
            textStyle: const TextStyle(fontSize: 14),
            side: const BorderSide(
                color: Colors.black, width: 1), // Border color and width
            fixedSize: const Size(60, 30), // Set the button size
            minimumSize: const Size(80, 20), // Minimum size constraint
            backgroundColor: _colorFlag ? Colors.transparent : Colors.black),
        child: Text(txt,
            style: TextStyle(
                fontSize: 14, color: _colorFlag ? Colors.black : Colors.white)),
      );
    }

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
              padding:
                  const EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0),
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    createButtonSorter('A-Z', sortAlphabetically,
                        colorFlag: false),
                    // Padding(padding: EdgeInsets.symmetric(horizontal: 6)),
                    // createButtonSorter('Sudents', () => {}),
                    // Padding(padding: EdgeInsets.symmetric(horizontal: 6)),
                    // createButtonSorter('Alumni', () => {}),
                    // Padding(padding: EdgeInsets.symmetric(horizontal: 6)),
                    // createButtonSorter('Industry', () => {}),
                    // Padding(padding: EdgeInsets.symmetric(horizontal: 6)),
                    // createButtonSorter('Jobs', () => {}),
                  ],
                ),
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
