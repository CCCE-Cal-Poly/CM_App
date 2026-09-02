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

class Member implements Comparable<Member> {
  dynamic id;
  dynamic name;
  dynamic website;
  dynamic level;
  String? logo;
  String? indivualName;
  // List<CalEvent> events;
  
  Member({this.id,
    this.name, 
    this.website, 
    this.level,
    this.logo,
    this.indivualName, 
  }); 

  factory Member.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Member(
      id: doc.id,
      name: data['Name'] ?? 'No Name',
      website: data['Website'] ?? 'No Website',
      level: data['Level'] ?? 'No Level',
      logo: (data['Logo'] ?? data['logo']) as String?, // Support both 'Logo' and 'logo' field names
      indivualName: data['IndividualName'] as String?,
    );
  }


  @override
  int compareTo(Member other) {
    return (name.toLowerCase().compareTo(other.name.toLowerCase()));
  }
}

class MemberItem extends StatelessWidget {
  Widget memberLogoImage(String? url, BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return ResilientImage(
      imageUrl: url,
      placeholderAsset: 'assets/icons/default_company.png',
      fit: BoxFit.contain,
      height: screenWidth * .15,
    );
  }

  final Member member;

  const MemberItem(this.member, {Key? key}) : super(key: key);

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
              child: memberLogoImage(member.logo, context),
            ),
          ),
        ),
    );
  }
}

Widget memberLogoImage(String? url, BuildContext context) {
  double screenWidth = MediaQuery.of(context).size.width;
  return ResilientImage(
    imageUrl: url,
    placeholderAsset: 'assets/icons/default_company.png',
    fit: BoxFit.contain,
    height: screenWidth * .15,
  );
}