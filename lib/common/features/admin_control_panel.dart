import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/common/widgets/cal_poly_menu_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ccce_application/common/collections/user_data.dart';

class AdminPanelScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const AdminPanelScreen({super.key, required this.scaffoldKey});
  
  @override
  AdminPanelScreenState createState() => AdminPanelScreenState();
}

class AdminPanelScreenState extends State<AdminPanelScreen> {
  void _showChangeUserRoleDialog() async {
    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
    final users = usersSnapshot.docs;

    showDialog(
      context: context,
      builder: (context) {
        String? selectedUserId;
        String? selectedRole;

        return AlertDialog(
          title: const Text("Change User Role"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                hint: const Text("Select User"),
                items: users.map((doc) {
                  final user = doc.data();
                  return DropdownMenuItem(
                    value: doc.id,
                    child: Text("${user['firstName']} ${user['lastName']}"),
                  );
                }).toList(),
                onChanged: (value) => selectedUserId = value,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                hint: const Text("Select Role"),
                items: ['Student', 'Faculty', 'Club Admin', 'Admin']
                    .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                    .toList(),
                onChanged: (value) => selectedRole = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedUserId != null && selectedRole != null) {
                  await setUserRole(selectedUserId!, selectedRole!.toLowerCase());
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("User role updated to $selectedRole")),
                  );
                }
              },
              child: const Text("Update Role"),
            ),
          ],
        );
      },
    );
  }

  void _showAdminRequestsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Pending Admin Requests"),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('adminRequests').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final requests = snapshot.data!.docs;
                if (requests.isEmpty) {
                  return const Text("No pending requests");
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index].data() as Map<String, dynamic>;
                    final uid = request['uid'];
                    return ListTile(
                      title: Text("${request['name']} (${request['email']})"),
                      subtitle: Text("Requested at: ${request['requestedAt']?.toDate()}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              final callable =
                                  FirebaseFunctions.instance.httpsCallable('makeAdmin');
                              await callable.call({'uid': uid});
                              await FirebaseFirestore.instance
                                  .collection('adminRequests')
                                  .doc(uid)
                                  .delete();
                            },
                            child: const Text("Approve"),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('adminRequests')
                                  .doc(uid)
                                  .delete();
                            },
                            child: const Text("Deny"),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  @override
Widget build(BuildContext context) {
  var screenHeight = MediaQuery.of(context).size.height;
  return Scaffold(
    backgroundColor: AppColors.calPolyGreen,
    body: Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          CalPolyMenuBar(scaffoldKey: widget.scaffoldKey),
          SizedBox(height: screenHeight * .05),
          ElevatedButton(
            onPressed: _showChangeUserRoleDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white, // white background
              foregroundColor: AppColors.darkGold, // text color
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero, // sharp edges
              ),
            ),
            child: const Text("Change User Role"),
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _showAdminRequestsDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.darkGold,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: const Text("View Admin Requests"),
          ),
        ],
      ),
    ),
  );
}
}