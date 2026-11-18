import 'package:ccce_application/common/collections/interview.dart';
import 'package:ccce_application/common/features/interview_signup_screen.dart';
import 'package:ccce_application/common/providers/event_provider.dart';
import 'package:ccce_application/common/theme/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// The signed-in student's interview sign-ups (from users/{uid}/interviewSignups).
class MyInterviewsScreen extends StatelessWidget {
  const MyInterviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: AppColors.calPolyGreen,
      appBar: AppBar(
        title: const Text('My Interviews',
            style: TextStyle(
                fontFamily: AppFonts.sansProSemiBold,
                color: AppColors.welcomeLightYellow,
                fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.calPolyGreen,
        foregroundColor: Colors.white,
      ),
      body: uid == null
          ? const _Message('Sign in to see your interviews.')
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('interviewSignups')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const _Message('Error loading your interviews.');
                }
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.white));
                }
                final now = DateTime.now();
                final all =
                    snapshot.data!.docs.map(MyInterview.fromSnapshot).toList();
                final upcoming = all
                    .where((i) => i.slotStart.isAfter(now))
                    .toList()
                  ..sort((a, b) => a.slotStart.compareTo(b.slotStart));
                final past = all
                    .where((i) =>
                        !i.slotStart.isAfter(now) &&
                        i.slotStart
                            .isAfter(now.subtract(const Duration(days: 120))))
                    .toList()
                  ..sort((a, b) => b.slotStart.compareTo(a.slotStart));

                if (upcoming.isEmpty && past.isEmpty) {
                  return const _Message(
                      "You haven't signed up for any interviews. Look for interview times on the calendar or in an info session.");
                }
                return ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    const _Header('Upcoming'),
                    if (upcoming.isEmpty)
                      const _Message('No upcoming interviews.'),
                    ...upcoming.map((i) => _InterviewRow(i)),
                    if (past.isNotEmpty) const _Header('Past'),
                    ...past.map((i) => _InterviewRow(i)),
                  ],
                );
              },
            ),
    );
  }
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 16, top: 12, bottom: 8),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white,
                fontFamily: 'SansSerifProItalic',
                fontSize: 24,
                fontStyle: FontStyle.italic)),
      );
}

class _Message extends StatelessWidget {
  final String text;
  const _Message(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(text,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
      );
}

class _InterviewRow extends StatelessWidget {
  final MyInterview interview;
  const _InterviewRow(this.interview);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        final block = context
            .read<EventProvider>()
            .allEvents
            .where((e) => e.id == interview.blockId)
            .firstOrNull;
        if (block == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Interview details are not available.')));
          return;
        }
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => InterviewSignUpScreen(block: block)));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
        child: SizedBox(
          height: 65,
          child: Row(
            children: [
              Container(
                width: 80,
                color: Colors.white,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(DateFormat('MMM d').format(interview.slotStart),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.darkGoldText)),
                    Text(DateFormat('h:mm a').format(interview.slotStart),
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.darkGoldText)),
                  ],
                ),
              ),
              const SizedBox(width: 1),
              Expanded(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.only(left: 12),
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${interview.company} Interview',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (interview.location.isNotEmpty)
                        Text(interview.location,
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.darkGoldText),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
