import 'package:ccce_application/common/features/job_board.dart';
import 'package:flutter/material.dart';
// Import your feature files
import 'package:ccce_application/common/features/faculty_directory.dart';
import 'package:ccce_application/common/features/profile_screen.dart';
import 'package:ccce_application/common/features/member_directory.dart';
import 'package:ccce_application/common/features/info_sessions_screen.dart';
import 'package:ccce_application/common/features/club_directory.dart';
import 'package:ccce_application/common/features/home_screen.dart';
import 'package:ccce_application/common/widgets/debug_outline.dart';

class RenderedPage extends StatefulWidget {
  const RenderedPage({Key? key}) : super(key: key);

  @override
  _MyRenderedPageState createState() => _MyRenderedPageState();
}

class _MyRenderedPageState extends State<RenderedPage> {
  static const standardGreen = Color(0xFF164734);
  static const tanColor = Color.fromARGB(255, 69, 68, 36);
  static const lighterTanColor = Color(0xFFfffded);
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late final List<Widget Function()> _pageBuilders;
  late final List<Widget?> _pages;

  @override
  void initState() {
    super.initState();
    _pageBuilders = [
      () => HomeScreen(scaffoldKey: _scaffoldKey),
      () => MemberDirectory(scaffoldKey: _scaffoldKey),
      () => ClubDirectory(scaffoldKey: _scaffoldKey),
      () => FacultyDirectory(scaffoldKey: _scaffoldKey),
      () => InfoSessionsScreen(scaffoldKey: _scaffoldKey),
      () => JobBoard(scaffoldKey: _scaffoldKey),
      () => ProfileScreen(scaffoldKey: _scaffoldKey),
    ];
    _pages = List<Widget?>.filled(_pageBuilders.length, null);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  ListTile createListItem(String title, int index) {
    return ListTile(
        tileColor: lighterTanColor,
        title: Text(title,
            textAlign: TextAlign.right,
            style: const TextStyle(
                fontFamily: "SansSerifProSemiBold",
                color: standardGreen,
                fontSize: 24.0)),
        onTap: () {
          _onItemTapped(index);
          Navigator.pop(context);
        });
  }

  @override
  Widget build(BuildContext context) {
    // Build the selected page if it hasn't been built yet
    if (_pages[_selectedIndex] == null) {
      _pages[_selectedIndex] = _pageBuilders[_selectedIndex]();
    }
    return Scaffold(
      key: _scaffoldKey, // Assign the key to the Scaffold
      body: LayoutBuilder(
        // Use LayoutBuilder
        builder: (context, constraints) {
          return Stack(
            // Use Stack to overlay the button
            children: [
              // Position the main content (IndexedStack) below the AppBar
              IndexedStack(
                index: _selectedIndex,
                children: List.generate(
                  _pages.length,
                  (i) => _pages[i] ?? const SizedBox.shrink(),
                ),
              ),
            ],
          );
        },
      ),
      backgroundColor: tanColor,
      endDrawer: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: DebugOutline(
          child: Drawer(
            backgroundColor: lighterTanColor,
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.only(right: 24.0),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(0),
                        child: IconButton(
                          icon: const Icon(
                            Icons.menu,
                            color: standardGreen,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                  createListItem("Home", 0),
                  createListItem("Member Directory", 1),
                  createListItem("Club Directory", 2),
                  createListItem("Faculty Directory", 3),
                  createListItem("Info Sessions", 4),
                  createListItem("Job Board", 5),
                  createListItem("Profile", 6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
