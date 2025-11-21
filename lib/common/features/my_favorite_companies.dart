// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:ccce_application/common/collections/company.dart';
import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/common/providers/app_state.dart';
import 'package:ccce_application/common/widgets/resilient_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Widget buildMyFavoriteCompaniesList(context) {
  final favoriteCompanies =
      Provider.of<AppState>(context, listen: true).favoriteCompanies?.toList() ??
          [];
  
  print("My favorite companies: ${favoriteCompanies.map((c) => c.name)}");

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

  Widget companyRow(Company company) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CompanyPopup(
                  company: company,
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
                      imageUrl: company.logo,
                      placeholderAsset: 'assets/icons/default_company.png',
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
                            company.name,
                            style: const TextStyle(
                              fontFamily: "AppFonts.sansProSemiBold",
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 12, color: AppColors.darkGoldText),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  company.location ?? '',
                                  style: const TextStyle(
                                    fontFamily: "SansSerifPro",
                                    fontSize: 11,
                                    color: AppColors.darkGoldText,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
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

  favoriteCompanies.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  return favoriteCompanies.isNotEmpty
      ? ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            sectionHeader('My Favorite Companies', italic: true),
            ...favoriteCompanies.map(companyRow).toList(),
          ],
        )
      : Center(
          child: sectionHeader("You haven't favorited any companies yet."),
        );
}

Widget buildMyFavoriteCompaniesDisplay(context) {
  return buildMyFavoriteCompaniesList(context);
}
