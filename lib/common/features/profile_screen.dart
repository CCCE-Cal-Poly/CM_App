import 'package:auto_size_text/auto_size_text.dart';
import 'package:ccce_application/common/features/my_info_sessions.dart';
import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/common/widgets/cal_poly_menu_bar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:ccce_application/common/providers/user_provider.dart';
import 'package:ccce_application/common/collections/user_data.dart';
import 'package:ccce_application/common/features/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const ProfileScreen({super.key, required this.scaffoldKey});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final String title = 'CM Home';
  String firstName = '';
  String lastName = '';
  String schoolYear = '';
  String company = '';

  static dynamic curUser;
  static dynamic curUserData;

  @override
  void initState() {
    super.initState();
    // Load user data when the widget initializes
    loadUserData();
  }

  void loadUserData() {
    // Load user data and update the text controllers
    curUser = FirebaseAuth.instance.currentUser;
    if (curUser != null) {
      // Load user profile via UserProvider
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Provider.of<UserProvider>(context, listen: false)
              .loadUserProfile(curUser.uid);
        }
      });

      FirebaseFirestore.instance
          .collection('users')
          .doc(curUser.uid)
          .get()
          .then((snapshot) {
        if (mounted && snapshot.exists) {
          curUserData = snapshot.data() as Map<String, dynamic>;
          firstName = curUserData['firstName'] ?? '';
          lastName = curUserData['lastName'] ?? '';
          schoolYear = curUserData['schoolYear'] ?? '';
          company = curUserData['company'] ?? '';
        }
      });
    }
  }

  Container createProfileAttributeContainer(
      TextFormField attributeField, Color color) {
    return Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: AppColors.calPolyGreen),
        ),
        child: attributeField);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: AppColors.calPolyGreen,
      body: Padding(
        padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20),
        child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CalPolyMenuBar(scaffoldKey: widget.scaffoldKey),
              SizedBox(height: screenHeight * 0.04),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "My Profile",
                          style: TextStyle(
                            color: AppColors.tanText,
                            fontFamily: "AppFonts.sansProSemiBold",
                            fontSize: 24,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                      ])),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(children: [
                    Divider(
                      color: Colors.white,
                      indent: screenWidth * 0.03,
                      endIndent: screenWidth * 0.03,
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    SizedBox(
                      height: screenHeight * 0.07,
                      child: Row(
                        children: [
                          Consumer<UserProvider>(
                            builder: (context, userProvider, child) {
                              UserData? userData = userProvider.user;
                              User? currentUser =
                                  FirebaseAuth.instance.currentUser;

                              ImageProvider profileImage;
                              if (userData?.profilePictureUrl != null &&
                                  userData!.profilePictureUrl!.isNotEmpty) {
                                profileImage =
                                    NetworkImage(userData.profilePictureUrl!);
                              } else if (currentUser?.photoURL != null &&
                                  currentUser!.photoURL!.isNotEmpty) {
                                profileImage =
                                    NetworkImage(currentUser.photoURL!);
                              } else {
                                profileImage = const AssetImage(
                                    'assets/icons/default_profile.png');
                              }

                              return CircleAvatar(
                                radius: (screenHeight * 0.07) / 2,
                                backgroundImage: profileImage,
                                onBackgroundImageError: (_, __) {
                                  // Fallback to default image on error
                                },
                                child: userData?.profilePictureUrl != null ||
                                        currentUser?.photoURL != null
                                    ? null
                                    : null, // Let backgroundImage handle it
                              );
                            },
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: SizedBox(
                              height: screenHeight * 0.07,
                              child: Consumer<UserProvider>(
                                builder: (context, userProvider, child) {
                                  UserData? userData = userProvider.user;
                                  User? currentUser =
                                      FirebaseAuth.instance.currentUser;

                                  String displayName = '';
                                  if (userData != null &&
                                      userData.name.trim().isNotEmpty) {
                                    displayName = userData.name.trim();
                                  } else {
                                    if (currentUser?.email != null && currentUser!.email!.isNotEmpty) {
                                      displayName = currentUser.email!.split('@')[0];
                                    } else {
                                      displayName = '';
                                    }
                                  }

                                  String displayRole = '';
                                  if (userData != null) {
                                    switch (userData.role) {
                                      case UserRole.admin:
                                        displayRole = 'Admin';
                                        break;
                                      case UserRole.clubAdmin:
                                        displayRole = 'Club Admin';
                                        break;
                                      case UserRole.student:
                                        displayRole = 'Student';
                                        break;
                                      case UserRole.faculty:
                                        displayRole = 'Faculty';
                                        break;
                                    }
                                  } else {
                                    displayRole = '';
                                  }

                                  String displayEmail = '';
                                  if (userData != null &&
                                      userData.email.trim().isNotEmpty) {
                                    displayEmail = userData.email.trim();
                                  } else if (currentUser?.email != null &&
                                      currentUser!.email!.trim().isNotEmpty) {
                                    displayEmail = currentUser.email!.trim();
                                  } else {
                                    displayEmail = 'user@example.com';
                                  }

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Flexible(
                                        child: AutoSizeText(
                                          displayName,
                                          maxLines: 2,
                                          minFontSize: 7,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontFamily:
                                                  AppFonts.sansProSemiBold,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16),
                                        ),
                                      ),
                                      if (displayRole.isNotEmpty)
                                        AutoSizeText(displayRole,
                                            maxLines: 1,
                                            minFontSize: 7,
                                            style: const TextStyle(
                                              color: AppColors.tanText,
                                              fontSize: 12,
                                            )),
                                      AutoSizeText(displayEmail,
                                          maxLines: 1,
                                          minFontSize: 7,
                                          style: const TextStyle(
                                              color: AppColors.tanText,
                                              fontSize: 12,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor:
                                                  AppColors.tanText))
                                    ],
                                  );
                                },
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Consumer<UserProvider>(builder: (context, userProvider, child) {
                      final clubs = userProvider.clubsAdminOf;
                      if (clubs.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Clubs you administer', style: TextStyle(color: AppColors.tanText)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: clubs.map((c) => Chip(label: Text(c), backgroundColor: Colors.white)).toList(),
                            ),
                          ],
                        ),
                      );
                    }),
                    Center(
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.yellowButton,
                              shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero)),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const EditProfileScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "EDIT",
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.white,
                            height: 10,
                            indent: screenWidth * 0.03,
                            endIndent: screenWidth * 0.04,
                          ),
                        ),
                        Image.asset(
                          "assets/icons/hardhat.png",
                          height: screenWidth * 0.06,
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.white,
                            height: 10,
                            indent: screenWidth * 0.04,
                            endIndent: screenWidth * 0.03,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.yellowButton,
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero),
                        minimumSize:
                            const Size(double.infinity, 48), // Forces full width
                      ),
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Text("Log Out",
                              style: TextStyle(color: Colors.black)),
                          Icon(Icons.arrow_forward, color: Colors.black),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.yellowButton,
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero),
                        minimumSize:
                            const Size(double.infinity, 48), // Forces full width
                      ),
                      onPressed: () => print("hi"),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Text("About", style: TextStyle(color: Colors.black)),
                          Icon(Icons.arrow_forward, color: Colors.black),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.yellowButton,
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero),
                        minimumSize:
                            const Size(double.infinity, 48), // Forces full width
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            appBar: AppBar(
                              title: const Text("My Info Sessions",
                                  style: TextStyle(
                                      fontFamily: AppFonts.sansProSemiBold,
                                      color: AppColors.welcomeLightYellow,
                                      fontWeight: FontWeight.w600)),
                              backgroundColor: AppColors.calPolyGreen,
                              foregroundColor: Colors.white,
                            ),
                            backgroundColor: AppColors.calPolyGreen,
                            body: buildInfoSessionDisplay(context),
                          ),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Text("My Info Sessions",
                              style: TextStyle(color: Colors.black)),
                          Icon(Icons.arrow_forward, color: Colors.black),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.yellowButton,
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero),
                        minimumSize:
                            const Size(double.infinity, 48), // Forces full width
                      ),
                      onPressed: () => print("hi"),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Text("Club Preferences",
                              style: TextStyle(color: Colors.black)),
                          Icon(Icons.arrow_forward, color: Colors.black),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.yellowButton,
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero),
                        minimumSize:
                            const Size(double.infinity, 48), // Forces full width
                      ),
                      onPressed: () => print("hi"),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Text("Industry Preferences",
                              style: TextStyle(color: Colors.black)),
                          Icon(Icons.arrow_forward, color: Colors.black),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ]),
      ),
    );
  }
}
