import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/common/widgets/cal_poly_menu_bar.dart';
import 'package:flutter/material.dart';
import 'package:ccce_application/common/collections/sponsor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ccce_application/services/error_logger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';




class Asc2026SponsorsDirectory extends StatefulWidget {
  // final GlobalKey<ScaffoldState> scaffoldKey;
  const Asc2026SponsorsDirectory({super.key});

  final String title = "Directory";
  @override
  State<Asc2026SponsorsDirectory> createState() => _Asc2026SponsorsDirectoryState();
}

class _Asc2026SponsorsDirectoryState extends State<Asc2026SponsorsDirectory> {

  // final String sloName = "SLO";
  // final String greenName = "Green";
  // final String goldName = "Gold";
  // final String mustangName = "Mustang";
  Future<List<Sponsor>> fetchDataFromFirestore() async {
    List<Sponsor> sponsorList = [];

    try {
      // Get a reference to the Firestore database
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      ErrorLogger.logInfo('SponsorsDirectory', 'Fetching sponsors from Firestore');
      // Query the "companies" collection
      QuerySnapshot querySnapshot = await firestore.collection('sponsors').get();
      ErrorLogger.logInfo('SponsorsDirectory', 'Fetched ${querySnapshot.size} sponsors from Firestore');
      print('Docs count: ${querySnapshot.docs.length}');
      print('Size: ${querySnapshot.size}');
      print('Is empty: ${querySnapshot.docs.isEmpty}');

      // Iterate through the documents in the query snapshot
      querySnapshot.docs.forEach((doc) {
        // Convert each document to a Map and add it to the list
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        Map<String, String> sponsorData = {};
        data.forEach((key, value) {
          sponsorData['id'] = doc.id;
          sponsorData['name'] = data['name'] ?? '';
          sponsorData['logo'] = data['logo'] ?? '';
          sponsorData['website'] = data['website'] ?? '';
          sponsorData['sponsorLevel'] = data['sponsorLevel'] ?? '';
          // Convert each value to String and add it to sponsorData
          sponsorData[key] = value.toString();
        });
        // bool administration = false;
        // if (sponsorData['administration'] != null) {
        //   administration =
        //       sponsorData['administration']!.toLowerCase().contains("true");
        // }
        Sponsor newSponsor = Sponsor(
            id: sponsorData['id']!,
            name: sponsorData['name']!,
            logo: sponsorData['logo']!,
            website: sponsorData['website']!,
            sponsorLevel: sponsorData['sponsorLevel']!,
            );
        sponsorList.add(newSponsor);
      });
    } catch (e) {
      // Handle any errors that occur
      ErrorLogger.logError('SponsorsDirectory', 'Error fetching data', error: e);
    }

    return sponsorList;
  }

  bool _isTextEntered = false;

  static List<Sponsor> sponsorList = [];
  static List<Sponsor> filteredSponsors = [];
  @override
  void initState() {
    super.initState();
    
    fetchDataFromFirestore().then((sponsorData) {
      setState(() {
        sponsorList = sponsorData;
        sponsorList.sort();
      });
    });

    // Fetch company data from a source (e.g., API call, database)
    // and populate the companies list
  }


  Map<String, bool> buttonStates = {
  'SLO': false,
  'Green': false,
  'Gold': false,
  'Mustang': false,
  };

  @override
  Widget build(BuildContext context) {
    OutlinedButton createButtonSorter(String txt, VoidCallback sortingFunction) {
      bool isActive = buttonStates[txt] ?? false;
      return OutlinedButton(
        onPressed: () {
          setState(() {
            sortingFunction(); 
            buttonStates[txt] = !isActive; // Flip the boolean
          });
        },
        style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero, // Rounded corners
            ),
            textStyle: const TextStyle(fontSize: 13),
            side: const BorderSide(
                color: Colors.black, width: 1), // Border color and width
            minimumSize: const Size(75, 25), // Minimum size constraint
            backgroundColor: !isActive ? Colors.transparent : AppColors.welcomeLightYellow),
        child: Text(txt,
            style: TextStyle(
                fontSize: 14, color: !isActive ? AppColors.welcomeLightYellow : AppColors.calPolyGreen,
                fontWeight: FontWeight.w600)),
      );
    }

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
        padding: const EdgeInsets.only(right: 16.0, left: 16.0, top: 16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              // child: CalPolyMenuBar(scaffoldKey: widget.scaffoldKey),
            ),
            Row(
              children: [
                Image.asset(
                  'assets/icons/default_company.png', // CHANGE THIS LATER TO COMPANY ICON
                  color: AppColors.welcomeLightYellow,
                  width: 26,
                  height: 28,
                ),
                const SizedBox(width: 6),
                const Text(
                  "ASC Sponsor Directory",
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
                          filteredSponsors.clear();

                          // Iterate through the original list of companies if text is entered
                          if (_isTextEntered) {
                            for (Sponsor sponsor in sponsorList) {
                              // Check if the company name starts with the entered text substring
                              String name = sponsor.name;
                              if (name
                                  .toLowerCase()
                                  .startsWith(text.toLowerCase())) {
                                // If it does, add the company to the filtered list
                                filteredSponsors.add(sponsor);
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
                        hintText: 'ASC Sponsor Directory',
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
                    createButtonSorter('Mustang', () => {}),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 6)),
                    createButtonSorter('Gold', () => {}),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 6)),
                    createButtonSorter('Green', () => {}),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 6)),
                    createButtonSorter('SLO', () => {}),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  final List<Sponsor> displayList =
                      _isTextEntered ? filteredSponsors : sponsorList;

                  // Split into admin and faculty
                  final List<Sponsor> sloList =
                      displayList.where((f) => f.sponsorLevel == 'SLO').toList();
                  final List<Sponsor> greenList =
                      displayList.where((f) => f.sponsorLevel == 'Green').toList();
                  final List<Sponsor> goldList =
                      displayList.where((f) => f.sponsorLevel == 'Gold').toList();
                  final List<Sponsor> mustangList =
                      displayList.where((f) => f.sponsorLevel == 'Mustang').toList();

                  // Combine with section headers
                  final List<Widget> sectionedList = [];



          _addSponsorSection("Mustang", mustangList, context, sectionedList);
          _addSponsorSection("Gold", goldList, context, sectionedList);
          _addSponsorSection("Green", greenList, context, sectionedList);
          _addSponsorSection("SLO", sloList, context, sectionedList);


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

  _addSponsorSection(
    String sponsorType,
    List<Sponsor> sponsorList,
    BuildContext context,
    List<Widget> sectionedList
  ){
    final bool shouldShow = ((buttonStates[sponsorType]!) || buttonStates.values.every((value) => !value));
    if (shouldShow){
        sectionedList.add(
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Text(
            "$sponsorType Sponsor",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: AppColors.welcomeLightYellow,
            ),
          ),
        ),
      );
    }
    else {
      null;
    }

    if (shouldShow) {
        if (sponsorList.isEmpty) {
          sectionedList.add(
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Text("None", style: TextStyle(color: Colors.grey)),
            ),
          );
        }
        else{
        sectionedList.addAll(
          sponsorList.map((f) => GestureDetector(
        onTap: () async {
          final url = f.website;
          if (url != null && url.isNotEmpty) {
            final uri = Uri.parse(url);
            try {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } catch (e) {
              if (!context.mounted) return;
              await Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Website link copied to clipboard')),
              );
            }
          }
        },
      child: SponsorItem(f),
    )).toList(),
          );
      }
      }
      else{
        const SizedBox(height: 10);
      }


  }
}
