import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/common/widgets/cal_poly_menu_bar.dart';
import 'package:flutter/material.dart';
import 'package:ccce_application/common/collections/member.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ccce_application/services/error_logger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';




class CMACMembersDirectory extends StatefulWidget {
  // final GlobalKey<ScaffoldState> scaffoldKey;
  // const CMACMembersDirectory({super.key});
  final GlobalKey<ScaffoldState> scaffoldKey;

	const CMACMembersDirectory({super.key, required this.scaffoldKey});

  final String title = "CMAC Members";
  @override
  State<CMACMembersDirectory> createState() => _CMACMembersDirectoryState();
}

class _CMACMembersDirectoryState extends State<CMACMembersDirectory> {


  Future<List<Member>> fetchDataFromFirestore() async {
    List<Member> memberList = [];

    try {
      // Get a reference to the Firestore database
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      ErrorLogger.logInfo('SponsorsDirectory', 'Fetching sponsors from Firestore');
      // Query the "companies" collection
      QuerySnapshot querySnapshot = await firestore.collection('cmacMembers').get();
      ErrorLogger.logInfo('SponsorsDirectory', 'Fetched ${querySnapshot.size} sponsors from Firestore');
      print('Docs count: ${querySnapshot.docs.length}');
      print('Size: ${querySnapshot.size}');
      print('Is empty: ${querySnapshot.docs.isEmpty}');

      // Iterate through the documents in the query snapshot
      querySnapshot.docs.forEach((doc) {
        // Convert each document to a Map and add it to the list
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        Map<String, String> memberData = {};
        data.forEach((key, value) {
          memberData['id'] = doc.id;
          memberData['name'] = data['name'] ?? '';
          memberData['logo'] = data['logo'] ?? '';
          memberData['website'] = data['website'] ?? '';
          memberData['level'] = data['sponsorLevel'] ?? '';
          // Convert each value to String and add it to memberData
          memberData[key] = value.toString();
        });
        // bool administration = false;
        // if (memberData['administration'] != null) {
        //   administration =
        //       memberData['administration']!.toLowerCase().contains("true");
        // }
        Member newMember = Member(
            id: memberData['id']!,
            name: memberData['name']!,
            logo: memberData['logo']!,
            website: memberData['website']!,
            level: memberData['level']!,
            );
        sponsorList.add(newMember);
      });
    } catch (e) {
      // Handle any errors that occur
      ErrorLogger.logError('SponsorsDirectory', 'Error fetching data', error: e);
    }

    return sponsorList;
  }

  bool _isTextEntered = false;

  static List<Member> sponsorList = [];
  static List<Member> filteredSponsors = [];
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
  'Green': false,
  'Gold': false,
  'Mustang': false,
  'Legacy': false,
  'Founder': false,
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
                  "CMAC Members Directory",
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
                            for (Member member in sponsorList) {
                              // Check if the company name starts with the entered text substring
                              String name = member.name;
                              if (name
                                  .toLowerCase()
                                  .startsWith(text.toLowerCase())) {
                                // If it does, add the company to the filtered list
                                filteredSponsors.add(member);
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
                        hintText: 'CMAC Member Directory',
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
                    createButtonSorter('Founder', () => {}),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 6)),
                    createButtonSorter('Legacy', () => {}),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 6)),
                    createButtonSorter('Mustang', () => {}),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 6)),
                    createButtonSorter('Gold', () => {}),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 6)),
                    createButtonSorter('Green', () => {}),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 6)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  final List<Member> displayList =
                      _isTextEntered ? filteredSponsors : sponsorList;

                  // Split into admin and faculty
                  final List<Member> founderList =
                      displayList.where((f) => f.level == 'Founder').toList();
                  final List<Member> legacyList =
                      displayList.where((f) => f.level == 'Legacy').toList();
                  final List<Member> greenList =
                      displayList.where((f) => f.level == 'Green').toList();
                  final List<Member> goldList =
                      displayList.where((f) => f.level == 'Gold').toList();
                  final List<Member> mustangList =
                      displayList.where((f) => f.level == 'Mustang').toList();

                  // Combine with section headers
                  final List<Widget> sectionedList = [];

          _addMemberSection("Founder", founderList, context, sectionedList);
          _addMemberSection("Legacy", legacyList, context, sectionedList);
          _addMemberSection("Mustang", mustangList, context, sectionedList);
          _addMemberSection("Gold", goldList, context, sectionedList);
          _addMemberSection("Green", greenList, context, sectionedList);


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

  _addMemberSection(
    String memberType,
    List<Member> memberList,
    BuildContext context,
    List<Widget> sectionedList
  ){
    final bool shouldShow = ((buttonStates[memberType]!) || buttonStates.values.every((value) => !value));
    if (shouldShow){
        sectionedList.add(
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Text(
            "$memberType Members",
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
      child: MemberItem(f),
    )).toList(),
          );
      }
      }
      else{
        const SizedBox(height: 10);
      }


  }
}
