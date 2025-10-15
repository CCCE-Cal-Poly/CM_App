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

  String _toTitleCase(String input) {
    if (input.isEmpty) return input;
    return input
        .split(RegExp(r"\s+"))
        .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }

  void _loadUserData() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = FirebaseAuth.instance.currentUser;

    if (userProvider.user != null) {
      final userData = userProvider.user!;
      final nameParts = userData.name.trim().split(' ');

      _firstNameController.text = nameParts.isNotEmpty ? nameParts.first : '';
      _lastNameController.text =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      _emailController.text = userData.email;
      _profilePictureUrlController.text = userData.profilePictureUrl ?? '';
    } else if (currentUser != null) {
      _emailController.text = currentUser.email ?? '';
      if (currentUser.displayName != null) {
        final nameParts = currentUser.displayName!.split(' ');
        _firstNameController.text = nameParts.isNotEmpty ? nameParts.first : '';
        _lastNameController.text =
            nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      }
      _profilePictureUrlController.text = currentUser.photoURL ?? '';
    }

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
              _roleController.text = (data['role'].toString());
              _isInitialized = true;
            });
          } else {
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

      final role = _roleController.text.trim();
      final userUpdate = <String, dynamic>{
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': role,
        'profilePictureUrl': _profilePictureUrlController.text.trim().isEmpty
            ? null
            : _profilePictureUrlController.text.trim(),
      };

      if (role.toLowerCase() == "admin") {
        await FirebaseFirestore.instance
            .collection('adminRequests')
            .doc(currentUser.uid)
            .set({
          'uid': currentUser.uid,
          'name': "${_firstNameController.text} ${_lastNameController.text}",
          'email': _emailController.text.trim(),
          'requestedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .set(userUpdate, SetOptions(merge: true));
      }

      if (mounted) {
        await Provider.of<UserProvider>(context, listen: false)
            .loadUserProfile(currentUser.uid);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

                      SizedBox(height: screenHeight * 0.01),

                      Center(
                        child: Text(
                          _roleController.text.isNotEmpty ? _toTitleCase(_roleController.text) : 'Student',
                          style: const TextStyle(
                            color: AppColors.tanText,
                            fontFamily: AppFonts.sansProSemiBold,
                            fontSize: 14,
                          ),
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.03),

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

                      SizedBox(height: screenHeight * 0.025),
                      const Divider(
                        color: Colors.white,
                      ),
                      SizedBox(height: screenHeight * 0.025),

                      Container(
                          decoration: const BoxDecoration(
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

                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.calPolyGold,
                            foregroundColor: Colors.black,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                            onPressed: () async {
                            final navigatorContext = context; 
                            final clubProvider = Provider.of<ClubProvider>(navigatorContext, listen: false);
                            await clubProvider.loadClubs();
                            if (!mounted) return;

                            final clubs = clubProvider.clubs;
                            final selected = <String>[];

                            await showDialog(
                              context: navigatorContext,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('Request Club Admin'),
                                  content: StatefulBuilder(builder: (context, setState) {
                                    if (clubs.isEmpty) {
                                      return const SizedBox(height: 80, child: Center(child: Text('No clubs available')));
                                    }
                                    return SizedBox(
                                      width: double.maxFinite,
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: clubs.length,
                                        itemBuilder: (context, i) {
                                          final club = clubs[i];
                                          final clubId = club.id?.toString() ?? '';
                                          final clubLabel = (club.name != null && club.name.toString().isNotEmpty) ? club.name.toString() : (club.acronym?.toString() ?? clubId);
                                          final checked = selected.contains(clubId);
                                          return CheckboxListTile(
                                            title: Text(clubLabel),
                                            value: checked,
                                            onChanged: (v) => setState(() {
                                              if (v == true) {
                                                if (!selected.contains(clubId)) selected.add(clubId);
                                              } else {
                                                selected.remove(clubId);
                                              }
                                            }),
                                          );
                                        },
                                      ),
                                    );
                                  }),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                    ElevatedButton(
                                      onPressed: () async {
                                        final user = FirebaseAuth.instance.currentUser;
                                        if (user != null && selected.isNotEmpty) {
                                          final existing = await FirebaseFirestore.instance.collection('clubAdminRequests').where('uid', isEqualTo: user.uid).get();
                                            final Set<String> alreadyRequested = {};
                                            for (final doc in existing.docs) {
                                              final data = doc.data();
                                              if (data.containsKey('clubs')) {
                                                final clubsField = data['clubs'];
                                                if (clubsField is List) {
                                                  for (final c in clubsField) {
                                                    if (c == null) continue;
                                                    if (c is String) {
                                                      alreadyRequested.add(c);
                                                    } else if (c is Map) {
                                                      final idVals = [];
                                                      idVals.add(c['id'] ?? c['clubId'] ?? c['club_id'] ?? c['club']);
                                                      if (idVals != null) alreadyRequested.add(idVals.toString());
                                                    } else {
                                                      alreadyRequested.add(c.toString());
                                                    }
                                                  }
                                                }
                                              }
                                            }

                                            final Map<String, String> idToName = { for (final c in clubs) (c.id?.toString() ?? ''): (c.name?.toString() ?? c.acronym?.toString() ?? '') };

                                            final toRequestIds = selected.where((id) => !alreadyRequested.contains(id)).toList();

                                            if (toRequestIds.isEmpty) {
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('You already have requests for the selected clubs'))
                                              );
                                              return;
                                            }

                                            final toRequest = toRequestIds.map((id) => {
                                              'id': id,
                                              'name': idToName[id] ?? id,
                                            }).toList();

                                            final userName = "${_firstNameController.text} ${_lastNameController.text}";

                                            await FirebaseFirestore.instance.collection('clubAdminRequests').add({
                                              'uid': user.uid,
                                              'name': userName ?? '',
                                              'email': user.email,
                                              'requestedAt': FieldValue.serverTimestamp(),
                                              'clubs': toRequest,
                                              'status': 'pending',
                                            });
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Club admin request submitted')));
                                          }
                                        }
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Submit Request'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: const Text('Request Club Admin'),
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.025),
                      const Divider(
                        color: Colors.white,
                      ),

                      SizedBox(height: screenHeight * 0.025),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.yellowButton,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
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
    return TextField(
          style: const TextStyle(color: Colors.black),
          controller: controller,
          decoration: InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      fillColor: Colors.white,
      filled: true,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
      )),
        );
  }
  Future<void> requestAdminRole(String uid) async {
    await FirebaseFirestore.instance.collection('adminRequests').doc(uid).set({
      'uid': uid,
      'requestedAt': FieldValue.serverTimestamp(),
    });
  }
}