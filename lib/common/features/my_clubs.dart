// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:ccce_application/common/collections/club.dart';
import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/common/providers/app_state.dart';
import 'package:ccce_application/common/widgets/resilient_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Widget buildMyClubsList(context) {
  final joinedClubs =
      Provider.of<AppState>(context, listen: true).joinedClubs?.toList() ??
          [];
  
  print("My joined clubs: ${joinedClubs.map((c) => c.name)}");

  Widget sectionHeader(String text, {bool italic = false}) => Padding(
        padding: const EdgeInsets.only(left: 16, top: 12, bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontFamily: italic ? "SansSerifProItalic" : "SansSerifPro",
            fontSize: 24,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      );

  Widget clubRow(Club club) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ClubPopUp(
                  club: club,
                  onClose: () => Navigator.of(context).pop(),
                ),
              ),
            );
          },
          child: SizedBox(
            height: 75,
            child: Row(
              children: [
                Container(
                  height: 75,
                  width: 75,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Center(
                    child: ResilientCircleImage(
                      imageUrl: club.logo,
                      placeholderAsset: 'assets/icons/default_club.png',
                      size: 70,
                    ),
                  ),
                ),
                const SizedBox(width: 1),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(left: 12.0, top: 6.0),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                    child: Center(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            club.name,
                            style: const TextStyle(
                              fontFamily: "AppFonts.sansProSemiBold",
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            club.acronym ?? '',
                            style: const TextStyle(
                              fontFamily: "SansSerifPro",
                              fontSize: 12,
                              color: AppColors.darkGoldText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  joinedClubs.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  return joinedClubs.isNotEmpty
      ? ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            sectionHeader('My Clubs', italic: true),
            ...joinedClubs.map(clubRow).toList(),
          ],
        )
      : Center(
          child: sectionHeader("You haven't joined any clubs yet."),
        );
}

Widget buildMyClubsDisplay(context) {
  return buildMyClubsList(context);
}
