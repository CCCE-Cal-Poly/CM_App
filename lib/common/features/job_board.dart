import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/common/widgets/cal_poly_menu_bar.dart';
import 'package:ccce_application/common/widgets/debug_outline.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:ccce_application/common/collections/faculty.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JobBoard extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const JobBoard({super.key, required this.scaffoldKey});

  final String title = "Directory";
  @override
  State<JobBoard> createState() => _JobBoardState();
}

class _JobBoardState extends State<JobBoard> {
  

  final TextEditingController _searchController = TextEditingController();
  bool _isTextEntered = false;

  static List<Faculty> facultyList = [];
  static List<Faculty> filteredFaculty = [];
  @override
  void initState() {
    super.initState();

    fetchDataFromFirestore().then((facultyData) {
      setState(() {
        facultyList = facultyData;
        facultyList.sort();
      });
    });

    // Fetch company data from a source (e.g., API call, database)
    // and populate the companies list
  }


  Map<String, bool> buttonStates = {
  'Internship': false,
  'Full Time': false,
  'Part Time': false,
  };

  @override
  Widget build(BuildContext context) {
    void sortAlphabetically() {
      setState(() {
        facultyList = facultyList.reversed.toList();
      });
    }

    OutlinedButton createButtonSorter(String txt, VoidCallback sortingFunction) {
      bool isActive = buttonStates[txt] ?? false;
      return OutlinedButton(
        onPressed: () {
          setState(() {
            sortingFunction(); // Call your sorting function
            buttonStates[txt] = !isActive; // Flip the boolean
          });
        },
        style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero, // Rounded corners
            ),
            textStyle: const TextStyle(fontSize: 12),
            side: const BorderSide(
                color: Colors.black, width: 1), // Border color and width
            fixedSize: const Size(60, 30), // Set the button size
            minimumSize: const Size(80, 20), // Minimum size constraint
            backgroundColor: !isActive ? Colors.transparent : AppColors.welcomeLightYellow),
        child: Text(txt,
            style: TextStyle(
                fontSize: 14, color: !isActive ? AppColors.welcomeLightYellow : AppColors.calPolyGreen,
                fontWeight: FontWeight.w600)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.calPolyGreen,
      body: Padding(
        padding: const EdgeInsets.only(right: 16.0, left: 16.0, top: 16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: CalPolyMenuBar(scaffoldKey: widget.scaffoldKey),
            ),
            const Row(
              children: [
                Icon(Icons.share, color: AppColors.welcomeLightYellow
                ),
                SizedBox(width: 6),
                Text(
                  "Job Board",
                  style: TextStyle(
                    fontFamily: AppFonts.sansProSemiBold,
                    fontSize: 21,
                    color: AppColors.welcomeLightYellow,
                  ),
                ),
              ],
            ),
            Padding(
              padding:
                  const EdgeInsets.only(left: 16.0, top: 12.0, right: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      //controller: _searchController,
                      onChanged: (text) {
                        setState(() {
                          _isTextEntered = text.isNotEmpty;
                          // Clear the previously filtered companies
                          filteredFaculty.clear();

                          // Iterate through the original list of companies if text is entered
                          if (_isTextEntered) {
                            for (Faculty faculty in facultyList) {
                              // Check if the company name starts with the entered text substring
                              String name = faculty.fname + " " + faculty.lname;
                              if (name
                                  .toLowerCase()
                                  .startsWith(text.toLowerCase())) {
                                // If it does, add the company to the filtered list
                                filteredFaculty.add(faculty);
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
                        hintText: 'Job Board',
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
              padding: const EdgeInsets.only(top: 2, left: 20, right: 20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    createButtonSorter('Internship', sortAlphabetically),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 6)),
                    createButtonSorter('Full Time', () => {}),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 6)),
                    createButtonSorter('Part Time', () => {}),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  final List<Faculty> displayList =
                      _isTextEntered ? filteredFaculty : facultyList;

                  // Split into admin and faculty
                  final List<Faculty> adminList =
                      displayList.where((f) => f.administration).toList();
                  final List<Faculty> facultyOnlyList =
                      displayList.where((f) => !f.administration).toList();

                  // Combine with section headers
                  final List<Widget> sectionedList = [];

      // Full Time section
      (!(buttonStates['Part Time']!) || (buttonStates['Part Time']!&&buttonStates['Full Time']!)) ? (sectionedList.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Text(
            "Full Time",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: AppColors.welcomeLightYellow,
            ),
          ),
        ),
      )) : null;
      if (!(buttonStates['Part Time']!) || (buttonStates['Part Time']!&&buttonStates['Full Time']!)) {
        if (adminList.isEmpty) {
          sectionedList.add(
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Text("None", style: TextStyle(color: Colors.grey)),
            ),
          );
        }
        else{
        sectionedList.addAll(
          adminList.map((f) => GestureDetector(
            onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return FacultyPopUp(
              faculty: f, 
              onClose: () => Navigator.of(context).pop(),
              );
          }
        );
      },
      child: FacultyItem(f),
    )).toList(),
          );
      }
      }
      else{
        const SizedBox(height: 10);
      }

      // Part Time section

      (!(buttonStates['Full Time']!) || (buttonStates['Part Time']!&&buttonStates['Full Time']!)) ? (sectionedList.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Text(
            "Part Time",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: AppColors.welcomeLightYellow,
            ),
          ),
        ),
      )) : null;
      if (!(buttonStates['Full Time']!) || (buttonStates['Part Time']! && buttonStates['Full Time']!)){
        if (facultyOnlyList.isEmpty) {
        sectionedList.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Text("None", style: TextStyle(color: Colors.grey)),
          ),
        );
      } 
      else {
        sectionedList.addAll(
          facultyOnlyList.map((f) => GestureDetector(
            onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return FacultyPopUp(
              faculty: f, 
              onClose: () => Navigator.of(context).pop(),
              );
          },
        );
      },
      child: FacultyItem(f),
    )).toList(),
          );
      }
      }
      else{
        const SizedBox(height: 10);
      }

                  return ListView(
                    children: sectionedList,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<List<Faculty>> fetchDataFromFirestore() async {
    List<Faculty> facultyList = [];
    return facultyList;
  }
}