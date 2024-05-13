import 'package:flutter/material.dart';
import 'package:ccce_application/src/screens/profile_screen.dart';
import 'package:ccce_application/src/screens/directory.dart';

import 'package:ccce_application/src/screens/home_screen.dart';

class RenderedPage extends StatefulWidget {
  const RenderedPage({Key? key}) : super(key: key);

  @override
  State<RenderedPage> createState() => _MyRenderedPageState();
}

class _MyRenderedPageState extends State<RenderedPage> {
  static const calPolyGreen = Color(0xFF003831);
  static const textGreen = Color(0xFF164734);
  static const tanColor = Color(0xFFcecca0);
  static const lighterTanColor = Color(0xFFfffded);
  static const appBackgroundColor = Color(0xFFE4E3D3);
  int _selectedIndex = 0;
  // static const TextStyle optionStyle =
  //     TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  static final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),
    Container(),
    Container(),
    Container(),
    Container(),
    const ProfileScreen(),
    const Directory(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    //Navigator.pop(context);
  }

  ListTile createListItem(String title) {
    return ListTile(
        tileColor: lighterTanColor,
        title: Text(title,
            textAlign: TextAlign.right,
            style: const TextStyle(color: textGreen, fontSize: 24.0)),
        selected: _selectedIndex == 0,
        onTap: () {
          _onItemTapped(0);
          Navigator.pop(context);
        });
  }

  @override
  Widget build(BuildContext context) {
    String getTitleText() {
      switch (_selectedIndex) {
        case 0:
          return "Home";
        case 1:
          return "Events";
        case 2:
          return "Club Info";
        case 3:
          return "Academics";
        case 4:
          return "Resources";
        case 5:
          return "Profile";
        case 6:
          return "Directory";
      }
      return "Missing Index";
    }

    return Scaffold(
        appBar: AppBar(
          backgroundColor: tanColor,
          elevation: 0.0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            getTitleText(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        body: _widgetOptions[_selectedIndex],
        backgroundColor: tanColor, //Still determining background color
        endDrawer: Container(
          width: MediaQuery.of(context).size.width,
          child: Drawer(
            backgroundColor: lighterTanColor,
            child: ListView(
              padding: const EdgeInsets.only(right: 24.0),
              children: [
                const SizedBox(
                  height: 80,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.all(0), // Add padding on the right
                      child: IconButton(
                        icon: const Icon(
                          Icons.dehaze,
                          color: textGreen,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
                createListItem("Home"),
                createListItem("Events"),
                createListItem("Club Info"),
                createListItem("Academics"),
                createListItem("Resources"),
                createListItem("Profile")
              ],
            ),
          ),
        ));
  }
}
