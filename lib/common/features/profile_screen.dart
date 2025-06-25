import 'package:ccce_application/common/features/sign_in.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

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

  Container createProfileAttributeContainer(TextFormField attributeField, Color color) {
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
      body: Stack(
        children: [
          // Top background
          Positioned.fill(
            top: 0,
            child: Container(color: calPolyGreen),
          ),

          // White background with rounded corners for text fields
          Positioned(
            top: MediaQuery.of(context).size.height / 6, // Adjust as needed
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: calPolyGreen,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(screenHeight * .2),
                  topRight: Radius.circular(screenHeight * .2),
                ),
              ),
              padding: EdgeInsets.all(screenHeight * .001),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(screenWidth * .08),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                        height: screenHeight * .075), // Adding space between the fields
                    Align(alignment: Alignment.center,
                    child: Text( 'My Profile', style: TextStyle(color: calPolyGold, fontSize: screenWidth * .06, fontFamily: 'Arial', fontWeight: FontWeight.bold), textAlign: TextAlign.center,)),
                    SizedBox(
                        height: screenHeight * .02),
                    createProfileAttributeContainer((createProfileAttributeField(
                        "First Name", _firstNameController)),Colors.white),
                    SizedBox(
                        height: screenHeight * .02), // Adding space between the fields
                    createProfileAttributeContainer(createProfileAttributeField(
                        "Last Name", _lastNameController),Colors.white),
                    SizedBox(
                        height: screenHeight * .02), // Adding space between the fields
                    createProfileAttributeContainer(createProfileAttributeField(
                        "School Year", _schoolYearController),Colors.white),
                    SizedBox(
                        height: screenHeight * .02), // Adding space between the fields
                    createProfileAttributeContainer(createProfileAttributeField(
                        "Company", _companyController),Colors.white),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: screenHeight * .013),
                      child:
                          editButtonBuild(), // Empty container when not in edit mode
                    ),
                    Container(
                        margin: EdgeInsets.symmetric(horizontal: screenWidth * .04),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              // Apply border to the bottom
                              color: Color(0xFFD9D9D9),
                              width: 1.0, // Adjust line thickness
                            ),
                          ),
                        )),
                    SizedBox(
                        height: screenHeight * .02), // Adding space between the fields
                    createProfileAttributeContainer(createProfileAttributeField(
                        "My Club Preferences", _schoolYearController), calPolyGold),
                    SizedBox(
                        height: screenHeight * .02), // Adding space between the fields
                    createProfileAttributeContainer(createProfileAttributeField(
                        "My Industry Preferences", _companyController),calPolyGold),
                  ],
                ),
              ),
            ),
          ),
          // Circle for profile pic
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
            padding: EdgeInsets.only(top: screenHeight * 0.055),
            child: Stack(
              children: [
                Container(
                  width: screenWidth * .45,
                  height: screenHeight * .20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: const Color.fromARGB(255, 112, 135, 121), width: 2),
                    color:
                        const Color.fromARGB(255, 112, 135, 121), // Change to your desired color
                  ),
                  padding: EdgeInsets.symmetric(vertical: screenHeight * .035),
                  // You can put an Image or Icon widget inside the container for profile picture
                  child: Icon(Icons.person,
                      size: screenHeight * .20, color: calPolyGreen),
                ),
                Positioned(
                    bottom: screenHeight * .011, // Adjust as needed
                    right: screenWidth *.022, // Adjust as needed
                    child: Container(
                        decoration: BoxDecoration(
                            color: calPolyGold, borderRadius: BorderRadius.circular(screenHeight * .008)),
                        child: Material(
                          borderRadius: BorderRadius.circular(100),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                // Toggle edit mode
                                if (_editMode == false) {
                                  _editMode = !_editMode;
                                }
                              });
                              // Add your onPressed function here
                              // For example, you can navigate to another screen
                              // or show a dialog to edit the profile
                            },
                            child: Ink(
                              width: screenWidth * .09,
                              height: screenHeight * .04,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: calPolyGold,
                              ),
                              child: Icon(
                                Icons.edit,
                                size: screenHeight * .03,
                                color: calPolyGreen,
                              ),
                            ),
                          ),
                        )))
              ],
            ),
          ),
          ),
        ],
      ),
    );
  }
}
