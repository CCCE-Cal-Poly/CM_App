import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/common/widgets/cal_poly_menu_bar.dart';
import 'package:flutter/material.dart';
import 'package:ccce_application/common/collections/company.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MemberDirectory extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const MemberDirectory({super.key, required this.scaffoldKey});

  final String title = "Directory";
  @override
  State<MemberDirectory> createState() => _MemberDirectoryState();
}

class _MemberDirectoryState extends State<MemberDirectory> {
  Future<List<Company>> fetchDataFromFirestore() async {
    List<Company> companies = [];

    try {
      // Get a reference to the Firestore database
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Query the "companies" collection
      QuerySnapshot querySnapshot =
          await firestore.collection('companies').get();

      // Iterate through the documents in the query snapshot
      querySnapshot.docs.forEach((doc) {
        // Convert each document to a Map and add it to the list
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        Map<String, String> companyData = {};
        data.forEach((key, value) {
          // Convert each value to String and add it to companyData
          companyData[key] = value.toString();
        });
        Company newComp = Company(
            companyData['name'],
            companyData['location'],
            companyData['about'],
            companyData['msg'],
            companyData['recruiterName'],
            companyData['recruiterTitle'],
            companyData['recruiterEmail'],
            companyData['logo']);
        companies.add(newComp);
      });
    } catch (e) {
      // Handle any errors that occur
      print('Error fetching data: $e');
    }

    return companies;
  }

  final TextEditingController _searchController = TextEditingController();
  bool _isTextEntered = false;

  static List<Company> companies = [];
  static List<Company> filteredCompanies = [];
  @override
  void initState() {
    super.initState();

    fetchDataFromFirestore().then((companiesData) {
      setState(() {
        companies = companiesData;
        companies.sort();
      });
    });

    // Fetch company data from a source (e.g., API call, database)
    // and populate the companies list
  }
  Map<String, bool> buttonStates = {
  'A-Z': true,
  'Admin': false,
  'Faculty': false,
  };

  @override
  Widget build(BuildContext context) {
    void sortAlphabetically() {
      setState(() {
        companies = companies.reversed.toList();
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
            padding: const EdgeInsets.symmetric(horizontal: 10),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero, // Rounded corners
            ),
            textStyle: const TextStyle(fontSize: 14),
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.group, color: AppColors.welcomeLightYellow, size: 24),
                SizedBox(width: 6),
                Text(
                  "Member Directory",
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
                          filteredCompanies.clear();

                          // Iterate through the original list of companies if text is entered
                          if (_isTextEntered) {
                            for (Company company in companies) {
                              // Check if the company name starts with the entered text substring
                              String name = company.name;
                              if (name
                                  .toLowerCase()
                                  .startsWith(text.toLowerCase())) {
                                // If it does, add the company to the filtered list
                                filteredCompanies.add(company);
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
                          borderSide: const BorderSide(
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
                        hintText: 'Member Directory',
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
                    createButtonSorter('A-Z', sortAlphabetically),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 6)),
                    createButtonSorter('Students', () => {}),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 6)),
                    createButtonSorter('Alumni', () => {}),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.vertical,
                itemCount:
                    _isTextEntered ? filteredCompanies.length : companies.length,
                itemBuilder: (context, index) {
                  final List<Company> displayList =
                      _isTextEntered ? filteredCompanies : companies;
                  return GestureDetector(
                    onTap: () {
                      Company companyData = displayList[index];
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return CompanyPopup(
                            company: companyData,
                            onClose: () =>
                                Navigator.pop(context), // Close popup on tap
                          );
                        },
                      );
                    },
                    child: CompanyItem(
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
