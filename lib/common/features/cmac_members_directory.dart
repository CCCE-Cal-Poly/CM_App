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
                        (member.indivualName
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
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CMACMemberDetailsPage(
                    member: member,
                    onClose: () => Navigator.of(context).pop(),
                  ),
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
    final founderName = member.indivualName?.trim();
    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      child: SizedBox(
        height: founderName != null && founderName.isNotEmpty ? 196 : 176,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
            child: Column(
              children: [
                if (founderName != null && founderName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: AutoSizeText(
                      founderName,
                      maxLines: 1,
                      minFontSize: 10,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.calPolyGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Expanded(
                  child: Center(
                    child: ResilientImage(
                      imageUrl: member.logo,
                      placeholderAsset: 'assets/icons/default_company.png',
                      fit: BoxFit.contain,
                      height: 126,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                AutoSizeText(
                  member.name,
                  maxLines: 1,
                  minFontSize: 10,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.calPolyGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
    final founderName = member.indivualName?.trim();

    return Scaffold(
      backgroundColor: AppColors.calPolyGreen,
      appBar: AppBar(
        backgroundColor: AppColors.calPolyGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back to CMAC member directory',
          onPressed: onClose,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(
          'CMAC Member',
          style: TextStyle(
            fontFamily: AppFonts.sansProSemiBold,
            color: AppColors.welcomeLightYellow,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Consumer<EventProvider>(
              builder: (context, eventProvider, child) {
                final sessions = eventProvider.isLoaded
                    ? _upcomingInfoSessions(eventProvider.allEvents)
                    : <CalEvent>[];
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    Container(
                      color: AppColors.calPolyGreen,
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      child: Column(
                        children: [
                          if (founderName != null && founderName.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                founderName,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.welcomeLightYellow,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          SizedBox(
                            height: 132,
                            child: ResilientImage(
                              imageUrl: member.logo,
                              placeholderAsset:
                                  'assets/icons/default_company.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 12),
                          AutoSizeText(
                            member.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            minFontSize: 17,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            member.level ?? '',
                            style: const TextStyle(
                              color: AppColors.welcomeLightYellow,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (websiteUri != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 16, 0, 4),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _openWebsite(context, websiteUri),
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Visit company website'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.welcomeLightYellow,
                              side: const BorderSide(
                                  color: AppColors.welcomeLightYellow),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Upcoming Info Sessions',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.welcomeLightYellow,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ),
                    if (!eventProvider.isLoaded)
                      const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.welcomeLightYellow,
                            ),
                          ))
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
        ),
      ),
    );
  }
}

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
