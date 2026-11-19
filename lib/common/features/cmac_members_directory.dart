import 'package:auto_size_text/auto_size_text.dart';
import 'package:ccce_application/common/collections/calevent.dart';
import 'package:ccce_application/common/collections/member.dart';
import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/common/providers/event_provider.dart';
import 'package:ccce_application/common/widgets/resilient_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ccce_application/services/error_logger.dart';
import 'package:ccce_application/common/widgets/cal_poly_menu_bar.dart';

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

      final QuerySnapshot querySnapshot = await firestore
          .collection('allCompanies')
          .where('cmacData', isNull: false)
          .get();
      ErrorLogger.logInfo('CMAC Directory',
          'Fetched ${querySnapshot.size} cmac members from Firestore');
      for (final doc in querySnapshot.docs) {
        members.add(Member.fromDocument(doc));
      }
    } catch (e) {
      // Handle any errors that occur
      ErrorLogger.logError('CMACMemberDirectory', 'Error fetching data',
          error: e);
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
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: CalPolyMenuBar(scaffoldKey: widget.scaffoldKey),
            ),
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
                            .contains(_searchQuery) ||
                        (member.individualName
                                ?.toLowerCase()
                                .contains(_searchQuery) ??
                            false);
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
        (member) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: _CMACMemberCard(
            member: member,
            onTap: () {
              showDialog<void>(
                context: context,
                builder: (dialogContext) => CMACMemberDetailsPage(
                  member: member,
                  onClose: () => Navigator.of(dialogContext).pop(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CMACMemberCard extends StatelessWidget {
  final Member member;
  final VoidCallback onTap;

  const _CMACMemberCard({required this.member, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final founderName = member.individualName?.trim();
    final hasFounder = founderName != null && founderName.isNotEmpty;

    return Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: AppColors.calPolyGreen.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.lightGold.withValues(alpha: 0.7),
          width: 1,
        ),
      ),
      child: SizedBox(
        height: hasFounder ? 232 : 208,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              children: [
                if (founderName != null && founderName.isNotEmpty) ...[
                  const Text(
                    'FOUNDER',
                    style: TextStyle(
                      color: AppColors.darkGoldText,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 1),
                  AutoSizeText(
                    founderName,
                    maxLines: 1,
                    minFontSize: 10,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.calPolyGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                Expanded(
                  child: Center(
                    child: ResilientImage(
                      imageUrl: member.logo,
                      placeholderAsset: 'assets/icons/default_company.png',
                      fit: BoxFit.contain,
                      height: 118,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: AutoSizeText(
                    member.name,
                    maxLines: 2,
                    minFontSize: 11,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.calPolyGreen,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//  child: ListTile(
//           contentPadding:
//               const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           leading: Container(
//             width: screenWidth * 0.11,
//             height: screenWidth * 0.11,
//             decoration: const BoxDecoration(
//               shape: BoxShape.circle,
//               border: Border.fromBorderSide(
//                 BorderSide(color: Colors.black, width: 0.5),
//               ),
//             ),
//             child: Padding(
//               padding: const EdgeInsets.all(1),
//               child: ResilientCircleImage(
//                 imageUrl: member.logo,
//                 placeholderAsset: 'assets/icons/default_company.png',
//                 size: screenWidth * 0.11,
//               ),
//             ),
//           ),
//           title: AutoSizeText(
//             member.name,
//             style: const TextStyle(
//               color: Colors.black,
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//             ),
//             minFontSize: 12,
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//           ),
//           subtitle: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   const Icon(
//                     Icons.star,
//                     color: AppColors.lightGold,
//                     size: 16,
//                   ),
//                   const SizedBox(width: 2),
//                   Flexible(
//                     child: AutoSizeText(
//                       member.level ?? 'No Level',
//                       style: const TextStyle(
//                         color: AppColors.lightGold,
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                       ),
//                       minFontSize: 8,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ],
//               ),
//               if (founderName != null && founderName.isNotEmpty)
//                 Padding(
//                   padding: const EdgeInsets.only(top: 2),
//                   child: AutoSizeText(
//                     'Founder: $founderName',
//                     style: const TextStyle(
//                       color: AppColors.darkGoldText,
//                       fontSize: 13,
//                     ),
//                     minFontSize: 8,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//             ],
//           ),
//         ),

class CMACMemberDetailsPage extends StatelessWidget {
  final Member member;
  final VoidCallback onClose;

  const CMACMemberDetailsPage({
    super.key,
    required this.member,
    required this.onClose,
  });

  String _normalizedName(String value) => value.trim().toLowerCase();

  List<CalEvent> _upcomingInfoSessions(List<CalEvent> events) {
    final now = DateTime.now();
    final memberId = member.id?.toString();
    return events.where((event) {
      if (event.eventType != 'infoSession' || !event.startTime.isAfter(now)) {
        return false;
      }
      final matchesId = memberId != null &&
          memberId.isNotEmpty &&
          event.companyId == memberId;
      return matchesId ||
          _normalizedName(event.eventName) == _normalizedName(member.name);
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  Uri? _websiteUri(String? website) {
    final value = website?.trim();
    if (value == null || value.isEmpty || value == 'No Website') return null;
    final parsed = Uri.tryParse(value);
    if (parsed == null) return null;
    if (parsed.hasScheme) return parsed;
    return Uri.tryParse('https://$value');
  }

  Future<void> _openWebsite(BuildContext context, Uri uri) async {
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open company website')),
        );
      }
    } catch (error) {
      ErrorLogger.logError('CMACMemberDetailsPage', 'Unable to open website',
          error: error);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open company website')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final websiteUri = _websiteUri(member.website);
    final founderName = member.individualName?.trim();
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: AppColors.calPolyGreen,
      body: SafeArea(
        child: ListView(
          children: [
            Center(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.zero,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(screenHeight * 0.01),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Close CMAC member details',
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.black,
                            ),
                            onPressed: onClose,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(screenHeight * 0.01),
                      child: ResilientImage(
                        imageUrl: member.logo,
                        placeholderAsset: 'assets/icons/default_company.png',
                        height: screenHeight * 0.12,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          AutoSizeText(
                            member.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                            minFontSize: 12,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'CMAC Level: ${member.level ?? 'No Level'}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.darkGoldText,
                            ),
                          ),
                          if (founderName != null &&
                              founderName.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Founder: $founderName',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.darkGoldText,
                              ),
                            ),
                          ],
                          if (websiteUri != null) ...[
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => _openWebsite(context, websiteUri),
                              child: Text(
                                member.website!.trim(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              color: AppColors.calPolyGreen,
              padding: const EdgeInsets.all(16),
              child: Consumer<EventProvider>(
                builder: (context, eventProvider, child) {
                  final sessions = eventProvider.isLoaded
                      ? _upcomingInfoSessions(eventProvider.allEvents)
                      : <CalEvent>[];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Upcoming Info Sessions',
                          style: TextStyle(
                            color: AppColors.lightGold,
                            fontSize: 22,
                            fontWeight: FontWeight.w400,
                            fontFamily: AppFonts.sansProSemiBold,
                          ),
                        ),
                      ),
                      const Divider(color: Colors.white, thickness: 1.1),
                      if (!eventProvider.isLoaded)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.welcomeLightYellow,
                            ),
                          ),
                        )
                      else if (sessions.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No upcoming info sessions scheduled.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      else
                        ...sessions.map(
                          (session) => _CMACInfoSessionCard(
                            session: session,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => InfoSessionPopUp(
                                    infoSession: session,
                                    onClose: () => Navigator.of(context).pop(),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
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

// Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             border: Border.all(color: Colors.transparent),
//             borderRadius: BorderRadius.zero,
//           ),
//           child: Padding(
//             padding: EdgeInsets.symmetric(
//                 vertical: screenHeight * .005, horizontal: screenWidth * 0.01),
//             child: Center(
//               child: memberLogoImage(member.logo, context),
//             ),
//           ),
//         ),

class _CMACInfoSessionCard extends StatelessWidget {
  final CalEvent session;
  final VoidCallback onTap;

  const _CMACInfoSessionCard({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: (screenHeight * 0.09).clamp(68.0, 88.0),
            child: Row(
              children: [
                SizedBox(
                  width: 112,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('MMM d').format(session.startTime),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: AppFonts.sansProSemiBold,
                            fontSize: 14,
                            color: AppColors.darkGoldText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${DateFormat('h:mm a').format(session.startTime)} - '
                          '${DateFormat('h:mm a').format(session.endTime)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.darkGoldText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(width: 1, color: AppColors.lightGold),
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AutoSizeText(
                          session.eventName,
                          maxLines: 1,
                          minFontSize: 10,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: AppFonts.sansProSemiBold,
                            fontSize: 14,
                            color: AppColors.calPolyGreen,
                          ),
                        ),
                        if (session.eventLocation.trim().isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 12,
                                color: AppColors.darkGoldText,
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: AutoSizeText(
                                  session.eventLocation,
                                  maxLines: 1,
                                  minFontSize: 8,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.darkGoldText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(
                    Icons.chevron_right,
                    color: AppColors.calPolyGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
