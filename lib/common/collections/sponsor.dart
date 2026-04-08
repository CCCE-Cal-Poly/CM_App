import 'package:auto_size_text/auto_size_text.dart';
import 'package:ccce_application/common/collections/calevent.dart';
import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/common/providers/app_state.dart';
import 'package:ccce_application/common/providers/user_provider.dart';
import 'package:ccce_application/common/widgets/resilient_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ccce_application/services/error_logger.dart';

class Sponsor implements Comparable<Sponsor> {
  dynamic id;
  dynamic name;
  dynamic website;
  dynamic sponsorLevel;
  String? logo;
  // List<CalEvent> events;
  
  Sponsor({this.id,
    this.name, 
    this.website, 
    this.sponsorLevel,
    this.logo, 
  }); 

  factory Sponsor.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Sponsor(
      id: doc.id,
      name: data['Name'] ?? 'No Name',
      website: data['Website'] ?? 'No Website',
      sponsorLevel: data['SponsorLevel'] ?? 'No Level',
      logo: (data['Logo'] ?? data['logo']) as String?, // Support both 'Logo' and 'logo' field names
    );
  }


  @override
  int compareTo(Sponsor other) {
    return (name.toLowerCase().compareTo(other.name.toLowerCase()));
  }
}

class SponsorItem extends StatelessWidget {
  Widget sponsorLogoImage(String? url, BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return ResilientImage(
      imageUrl: url,
      placeholderAsset: 'assets/icons/default_company.png',
      fit: BoxFit.contain,
      height: screenWidth * .15,
    );
  }

  final Sponsor sponsor;

  const SponsorItem(this.sponsor, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.transparent),
            borderRadius: BorderRadius.zero,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.2, 
                ),
                spreadRadius: 1,
                blurRadius: 2,
                offset: const Offset(0, 2), 
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
                vertical: screenHeight * .005, horizontal: screenWidth * 0.01),
            child: Center(
              child: sponsorLogoImage(sponsor.logo, context),
            ),
          ),
        ),
    );
  }
}

        // onTap: () async {
        //   final url = sponsor.website;
        //   if (url != null && url.isNotEmpty) {
        //     final uri = Uri.parse(url);
        //     try {
        //       await launchUrl(uri, mode: LaunchMode.externalApplication);
        //     } catch (e) {
        //       if (!context.mounted) return;
        //       await Clipboard.setData(ClipboardData(text: url));
        //       ScaffoldMessenger.of(context).showSnackBar(
        //         const SnackBar(content: Text('Website link copied to clipboard')),
        //       );
        //     }
        //   }
        // },

// class ClubPopUp extends StatefulWidget {
//   final Club club;

//   final VoidCallback onClose;

//   const ClubPopUp({required this.club, required this.onClose, Key? key})
//       : super(key: key);

//   @override
//   _ClubPopUpState createState() => _ClubPopUpState();
// }

Widget sponsorLogoImage(String? url, BuildContext context) {
  double screenWidth = MediaQuery.of(context).size.width;
  return ResilientImage(
    imageUrl: url,
    placeholderAsset: 'assets/icons/default_company.png',
    fit: BoxFit.contain,
    height: screenWidth * .15,
  );
}

// class _ClubPopUpState extends State<ClubPopUp> {
//   bool _isLoadingEvents = true;

//   @override
//   void initState() {
//     super.initState();
//     _initializeClub();
//   }

//   Future<void> _initializeClub() async {
//     // Auto-join club admins to their clubs if not already joined
//     final userProvider = Provider.of<UserProvider>(context, listen: false);
//     final appState = Provider.of<AppState>(context, listen: false);
    
//     if (userProvider.isClubAdmin(widget.club.id) && !appState.isJoined(widget.club)) {
//       appState.addJoinedClub(widget.club);
//     }

//     // Fetch events from references
//     await widget.club.fetchEvents();
    
//     if (mounted) {
//       setState(() {
//         _isLoadingEvents = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     double screenHeight = MediaQuery.of(context).size.height;
//     double screenWidth = MediaQuery.of(context).size.width;
//     final now = DateTime.now();
//     final twoWeeksFromNow = now.add(const Duration(days: 14));
    
//     final clubEvents = widget.club.events.where((e) {
//       final t = e.eventType.toLowerCase();
//       final isClubEvent = t == 'club' || t == 'club event' || t == 'clubevent' || t == 'club_event';
//       final isUpcoming = e.startTime.isAfter(now) && e.startTime.isBefore(twoWeeksFromNow);
//       return isClubEvent && isUpcoming;
//     }).toList()
//     ..sort((a, b) => a.startTime.compareTo(b.startTime));
    
//     return Scaffold(
//       backgroundColor: AppColors.calPolyGreen,
//       body: ListView(
//         children: [
//           Stack(
//             children: [
//               Center(
//                 child: Container(
//                   decoration: const BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.zero,
//                   ),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.start,
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       Padding(
//                         padding: EdgeInsets.only(
//                           left: screenWidth * .02,
//                           top: screenHeight * .012,
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             SizedBox(
//                               height: screenHeight * .03,
//                               child: IconButton(
//                                 icon: const Icon(
//                                   Icons.arrow_back,
//                                   color: Colors.black,
//                                 ),
//                                 onPressed: widget.onClose,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       Padding(
//                         padding: EdgeInsets.all(screenWidth * 0.015),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             SizedBox(
//                               width: screenHeight * 0.14,
//                               height: screenHeight * 0.14,
//                               child: clubLogoImage(
//                                 widget.club.logo,
//                                 screenHeight * 0.1,
//                                 screenHeight * 0.1,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       Padding(
//                         padding: EdgeInsets.all(screenHeight * 0.015),
//                         child: Column(
//                           children: [
//                             SizedBox(
//                               width: screenWidth * 0.7,
//                               child: AutoSizeText(
//                                 widget.club.name,
//                                 textAlign: TextAlign.center,
//                                 style: const TextStyle(
//                                   fontSize: 19,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                                 minFontSize: 16,
//                                 maxLines: 2,
//                               ),
//                             ),
//                             Text(
//                               "(" + widget.club.acronym + ")",
//                               textAlign: TextAlign.center,
//                               style: const TextStyle(
//                                 fontSize: 15.0,
//                               ),
//                             ),
//                             SizedBox(height: screenHeight * .0015),
//                             Padding(
//                               padding: EdgeInsets.symmetric(
//                                 vertical: screenHeight * 0.015,
//                               ),
//                               child: Consumer<UserProvider>(
//                                 builder: (context, userProvider, _) {
//                                   final isClubAdmin = userProvider.isClubAdmin(widget.club.id);
//                                   final isJoined = context.watch<AppState>().isJoined(widget.club);
                                  
//                                   if (isClubAdmin) {
//                                     // Show "Stop Being Club Admin" button for club admins
//                                     return ElevatedButton(
//                                       onPressed: () async {
//                                         // Show confirmation dialog
//                                         final confirmed = await showDialog<bool>(
//                                           context: context,
//                                           builder: (dialogContext) => AlertDialog(
//                                             title: const Text('Remove Admin Access?'),
//                                             content: Text('Are you sure you want to stop being an admin for ${widget.club.name}?'),
//                                             actions: [
//                                               TextButton(
//                                                 onPressed: () => Navigator.of(dialogContext).pop(false),
//                                                 child: const Text('Cancel'),
//                                               ),
//                                               TextButton(
//                                                 onPressed: () => Navigator.of(dialogContext).pop(true),
//                                                 style: TextButton.styleFrom(foregroundColor: Colors.red),
//                                                 child: const Text('Remove'),
//                                               ),
//                                             ],
//                                           ),
//                                         );
                                        
//                                         if (confirmed == true) {
//                                           try {
//                                             final user = FirebaseAuth.instance.currentUser;
//                                             if (user != null) {
//                                               await FirebaseFirestore.instance
//                                                   .collection('users')
//                                                   .doc(user.uid)
//                                                   .update({
//                                                 'clubsAdminOf': FieldValue.arrayRemove([widget.club.id])
//                                               });
                                              
//                                               // Check if user has any clubs left - if not, downgrade to student
//                                               final updatedDoc = await FirebaseFirestore.instance
//                                                   .collection('users')
//                                                   .doc(user.uid)
//                                                   .get();
//                                               final clubsLeft = List<String>.from(updatedDoc.data()?['clubsAdminOf'] ?? []);
                                              
//                                               if (clubsLeft.isEmpty) {
//                                                 // No clubs left - downgrade to student
//                                                 await FirebaseFirestore.instance
//                                                     .collection('users')
//                                                     .doc(user.uid)
//                                                     .update({'role': 'student'});
//                                               }
                                              
//                                               if (!mounted) return;
//                                               ScaffoldMessenger.of(context).showSnackBar(
//                                                 SnackBar(
//                                                   content: Text(clubsLeft.isEmpty 
//                                                       ? 'Removed as admin of ${widget.club.name}. Role changed to Student.'
//                                                       : 'Removed as admin of ${widget.club.name}'),
//                                                   backgroundColor: Colors.green,
//                                                 ),
//                                               );
//                                             }
//                                           } catch (e) {
//                                             if (!mounted) return;
//                                             ScaffoldMessenger.of(context).showSnackBar(
//                                               SnackBar(
//                                                 content: Text('Failed to remove admin access: $e'),
//                                                 backgroundColor: Colors.red,
//                                               ),
//                                             );
//                                           }
//                                         }
//                                       },
//                                       style: ElevatedButton.styleFrom(
//                                         fixedSize: Size(
//                                           screenWidth * 0.5,
//                                           screenHeight * 0.05,
//                                         ),
//                                         backgroundColor: Colors.red.shade400,
//                                         shape: const RoundedRectangleBorder(
//                                           borderRadius: BorderRadius.zero,
//                                         ),
//                                         padding: EdgeInsets.symmetric(
//                                           horizontal: screenWidth * .03,
//                                           vertical: screenHeight * .008,
//                                         ),
//                                       ),
//                                       child: const Text(
//                                         'RESIGN CLUB ADMIN',
//                                         style: TextStyle(
//                                           color: Colors.white,
//                                           fontSize: 13,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                     );
//                                   } else {
//                                     // Show Join/Joined button for non-admins
//                                     return ElevatedButton(
//                                       onPressed: () {
//                                         if (isJoined) {
//                                           context.read<AppState>().removeJoinedClub(widget.club);
//                                         } else {
//                                           context.read<AppState>().addJoinedClub(widget.club);
//                                         }
//                                       },
//                                       style: ElevatedButton.styleFrom(
//                                         fixedSize: Size(
//                                           screenWidth * 0.5,
//                                           screenHeight * 0.05,
//                                         ),
//                                         backgroundColor: isJoined
//                                             ? Colors.grey
//                                             : AppColors.calPolyGreen,
//                                         shape: const RoundedRectangleBorder(
//                                           borderRadius: BorderRadius.zero,
//                                         ),
//                                         padding: EdgeInsets.symmetric(
//                                           horizontal: screenWidth * .03,
//                                           vertical: screenHeight * .008,
//                                         ),
//                                       ),
//                                       child: isJoined
//                                           ? const Row(
//                                               mainAxisSize: MainAxisSize.min,
//                                               children: [
//                                                 Icon(Icons.check, color: Colors.black),
//                                                 SizedBox(width: 6),
//                                                 Text(
//                                                   'JOINED',
//                                                   style: TextStyle(
//                                                     color: Colors.black,
//                                                     fontSize: 16,
//                                                     fontWeight: FontWeight.bold,
//                                                   ),
//                                                 ),
//                                               ],
//                                             )
//                                           : const Text(
//                                               'JOIN CLUB',
//                                               style: TextStyle(
//                                                 color: AppColors.welcomeLightYellow,
//                                                 fontSize: 16,
//                                                 fontWeight: FontWeight.bold,
//                                               ),
//                                             ),
//                                     );
//                                   }
//                                 },
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           Container(
//             color: AppColors.calPolyGreen,
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       "Upcoming Events",
//                       style: TextStyle(
//                         color: AppColors.lightGold,
//                         fontSize: 22.0,
//                         fontWeight: FontWeight.w400,
//                       ),
//                     ),
//                     const SizedBox(height: 5),
//                     // Show loading indicator while fetching events
//                     if (_isLoadingEvents)
//                       const Center(
//                         child: Padding(
//                           padding: EdgeInsets.all(16.0),
//                           child: CircularProgressIndicator(
//                             valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                           ),
//                         ),
//                       )
//                     // Only show events that represent club events (not info sessions or other types)
//                     else if (clubEvents.isNotEmpty)
//                       ...clubEvents.map((event) => Padding(
//                             padding: const EdgeInsets.only(bottom: 8.0),
//                             child: _EventTile(event: event),
//                           ))
//                     else
//                       const Text(
//                         "No upcoming events.",
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 16.0,
//                         ),
//                       ),
//                   ],
//                 ),
//                 const Divider(),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Icon(
//                           Icons.mail,
//                           size: 24,
//                           color: Colors.white,
//                         ),
//                         const SizedBox(width: 10),
//                         InkWell(
//                           onTap: () async {
//                             final email = widget.club.email;
//                             if (email != null && email.isNotEmpty) {
//                               final uri = Uri(scheme: 'mailto', path: email);
//                               try {
//                                 await launchUrl(uri);
//                               } catch (e) {
//                                 if (!mounted) return;
//                                 await Clipboard.setData(ClipboardData(text: email));
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   const SnackBar(content: Text('Email copied to clipboard')),
//                                 );
//                               }
//                             }
//                           },
//                           child: Text(
//                             widget.club.email ?? 'No Email',
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 18.0,
//                               decoration: TextDecoration.underline,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Container(
//                           height: 24,
//                           width: 24,
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(6.0),
//                             color: Colors.transparent,
//                             border: Border.all(color: Colors.white),
//                           ),
//                           child: const Icon(
//                             Icons.camera_alt,
//                             size: 16,
//                             color: Colors.white,
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         InkWell(
//                           onTap: () async {
//                             final instagram = widget.club.instagram;
//                             if (instagram != null && instagram.isNotEmpty) {
//                               // Try to extract handle and build full URL
//                               String url = instagram;
//                               if (!url.startsWith('http')) {
//                                 // Remove @ if present
//                                 final handle = instagram.startsWith('@') ? instagram.substring(1) : instagram;
//                                 url = 'https://instagram.com/$handle';
//                               }
//                               final uri = Uri.parse(url);
//                               try {
//                                 await launchUrl(uri, mode: LaunchMode.externalApplication);
//                               } catch (e) {
//                                 if (!mounted) return;
//                                 await Clipboard.setData(ClipboardData(text: url));
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   const SnackBar(content: Text('Instagram link copied to clipboard')),
//                                 );
//                               }
//                             }
//                           },
//                           child: Text(
//                             (widget.club.instagram != null && widget.club.instagram!.isNotEmpty)
//                                 ? '@${widget.club.instagram}'
//                                 : 'No Instagram',
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 18.0,
//                               decoration: TextDecoration.underline,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       "About",
//                       style: TextStyle(
//                         color: AppColors.lightGold,
//                         fontSize: 22.0,
//                         fontWeight: FontWeight.w400,
//                       ),
//                     ),
//                     const SizedBox(height: 5),
//                     Text(
//                       widget.club.aboutMsg,
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 14.0,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// Compact event tile used in ClubPopUp
// class _EventTile extends StatelessWidget {
//   final CalEvent event;

//   const _EventTile({required this.event, Key? key}) : super(key: key);

//   String _formatShortDate(DateTime dt) {
//     // e.g. 'Oct 3 · 3:30pm'
//     final month = _shortMonth(dt.month);
//     final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
//     final minute = dt.minute.toString().padLeft(2, '0');
//     final ampm = dt.hour >= 12 ? 'pm' : 'am';
//     return '$month ${dt.day} · $hour:$minute$ampm';
//   }

//   String _shortMonth(int m) {
//     const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
//     return months[(m-1).clamp(0,11)];
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.06),
//         borderRadius: BorderRadius.circular(6),
//       ),
//       padding: const EdgeInsets.all(8.0),
//       child: Row(
//         children: [
//           SizedBox(
//             width: screenWidth * 0.12,
//             height: screenWidth * 0.12,
//             child: clubLogoImage(event.logo, screenWidth * 0.12, screenWidth * 0.12),
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   event.eventName,
//                   style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   _formatShortDate(event.startTime),
//                   style: const TextStyle(color: Colors.white70, fontSize: 12),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
