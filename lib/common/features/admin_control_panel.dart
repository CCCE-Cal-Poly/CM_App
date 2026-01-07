import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/common/widgets/cal_poly_menu_bar.dart';
import 'package:ccce_application/common/providers/event_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:provider/provider.dart';

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
    final clubsSnapshot = await FirebaseFirestore.instance.collection('clubs').get();
    final clubs = clubsSnapshot.docs;

    final outerContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) {
        String? selectedUserId;
        String? selectedRole;
        final Set<String> selectedClubIds = {}; 

        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            title: const Text("Change User Role"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    hint: const Text("Select User"),
                    items: users.map((doc) {
                      final user = doc.data();
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text("${user['firstName'] ?? ''} ${user['lastName'] ?? ''}"),
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
                    onChanged: (value) => setState(() => selectedRole = value),
                  ),

                  if ((selectedRole ?? '').toLowerCase() == 'club admin') ...[
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Assign Clubs', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      width: double.maxFinite,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: clubs.length,
                        itemBuilder: (context, index) {
                          final c = clubs[index];
                          final clubData = c.data();
                          final clubName = clubData['Name'] ?? c.id;
                          final clubId = c.id;
                          final checked = selectedClubIds.contains(clubId);
                          return CheckboxListTile(
                            title: Text(clubName),
                            value: checked,
                            onChanged: (v) {
                              setState(() {
                                if (v == true) selectedClubIds.add(clubId);
                                else selectedClubIds.remove(clubId);
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedUserId != null && selectedRole != null) {
                    final clubsToAssign = (selectedRole!.toLowerCase() == 'club admin') ? selectedClubIds.toList() : null;
                    await FirebaseFunctions.instance
                      .httpsCallable('setUserRole')
                      .call(<String, dynamic>{
                        'uid': selectedUserId!,
                        'role': selectedRole!.toLowerCase(),
                        if (clubsToAssign != null) 'clubs': clubsToAssign,
                      });
                    Navigator.of(dialogContext).pop();
                    if (!mounted) return;
                    ScaffoldMessenger.of(outerContext).showSnackBar(
                      SnackBar(content: Text("User role updated to $selectedRole")),
                    );
                  }
                },
                child: const Text("Update Role"),
              ),
            ],
          );
        });
      },
    );
  }

  void _showAdminRequestsDialog() {
    // Capture outer context for safe UI operations after async work
    final outerContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: const Text("Club Admin Requests"),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('clubAdminRequests').where('status', isEqualTo: 'pending').snapshots(),
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
                    final doc = requests[index];
                    final request = doc.data() as Map<String, dynamic>;
                    final uid = request['uid']?.toString() ?? '';
                    final requestedAt = request['requestedAt'] is Timestamp ? (request['requestedAt'] as Timestamp).toDate() : null;
                    final clubsField = request['clubs'];
                    final List<Map<String,String>> clubs = [];
                    if (clubsField is List) {
                      for (final c in clubsField) {
                        if (c == null) continue;
                        if (c is String) {
                          clubs.add({'id': c, 'name': c});
                        } else if (c is Map) {
                          final idv = c['id'] ?? c['clubId'] ?? c['club'] ?? '';
                          final namev = c['name'] ?? c['clubName'] ?? idv;
                          clubs.add({'id': idv.toString(), 'name': namev.toString()});
                        }
                      }
                    }

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AutoSizeText('${request['name'] ?? ''} - ${request['email'] ?? ''}'),
                            if (requestedAt != null) Text('Requested at: $requestedAt'),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 2,
                              children: clubs.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final c = entry.value;
                                final name = (c['name'] ?? c['id'] ?? '').toString();
                                final hasSeparator = idx < clubs.length - 1;
                                return Text(
                                  '$name${hasSeparator ? ',' : ''}',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 4),
                            Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  try {
                                    final clubIds = clubs.map((c) => c['id'] ?? '').where((s) => s.isNotEmpty).toList();
                                    if (clubIds.isEmpty) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(outerContext).showSnackBar(const SnackBar(content: Text('No valid clubs in request')));
                                      return;
                                    }
                                    await FirebaseFunctions.instance
                                        .httpsCallable('setUserRole')
                                        .call(<String, dynamic>{
                                          'uid': uid,
                                          'role': 'club admin',
                                          'clubs': clubIds,
                                        });
                                    
                                    await FirebaseFirestore.instance
                                        .collection('clubAdminRequests')
                                        .doc(doc.id)
                                        .update({
                                      'status': 'approved',
                                      'reviewedBy':
                                          FirebaseAuth.instance.currentUser?.uid,
                                      'reviewedAt': FieldValue.serverTimestamp(),
                                      'approvedAt': FieldValue.serverTimestamp(),
                                    });

                                    if (!mounted) return;
                                    ScaffoldMessenger.of(outerContext).showSnackBar(const SnackBar(content: Text('Approved')));
                                  } catch (e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(outerContext).showSnackBar(SnackBar(content: Text('Approve failed: $e')));
                                  }
                                },
                                child: const Text('Approve'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, ),
                                onPressed: () async {
                                  try {
                                    final adminUser = FirebaseAuth.instance.currentUser;
                                    await FirebaseFirestore.instance.collection('clubAdminRequests').doc(doc.id).update({
                                      'status': 'denied',
                                      'reviewedBy': adminUser?.uid ?? null,
                                      'reviewedAt': FieldValue.serverTimestamp(),
                                    });
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(outerContext).showSnackBar(const SnackBar(content: Text('Denied')));
                                  } catch (e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(outerContext).showSnackBar(SnackBar(content: Text('Deny failed: $e')));
                                  }
                                },
                                child: const Text('Deny', style: TextStyle(color: Colors.white),),
                              ),
                            ],
                          ),
                          ],
                        ),
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

  void _showClubEventRequestsDialog() {
    final outerContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: const Text("Club Event Requests"),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('clubEventRequests')
                  .where('status', isEqualTo: 'pending')
                  .orderBy('submittedAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final requests = snapshot.data!.docs;
                if (requests.isEmpty) {
                  return const Text("No pending event requests");
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final doc = requests[index];
                    final request = doc.data() as Map<String, dynamic>;
                    final submittedAt = request['submittedAt'] is Timestamp 
                        ? (request['submittedAt'] as Timestamp).toDate() 
                        : null;
                    final startTime = request['startTime'] is Timestamp 
                        ? (request['startTime'] as Timestamp).toDate() 
                        : null;
                    final endTime = request['endTime'] is Timestamp 
                        ? (request['endTime'] as Timestamp).toDate() 
                        : null;
                    final recurrenceEndDate = request['recurrenceEndDate'] is Timestamp 
                        ? (request['recurrenceEndDate'] as Timestamp).toDate() 
                        : null;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${request['eventName'] ?? 'Unnamed Event'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('Club: ${request['clubName'] ?? 'Unknown'}'),
                            Text('Requested by: ${request['requestedByName'] ?? request['requestedByEmail'] ?? 'Unknown'}'),
                            if (submittedAt != null) 
                              Text('Submitted: ${submittedAt.toString().substring(0, 16)}'),
                            if (startTime != null)
                              Text('Start: ${startTime.toString().substring(0, 16)}'),
                            if (endTime != null)
                              Text('End: ${endTime.toString().substring(0, 16)}'),
                            if (request['eventLocation'] != null)
                              Text('Location: ${request['eventLocation']}'),
                            if (request['recurrenceType'] != null && request['recurrenceType'].toString().isNotEmpty)
                              Text('Recurrence: ${request['recurrenceType']}'),
                            if (recurrenceEndDate != null)
                              Text('Recurs until: ${recurrenceEndDate.toString().substring(0, 16)}'),
                            if (request['description'] != null && request['description'].toString().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Description: ${request['description']}',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      // Check if user is authenticated
                                      final currentUser = FirebaseAuth.instance.currentUser;
                                      if (currentUser == null) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(outerContext).showSnackBar(
                                          const SnackBar(content: Text('Not authenticated. Please log in again.'))
                                        );
                                        return;
                                      }

                                      // Get fresh token
                                      await currentUser.getIdToken(true);
                                      
                                      final result = await FirebaseFunctions.instance
                                          .httpsCallable('approveClubEvent')
                                          .call(<String, dynamic>{
                                            'requestId': doc.id,
                                          });
                                      
                                      // Add just the new event (cost-efficient)
                                      if (mounted && result.data['eventId'] != null) {
                                        final eventProvider = Provider.of<EventProvider>(outerContext, listen: false);
                                        await eventProvider.addEventById(result.data['eventId']);
                                      }
                                      
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(outerContext).showSnackBar(
                                        const SnackBar(content: Text('Event approved and added to calendar'))
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(outerContext).showSnackBar(
                                        SnackBar(content: Text('Approve failed: $e'))
                                      );
                                    }
                                  },
                                  child: const Text('Approve'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: () async {
                                    try {
                                      // Check if user is authenticated
                                      final currentUser = FirebaseAuth.instance.currentUser;
                                      if (currentUser == null) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(outerContext).showSnackBar(
                                          const SnackBar(content: Text('Not authenticated. Please log in again.'))
                                        );
                                        return;
                                      }

                                      // Get fresh token
                                      await currentUser.getIdToken(true);
                                      
                                      await FirebaseFunctions.instance
                                          .httpsCallable('denyClubEvent')
                                          .call(<String, dynamic>{
                                            'requestId': doc.id,
                                          });
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(outerContext).showSnackBar(
                                        const SnackBar(content: Text('Event request denied'))
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(outerContext).showSnackBar(
                                        SnackBar(content: Text('Deny failed: $e'))
                                      );
                                    }
                                  },
                                  child: const Text(
                                    'Deny',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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

  void _showFacultyRequestsDialog() {
    final outerContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: const Text("Faculty Role Requests"),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('facultyRequests')
                  .where('status', isEqualTo: 'pending')
                  // .orderBy('requestedAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final requests = snapshot.data!.docs;
                if (requests.isEmpty) {
                  return const Text("No pending faculty role requests");
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final doc = requests[index];
                    final request = doc.data() as Map<String, dynamic>;
                    final uid = request['uid']?.toString() ?? '';
                    final requestedAt = request['requestedAt'] is Timestamp
                        ? (request['requestedAt'] as Timestamp).toDate()
                        : null;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${request['name'] ?? 'Unknown'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('Email: ${request['email'] ?? 'Unknown'}'),
                            if (requestedAt != null)
                              Text('Requested at: ${requestedAt.toString().substring(0, 16)}'),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      // Call Cloud Function to set user role to faculty
                                      await FirebaseFunctions.instance
                                          .httpsCallable('setUserRole')
                                          .call(<String, dynamic>{
                                            'uid': uid,
                                            'role': 'faculty',
                                          });

                                      // Update the request status to approved
                                      await FirebaseFirestore.instance
                                          .collection('facultyRequests')
                                          .doc(doc.id)
                                          .update({
                                        'status': 'approved',
                                        'reviewedBy': FirebaseAuth.instance.currentUser?.uid,
                                        'reviewedAt': FieldValue.serverTimestamp(),
                                        'approvedAt': FieldValue.serverTimestamp(),
                                      });

                                      if (!mounted) return;
                                      ScaffoldMessenger.of(outerContext).showSnackBar(
                                        const SnackBar(content: Text('Faculty role approved'))
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(outerContext).showSnackBar(
                                        SnackBar(content: Text('Approve failed: $e'))
                                      );
                                    }
                                  },
                                  child: const Text('Approve'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: () async {
                                    try {
                                      // Update the request status to denied
                                      await FirebaseFirestore.instance
                                          .collection('facultyRequests')
                                          .doc(doc.id)
                                          .update({
                                        'status': 'denied',
                                        'reviewedBy': FirebaseAuth.instance.currentUser?.uid,
                                        'reviewedAt': FieldValue.serverTimestamp(),
                                      });

                                      if (!mounted) return;
                                      ScaffoldMessenger.of(outerContext).showSnackBar(
                                        const SnackBar(content: Text('Faculty role request denied'))
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(outerContext).showSnackBar(
                                        SnackBar(content: Text('Deny failed: $e'))
                                      );
                                    }
                                  },
                                  child: const Text(
                                    'Deny',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
              backgroundColor: Colors.white,
              foregroundColor: AppColors.darkGold, 
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
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
            child: const Text("Pending Club Admin Requests"),
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _showClubEventRequestsDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.darkGold,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: const Text("Pending Club Event Requests"),
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _showFacultyRequestsDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.darkGold,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: const Text("Pending Faculty Role Requests"),
          ),
        ],
      ),
    ),
  );
}
}

class AdminControlPanelRequests extends StatelessWidget {
  const AdminControlPanelRequests({super.key});

  Future<void> _approve(BuildContext context, String requestId) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('approveClubEvent');
      await callable.call(<String, dynamic>{'requestId': requestId});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Approved')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Approve failed: $e')));
    }
  }

  Future<void> _deny(BuildContext context, String requestId) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('denyClubEvent');
      await callable.call(<String, dynamic>{'requestId': requestId});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Denied')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deny failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('clubEventRequests')
        .where('status', isEqualTo: 'pending')
        .orderBy('submittedAt', descending: false)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('No pending requests'));
        return ListView.builder(
          shrinkWrap: true,
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final id = docs[i].id;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: ListTile(
                title: Text('${data['eventName'] ?? 'Unnamed event'} — ${data['clubName'] ?? ''}'),
                subtitle: Text('Requested by ${data['requestedByName'] ?? data['requestedByEmail'] ?? ''}\n${data['description'] ?? ''}'),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () => _approve(context, id),
                      child: const Text('Approve'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => _deny(context, id),
                      child: const Text('Deny', style: TextStyle(color: Colors.white),),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}