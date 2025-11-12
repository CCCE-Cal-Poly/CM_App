import 'package:auto_size_text/auto_size_text.dart';
import 'package:ccce_application/common/collections/favoritable.dart';
import 'package:ccce_application/common/collections/job.dart';
import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/common/providers/app_state.dart';
import 'package:ccce_application/common/widgets/resilient_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class Company extends Favoritable implements Comparable<Company> {
  String? id;
  dynamic name;
  dynamic location;
  dynamic aboutMsg;
  dynamic msg;
  dynamic recruiterName;
  dynamic recruiterTitle;
  dynamic recruiterEmail;
  String? logo;
  Set<Job> offeredJobs;

  Company({
      this.id,
      this.name, 
      this.location, 
      this.aboutMsg, 
      this.msg, 
      this.recruiterName,
      this.recruiterTitle, 
      this.recruiterEmail, 
      this.logo, 
      required this.offeredJobs});

  @override
  int compareTo(Company other) {
    return (name.toLowerCase().compareTo(other.name.toLowerCase()));
  }

  factory Company.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Company(
      id: doc.id,
      name: data['name'] ?? '',
      location: data['location'] ?? '',
      aboutMsg: data['about'] ?? '',
      msg: data['msg'] ?? '',
      recruiterName: data['recruiterName'] ?? '',
      recruiterTitle: data['recruiterTitle'] ?? '',
      recruiterEmail: data['recruiterEmail'] ?? '',
      logo: data['logo'] ?? '',
      offeredJobs: {}
    );
  }
}

class CompanyItem extends StatelessWidget {
  final Company company;

  const CompanyItem(this.company, {Key? key}) : super(key: key);

  Widget clubLogoImage(String? url, double width, double height) {
    return ResilientCircleImage(
      imageUrl: url,
      placeholderAsset: 'assets/icons/default_company.png',
      size: width,
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.zero,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 2), // changes position of shadow
            ),
          ],
        ),
        child: Column(
          children: [
            ListTile(
              leading: Container(
                width: screenWidth * .11,
                height: screenWidth * .11,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    border: Border.fromBorderSide(
                      BorderSide(color: Colors.black, width: .5),
                    )),
                child: Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: ClipOval(
                    child: clubLogoImage(
                        company.logo, screenWidth * .09, screenWidth * .09),
                  ),
                ),
              ),
              title: AutoSizeText(
                company.name,
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
                minFontSize: 12,
                maxLines: 1,
              ),
              subtitle: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on,
                      color: AppColors.lightGold, size: 16),
                  const SizedBox(width: 2),
                  AutoSizeText(
                    company.location,
                    style: const TextStyle(
                        color: AppColors.lightGold,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                    minFontSize: 10,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CompanyPopup extends StatefulWidget {
  final Company company;
  final VoidCallback onClose;

  const CompanyPopup({required this.company, required this.onClose, Key? key})
      : super(key: key);

  @override
  State<CompanyPopup> createState() => _CompanyPopupState();
}

class _CompanyPopupState extends State<CompanyPopup> {
  String getRecName() {
    return widget.company.recruiterName;
  }

  Widget clubLogoImage(String? url, double width, double height) {
    return ResilientCircleImage(
      imageUrl: url,
      placeholderAsset: 'assets/icons/default_company.png',
      size: width,
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: AppColors.calPolyGreen,
      body: ListView(
        children: [
          Stack(
            children: [
              Center(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Close button with arrow
                      Padding(
                        padding: EdgeInsets.all(screenHeight * 0.01),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back,
                                  color: Colors.black),
                              onPressed: widget.onClose,
                            ),
                          ],
                        ),
                      ),
                      // Circle near the top of the page in the middle
                      Padding(
                        padding: EdgeInsets.all(screenHeight * 0.01),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: screenHeight * .1,
                              height: screenHeight * .1,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border:
                                    Border.all(color: Colors.black, width: 1),
                              ),
                              child: Center(
                                child: clubLogoImage(widget.company.logo,
                                    screenWidth * .1, screenWidth * .1),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Company details
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              widget.company.name,
                              style: const TextStyle(
                                fontSize: 24.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              widget.company.location,
                              style: const TextStyle(
                                fontSize: 16.0,
                                color: AppColors.darkGoldText,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: SizedBox(
                                width: screenWidth * .5,
                                height: screenHeight * .05,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: context
                                            .watch<AppState>()
                                            .isFavorite(widget.company)
                                        ? Colors.grey
                                        : AppColors.calPolyGreen,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.zero,
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: () {
                                    if (context
                                        .read<AppState>()
                                        .isFavorite(widget.company)) {
                                      context
                                          .read<AppState>()
                                          .removeFavorite(widget.company);
                                    } else {
                                      context
                                          .read<AppState>()
                                          .addFavorite(widget.company);
                                    }
                                  },
                                  child: context
                                          .watch<AppState>()
                                          .isFavorite(widget.company)
                                      ? const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.check,
                                                color: Colors.black, size: 18),
                                            SizedBox(width: 6),
                                            AutoSizeText(
                                              "ADDED",
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontFamily:
                                                    AppFonts.sansProSemiBold,
                                                fontSize: 16.0,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              minFontSize: 10,
                                              maxLines: 1,
                                            ),
                                          ],
                                        )
                                      : const AutoSizeText(
                                          "ADD TO FAVORITES",
                                          style: TextStyle(
                                            color: AppColors.welcomeLightYellow,
                                            fontFamily:
                                                AppFonts.sansProSemiBold,
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.w400,
                                          ),
                                          minFontSize: 10,
                                          maxLines: 1,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Bottom section with text
          Container(
            color: AppColors.calPolyGreen,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      bottom: 12.0, top: 8, left: 8, right: 8),
                  child: Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.zero,
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey,
                                child: Icon(
                                  Icons.person,
                                  size: 32,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 64,
                          color: AppColors.calPolyGreen,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AutoSizeText(
                                widget.company.recruiterName,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.w600,
                                ),
                                minFontSize: 14,
                                maxLines: 1,
                              ),
                              AutoSizeText(
                                widget.company.recruiterTitle,
                                style: const TextStyle(
                                  color: AppColors.darkGoldText,
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w400,
                                ),
                                minFontSize: 8,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: InkWell(
                    onTap: () async {
                      final email = widget.company.recruiterEmail;
                      if (email != null && email.isNotEmpty) {
                        final uri = Uri(scheme: 'mailto', path: email);
                        try {
                          await launchUrl(uri);
                        } catch (e) {
                          await Clipboard.setData(ClipboardData(text: email));
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Email copied to clipboard')),
                          );
                        }
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.mail,
                            size: 24,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: AutoSizeText(
                              widget.company.recruiterEmail ?? 'No Email',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18.0,
                                decoration: TextDecoration.underline,
                              ),
                              minFontSize: 11,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Divider(
                  color: Colors.white,
                  thickness: 1.1,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "About",
                        style: TextStyle(
                          color: AppColors.lightGold,
                          fontSize: 22.0,
                          fontWeight: FontWeight.w400,
                          fontFamily: AppFonts.sansProSemiBold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.company.aboutMsg,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  color: Colors.white,
                  thickness: 1.1,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Message",
                        style: TextStyle(
                          color: AppColors.lightGold,
                          fontSize: 22.0,
                          fontWeight: FontWeight.w400,
                          fontFamily: AppFonts.sansProSemiBold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.company.msg,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.company.offeredJobs.isNotEmpty) ...[
                const Divider(
                  color: Colors.white,
                  thickness: 1.1,
                ),
                // Third Section (Message)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0, bottom: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Job List",
                        style: TextStyle(
                          color: AppColors.lightGold,
                          fontSize: 22.0,
                          fontWeight: FontWeight.w400,
                          fontFamily: AppFonts.sansProSemiBold,
                        ),
                      ),
                    ],
                  ),
                ), 
                ...(widget.company.offeredJobs.map((job) => buildItemButton(job)).toList())
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget buildItemButton(Job job) {
    return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white, // button background
        foregroundColor: AppColors.calPolyGreen, // text color
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // pill shape
        ),
      ),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => JobPopUp(job: job, onClose: () {Navigator.of(context).pop();}),
          ),
        );
      },
      child: Text(job.title),
    ),
  );
  }
}
