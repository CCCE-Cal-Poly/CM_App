import 'package:auto_size_text/auto_size_text.dart';
import 'package:ccce_application/common/collections/calevent.dart';
import 'package:ccce_application/common/collections/member.dart';
import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/common/providers/app_state.dart';
import 'package:ccce_application/common/providers/user_provider.dart';
import 'package:ccce_application/common/widgets/resilient_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ccce_application/services/error_logger.dart';

// Fixed display order for member levels, top to bottom.
const List<String> kMemberLevelOrder = [
  'Founder',
  'Legacy',
  'Mustang',
  'Gold',
  'Green',
];

class CMACMemberDirectory extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const CMACMemberDirectory({super.key, required this.scaffoldKey});

  final String title = "Directory";
  @override
  State<CMACMemberDirectory> createState() => _CMACMemberDirectoryState();
}

class _CMACMemberDirectoryState extends State<CMACMemberDirectory> {
  String _searchQuery = '';
  bool _isLoading = true;
  List<Member> memberList = [];
  Map<String, bool> levelButtonStates = {};

  Future<List<Member>> fetchDataFromFirestore() async {
    final List<Member> members = [];

    try {
      // Get a reference to the Firestore database
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      ErrorLogger.logInfo('CMAC Directory', 'Fetching members from Firestore');

      final QuerySnapshot querySnapshot =
          await firestore.collection('cmacMembers').get();
      ErrorLogger.logInfo(
          'CMAC Directory', 'Fetched ${querySnapshot.size} members from Firestore');
      for (final doc in querySnapshot.docs) {
        members.add(Member.fromDocument(doc));
      }
    } catch (e) {
      // Handle any errors that occur
      ErrorLogger.logError('CMACMemberDirectory', 'Error fetching data', error: e);
    }

    return members;
  }

  @override
  void initState() {
    super.initState();

    fetchDataFromFirestore().then((memberData) {
      if (!mounted) return;

      memberData.sort();
      final presentLevels =
          memberData.map((member) => member.level.toString()).toSet();
      // Known levels first, in the fixed order; anything unexpected falls
      // in afterward so it's never silently dropped.
      final levels = [
        ...kMemberLevelOrder.where(presentLevels.contains),
        ...presentLevels
            .where((level) => !kMemberLevelOrder.contains(level))
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())),
      ];

      setState(() {
        memberList = memberData;
        levelButtonStates = {for (final level in levels) level: false};
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    OutlinedButton createLevelButton(String level) {
      final bool isActive = levelButtonStates[level] ?? false;
      return OutlinedButton(
        onPressed: () {
          setState(() {
            levelButtonStates[level] = !isActive;
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
            backgroundColor:
                !isActive ? Colors.transparent : AppColors.welcomeLightYellow),
        child: Text(level,
            style: TextStyle(
                fontSize: 14,
                color: !isActive
                    ? AppColors.welcomeLightYellow
                    : AppColors.calPolyGreen,
                fontWeight: FontWeight.w600)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.calPolyGreen,
      body: Padding(
        padding: const EdgeInsets.only(right: 16.0, left: 16.0, top: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Row(
              children: [
                Image.asset(
                  'assets/icons/default_company.png', // CHANGE THIS LATER TO CMAC ICON
                  color: AppColors.welcomeLightYellow,
                  width: 26,
                  height: 28,
                ),
                const SizedBox(width: 6),
                const Text(
                  "CMAC Member Directory",
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
                      onChanged: (text) {
                        setState(() {
                          _searchQuery = text.trim().toLowerCase();
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
                        hintText: 'Search members',
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
                  children: levelButtonStates.keys
                      .map(
                        (level) => Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: createLevelButton(level),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (_isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.welcomeLightYellow,
                      ),
                    );
                  }

                  final selectedLevels = levelButtonStates.entries
                      .where((entry) => entry.value)
                      .map((entry) => entry.key)
                      .toSet();

                  final displayList = memberList.where((member) {
                    final matchesSearch = _searchQuery.isEmpty ||
                        member.name
                            .toString()
                            .toLowerCase()
                            .contains(_searchQuery);
                    final matchesLevel = selectedLevels.isEmpty ||
                        selectedLevels.contains(member.level.toString());
                    return matchesSearch && matchesLevel;
                  }).toList();

                  final List<Widget> sectionedList = [];

                  for (final level in levelButtonStates.keys) {
                    final membersInLevel = displayList
                        .where((member) => member.level.toString() == level)
                        .toList();
                    _addLevelSection(
                      level,
                      membersInLevel,
                      context,
                      sectionedList,
                    );
                  }

                  if (sectionedList.isEmpty) {
                    sectionedList.add(
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No members match the selected filters.',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    );
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

  void _addLevelSection(
    String level,
    List<Member> members,
    BuildContext context,
    List<Widget> sectionedList,
  ) {
    if (members.isEmpty) return;

    sectionedList.add(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Text(
          level,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: AppColors.welcomeLightYellow,
          ),
        ),
      ),
    );

    sectionedList.addAll(
      members.map(
        (member) => GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return CMACMemberPopUp(
                  member: member,
                  onClose: () => Navigator.pop(context),
                );
              },
            );
          },
          child: MemberItem(member),
        ),
      ),
    );
  }
}

class CMACMemberPopUp extends StatefulWidget {
  final Member member;
  final VoidCallback onClose;

  const CMACMemberPopUp({
    required this.member,
    required this.onClose,
    Key? key,
  }) : super(key: key);

  @override
  _CMACMemberPopUpState createState() => _CMACMemberPopUpState();
}

class _CMACMemberPopUpState extends State<CMACMemberPopUp> {
  Future<void> _copyToClipboard(String label, String value) async {
    try {
      await Clipboard.setData(ClipboardData(text: value));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$label copied to clipboard')));
    } catch (e) {}
  }

  Future<void> _launchUriOrCopy(Uri uri, String fallbackLabel) async {
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await Clipboard.setData(ClipboardData(text: uri.toString()));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$fallbackLabel copied to clipboard')));
      }
    } catch (e) {
      try {
        await Clipboard.setData(ClipboardData(text: uri.toString()));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$fallbackLabel copied to clipboard')));
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: AppColors.calPolyGreen,
      body: ListView(
        children: [
          Stack(
            children: [
              Center(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          left: screenWidth * .02,
                          top: screenHeight * .012,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              height: screenHeight * .03,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.black,
                                ),
                                onPressed: widget.onClose,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(screenWidth * 0.015),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: screenHeight * 0.14,
                              height: screenHeight * 0.14,
                              child: ResilientImage(
                                imageUrl: widget.member.logo,
                                placeholderAsset:
                                    'assets/icons/default_company.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(screenHeight * 0.015),
                        child: Column(
                          children: [
                            SizedBox(
                              width: screenWidth * 0.7,
                              child: AutoSizeText(
                                widget.member.name.toString(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                                minFontSize: 16,
                                maxLines: 2,
                              ),
                            ),
                            SizedBox(height: screenHeight * .0015),
                            Text(
                              widget.member.level.toString(),
                              style: const TextStyle(
                                  color: Colors.black87, fontSize: 14),
                            ),
                            SizedBox(height: screenHeight * 0.006),
                            if (widget.member.indivualName != null &&
                                widget.member.indivualName!.isNotEmpty)
                              Text(
                                widget.member.indivualName!,
                                style: const TextStyle(
                                    color: Colors.black54, fontSize: 13),
                              ),
                            if (widget.member.website != null &&
                                widget.member.website.toString().isNotEmpty &&
                                widget.member.website.toString() !=
                                    'No Website')
                              InkWell(
                                onTap: () {
                                  final uri = Uri.tryParse(
                                      widget.member.website.toString());
                                  if (uri != null) {
                                    _launchUriOrCopy(uri, 'Website');
                                  }
                                },
                                onLongPress: () => _copyToClipboard(
                                    'Website', widget.member.website.toString()),
                                child: Text(
                                  widget.member.website.toString(),
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}