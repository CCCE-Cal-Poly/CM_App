import 'package:auto_size_text/auto_size_text.dart';
import 'package:ccce_application/common/features/my_info_sessions.dart';
import 'package:ccce_application/common/features/sign_in.dart';
import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/common/widgets/cal_poly_menu_bar.dart';
import 'package:ccce_application/common/widgets/debug_outline.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const ProfileScreen({super.key, required this.scaffoldKey});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final String title = 'CM Home';
  static const calPolyGreen = Color(0xFF003831);
  static const calPolyGold = Color(0xFFFFCC33);
  static const tanColor = Color(0xFFcecca0);
  //static const appBackgroundColor = Color(0xFFE4E3D3);
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _schoolYearController = TextEditingController();
  final _companyController = TextEditingController();
  static dynamic curUser;
  static dynamic curUserData;

  bool _editMode = false; // Indicates whether the page is in edit mode

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
      FirebaseFirestore.instance
          .collection('users')
          .doc(curUser.uid)
          .get()
          .then((snapshot) {
        if (snapshot.exists) {
          curUserData = snapshot.data() as Map<String, dynamic>;
          _firstNameController.text = curUserData['firstName'] ?? '';
          _lastNameController.text = curUserData['lastName'] ?? '';
          _schoolYearController.text = curUserData['schoolYear'] ?? '';
          _companyController.text = curUserData['company'] ?? '';
        }
      });
    }
  }

  Row editButtonBuild() {
    List<Widget> children = [
      ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: calPolyGreen),
        onPressed: () async {
          setState(() {
            _editMode = !_editMode;
          });
          // Retrieve values from form fields
          final firstName = _firstNameController.text;
          final lastName = _lastNameController.text;
          final schoolYear = _schoolYearController.text;
          final company = _companyController.text;

          // Get the user ID
          String? userID = curUser.uid;
          String? email = curUser.email;

          // Check if any field is empty
          if (firstName.isEmpty ||
              lastName.isEmpty ||
              schoolYear.isEmpty ||
              company.isEmpty) {
            // Show a popup (dialog)
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Error'),
                  content: const Text('Please fill out all fields.'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                      },
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
            return;
          }
          try {
            // Get a reference to the users collection
            final userCollection =
                FirebaseFirestore.instance.collection('users');

            // Create a new user document with the entered data
            // Merge: true creates new user if user doesnt exist, modifies if this user already existsLamk
            await userCollection.doc(userID).set({
              'email': email,
              'firstName': firstName,
              'lastName': lastName,
              'schoolYear': schoolYear,
              'company': company,
            }, SetOptions(merge: true));

            // Show a success message
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('User edited successfully!'),
            ));
          } catch (e) {
            // Handle errors
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Error creating user. Please try again later.'),
            ));
          }
        },
        child: const Text(
          'Submit',
          style: TextStyle(color: Colors.white),
        ),
      ),
      const SizedBox(width: 16), // Adding some space between buttons
      ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: calPolyGold),
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const SignIn()),
            (route) => false,
          );
        },
        child: const Text('Confirm', style: TextStyle(color: Colors.black)),
      ),
    ];

    return Row(
      children: [
        for (int i = 0; i < children.length; i++)
          if ((i != 0 && i != 1) || _editMode)
            children[i], // Hide first child if flag is true
      ],
    );
  }

  TextFormField createProfileAttributeField(
      String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      enabled: _editMode,
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
        labelText: label,
        border: InputBorder.none,
      ),
    );
  }

  Container createProfileAttributeContainer(
      TextFormField attributeField, Color color) {
    return Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: calPolyGreen),
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
                    padding:
                        EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
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
                        Divider(
                          color: Colors.white,
                          indent: screenWidth * 0.06,
                          endIndent: screenWidth * 0.06,
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        SizedBox(
                          height: screenHeight * 0.07,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: (screenHeight * 0.07) / 2,
                                backgroundImage: AssetImage(
                                    'assets/icons/default_profile.png'),
                              ),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: SizedBox(
                                  height: screenHeight * 0.07,
                                  child: const Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Flexible(
                                        child: AutoSizeText(
                                          "Clark Johnson Cleary Cleary",
                                          maxLines: 2,
                                          minFontSize: 7,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontFamily:
                                                  AppFonts.sansProSemiBold,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16),
                                        ),
                                      ),
                                      AutoSizeText(
                                          "lamkinlamkinlamkinlamkin@gmail.com",
                                          maxLines: 1,
                                          minFontSize: 7,
                                          style: TextStyle(
                                              color: AppColors.tanText,
                                              fontSize: 12,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor:
                                                  AppColors.tanText))
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkGoldText,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Scaffold(
                                  appBar: AppBar(
                                    title: const Text("My Info Sessions", style: TextStyle(fontFamily: AppFonts.sansProSemiBold, color: AppColors.welcomeLightYellow, fontWeight: FontWeight.w600)),
                                    backgroundColor: AppColors.calPolyGreen,
                                    foregroundColor: Colors.white,
                                  ),
                                  backgroundColor: AppColors.calPolyGreen,
                                  body: buildInfoSessionDisplay(context),
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            "My Info Sessions",
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      ],
                    ),
                  )
                ])));
  }
}
