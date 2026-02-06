import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:ccce_application/common/providers/user_provider.dart';
import 'package:ccce_application/common/providers/club_provider.dart';
import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/common/features/sign_in.dart';
import 'package:ccce_application/common/constants/app_constants.dart';
import 'package:ccce_application/services/error_logger.dart';
import 'dart:io';

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

  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isUploadingImage = false;
  File? _selectedImageFile;
  String? _uploadedImageUrl;

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
        ErrorLogger.logError('EditProfileScreen', 'Error loading additional fields', error: e);
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

  Future<void> _pickAndUploadImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isUploadingImage = true;
        _selectedImageFile = File(image.path);
      });

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      // Create a reference to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('${currentUser.uid}.jpg');

      // Upload the file
      final uploadTask = await storageRef.putFile(_selectedImageFile!);

      // Get the download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      setState(() {
        _uploadedImageUrl = downloadUrl;
        _profilePictureUrlController.text = downloadUrl;
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture uploaded successfully!')),
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
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

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                  helperText: 'At least 8 characters',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final currentPassword = currentPasswordController.text.trim();
              final newPassword = newPasswordController.text.trim();
              final confirmPassword = confirmPasswordController.text.trim();

              if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppConstants.errorAllFieldsRequired)),
                );
                return;
              }

              if (newPassword != confirmPassword) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppConstants.errorPasswordMismatchChange)),
                );
                return;
              }

              if (newPassword.length < AppConstants.minPasswordLengthChange) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppConstants.errorPasswordRequirementNotMet)),
                );
                return;
              }

              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null || user.email == null) {
                  throw Exception('No authenticated user');
                }

                // Re-authenticate user
                final credential = EmailAuthProvider.credential(
                  email: user.email!,
                  password: currentPassword,
                );
                await user.reauthenticateWithCredential(credential);

                // Update password
                await user.updatePassword(newPassword);

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext, true);
              } on FirebaseAuthException catch (e) {
                String message = 'Failed to change password';
                if (e.code == 'wrong-password') {
                  message = 'Current password is incorrect';
                } else if (e.code == 'weak-password') {
                  message = 'New password is too weak';
                } else if (e.code == 'requires-recent-login') {
                  message = 'Please sign out and sign in again before changing password';
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    final passwordController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Account'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This action cannot be undone. Your account and all associated data will be permanently deleted.',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 16),
              const Text('This includes:'),
              const Text('• Profile information'),
              const Text('• Event check-ins'),
              const Text('• Club memberships'),
              const Text('• Favorite companies'),
              const Text('• All preferences'),
              const SizedBox(height: 16),
              const Text('Enter your password to confirm:'),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final password = passwordController.text.trim();
              if (password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password is required')),
                );
                return;
              }

              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null || user.email == null) {
                  throw Exception('No authenticated user');
                }

                // Re-authenticate user
                final credential = EmailAuthProvider.credential(
                  email: user.email!,
                  password: password,
                );
                await user.reauthenticateWithCredential(credential);

                // Delete Firebase Auth account
                // Backend cleanup (Firestore, Storage, memberships, etc.) is handled by
                // the onUserDeleted Cloud Function.
                await user.delete();

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext, true);
              } on FirebaseAuthException catch (e) {
                String message = 'Failed to delete account';
                if (e.code == 'wrong-password') {
                  message = 'Password is incorrect';
                } else if (e.code == 'requires-recent-login') {
                  message = 'Please sign out and sign in again before deleting your account';
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting account: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Account deleted, navigate to sign-in
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignIn()),
        (route) => false,
      );
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

                      GestureDetector(
                        onTap: _isUploadingImage ? null : _pickAndUploadImage,
                        child: Stack(
                          children: [
                            Consumer<UserProvider>(
                              builder: (context, userProvider, child) {
                                final currentUser =
                                    FirebaseAuth.instance.currentUser;
                                final userData = userProvider.user;

                                ImageProvider profileImage;
                                
                                // Priority: uploaded image > user data > selected file > current user > default
                                if (_uploadedImageUrl != null) {
                                  profileImage = NetworkImage(_uploadedImageUrl!);
                                } else if (_selectedImageFile != null) {
                                  profileImage = FileImage(_selectedImageFile!);
                                } else if (userData?.profilePictureUrl != null &&
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

                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 60,
                                      backgroundColor: Colors.grey[400],
                                      backgroundImage: profileImage,
                                    ),
                                    if (_isUploadingImage)
                                      Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                  ],
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
                                  Icons.camera_alt,
                                  color: Colors.black,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
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
                        readOnly: true,
                        enabled: false,
                      ),
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(
                          'Email cannot be changed as it is linked to your account',
                          style: TextStyle(
                            color: AppColors.tanText,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),

                      SizedBox(height: screenHeight * .03),

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

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(),
                      ),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.yellowButton,
                            foregroundColor: Colors.black,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          onPressed: _showChangePasswordDialog,
                          child: const Text('Change Password'),
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.01),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade400,
                            foregroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          onPressed: _showDeleteAccountDialog,
                          child: const Text('Delete Account'),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(),
                      ),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.yellowButton,
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
                                        if (selected.isEmpty) {
                                          Navigator.pop(context);
                                          return;
                                        }
                                        
                                        final user = FirebaseAuth.instance.currentUser;
                                        if (user == null) {
                                          Navigator.pop(context);
                                          return;
                                        }
                                        
                                        // Only check pending requests to avoid blocking after denial/approval
                                        final existing = await FirebaseFirestore.instance
                                            .collection('clubAdminRequests')
                                            .where('uid', isEqualTo: user.uid)
                                            .where('status', isEqualTo: 'pending')
                                            .get();
                                        
                                        if (!context.mounted) return;
                                        
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
                                                  final idVals = c['id'] ?? c['clubId'] ?? c['club_id'] ?? c['club'];
                                                  alreadyRequested.add(idVals.toString());
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
                                          'name': userName,
                                          'email': user.email,
                                          'requestedAt': FieldValue.serverTimestamp(),
                                          'clubs': toRequest,
                                          'status': 'pending',
                                        });
                                        
                                        if (!context.mounted) return;
                                        
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Club admin request submitted'))
                                        );
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

                      SizedBox(height: screenHeight * 0.02),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.yellowButton,
                            foregroundColor: Colors.black,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          onPressed: () async {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) return;

                            // Check for existing pending faculty request
                            final existing = await FirebaseFirestore.instance
                                .collection('facultyRequests')
                                .where('uid', isEqualTo: user.uid)
                                .where('status', isEqualTo: 'pending')
                                .get();

                            if (!context.mounted) return;

                            if (existing.docs.isNotEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('You already have a pending faculty role request'))
                              );
                              return;
                            }

                            // Show confirmation dialog
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Request Faculty Role'),
                                content: const Text(
                                  'Are you sure you want to request the faculty role? '
                                  'A member of CCCE will review your request and may reach out for verification.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Request'),
                                  ),
                                ],
                              ),
                            ) ?? false;

                            if (!confirmed || !context.mounted) return;

                            final userName = "${_firstNameController.text} ${_lastNameController.text}";

                            try {
                              await FirebaseFirestore.instance.collection('facultyRequests').add({
                                'uid': user.uid,
                                'name': userName,
                                'email': user.email,
                                'requestedAt': FieldValue.serverTimestamp(),
                                'status': 'pending',
                              });

                              if (!context.mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Faculty role request submitted successfully'))
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error submitting request: $e'))
                              );
                            }
                          },
                          child: const Text('Request Faculty Role'),
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
    bool readOnly = false,
    bool enabled = true,
  }) {
    return TextField(
          style: TextStyle(
            color: enabled ? Colors.black : Colors.grey[600],
          ),
          controller: controller,
          readOnly: readOnly,
          enabled: enabled,
          decoration: InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      fillColor: enabled ? Colors.white : Colors.grey[200],
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