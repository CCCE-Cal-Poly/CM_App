import 'package:ccce_application/common/widgets/multi_select_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:ccce_application/common/providers/user_provider.dart';
import 'package:ccce_application/common/providers/club_provider.dart';
import 'package:ccce_application/common/theme/theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _roleController = TextEditingController();
  final _profilePictureUrlController = TextEditingController();

  List<String> selectedClubs = [];

  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  void _loadUserData() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = FirebaseAuth.instance.currentUser;

    if (userProvider.user != null) {
      // Load data from UserProvider
      final userData = userProvider.user!;
      final nameParts = userData.name.trim().split(' ');

      _firstNameController.text = nameParts.isNotEmpty ? nameParts.first : '';
      _lastNameController.text =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      _emailController.text = userData.email;
      _profilePictureUrlController.text = userData.profilePictureUrl ?? '';
    } else if (currentUser != null) {
      // Fallback to Firebase Auth data
      _emailController.text = currentUser.email ?? '';
      if (currentUser.displayName != null) {
        final nameParts = currentUser.displayName!.split(' ');
        _firstNameController.text = nameParts.isNotEmpty ? nameParts.first : '';
        _lastNameController.text =
            nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      }
      _profilePictureUrlController.text = currentUser.photoURL ?? '';
    }

    // Load additional fields from Firestore
    _loadAdditionalFields();
  }

  Future<void> _loadAdditionalFields() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (mounted) {
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            setState(() {
              _roleController.text = data['role'] ?? '';
              _isInitialized = true;
            });
          } else {
            // Document doesn't exist, still initialize
            setState(() {
              _isInitialized = true;
            });
          }
        }
      } catch (e) {
        print('Error loading additional fields: $e');
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    } else {
      // No current user, still initialize
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      // Prepare data for Firestore
      final userData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _roleController.text.trim(),
        'profilePictureUrl': _profilePictureUrlController.text.trim().isEmpty
            ? null
            : _profilePictureUrlController.text.trim(),
      };

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .set(userData, SetOptions(merge: true));

      // Reload user data in UserProvider
      if (mounted) {
        await Provider.of<UserProvider>(context, listen: false)
            .loadUserProfile(currentUser.uid);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: AppColors.calPolyGreen,
            ),
          );

          // Navigate back
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _roleController.dispose();
    _profilePictureUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

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
      body: _isInitialized
          ? SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      SizedBox(height: screenHeight * 0.02),

                      // Profile Icon with Edit Badge
                      Stack(
                        children: [
                          Consumer<UserProvider>(
                            builder: (context, userProvider, child) {
                              final currentUser =
                                  FirebaseAuth.instance.currentUser;
                              final userData = userProvider.user;

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
                                radius: 60,
                                backgroundColor: Colors.grey[400],
                                backgroundImage: profileImage,
                              );
                            },
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.yellowButton,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.black,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: screenHeight * 0.04),

                      // Title
                      const Text(
                        'My Profile',
                        style: TextStyle(
                          color: AppColors.tanText,
                          fontFamily: AppFonts.sansProSemiBold,
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.04),

                      // First Name
                      _buildTextField(
                        controller: _firstNameController,
                        label: 'First Name',
                        screenHeight: screenHeight,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'First name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Last Name
                      _buildTextField(
                        controller: _lastNameController,
                        label: 'Last Name',
                        screenHeight: screenHeight,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Last name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Email
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        screenHeight: screenHeight,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Role
                      _buildTextField(
                        controller: _roleController,
                        label: 'Role',
                        screenHeight: screenHeight,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Divider(
                        color: Colors.white,
                        indent: screenWidth * 0.04,
                        endIndent: screenWidth * 0.04,
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      Container(
                          decoration: BoxDecoration(
                              color: AppColors.calPolyGold,
                              borderRadius: BorderRadius.zero),
                          child: Consumer<ClubProvider>(
                            builder: (context, clubProvider, child) {
                              return MultiSelectDropdown(
                                label: "My Club Preferences",
                                options: clubProvider.clubAcronyms,
                                selectedItems: selectedClubs,
                                onChanged: (selected) {
                                  setState(() {
                                    selectedClubs = selected;
                                  });
                                },
                              );
                            },
                          )),

                      SizedBox(height: screenHeight * 0.05),

                      // Save Button (moved to bottom, full width)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.yellowButton,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2,
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.03),
                    ],
                  ),
                ),
              ),
            )
          : const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required double screenHeight,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
        child: TextField(
      style: TextStyle(color: Colors.black),
      controller: controller,
      decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.never,
          fillColor: Colors.white,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
          )),
    ));
  }
}
