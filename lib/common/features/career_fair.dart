import 'package:auto_size_text/auto_size_text.dart';
import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/common/widgets/cal_poly_menu_bar.dart';
import 'package:ccce_application/common/widgets/resilient_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ccce_application/services/error_logger.dart';
import 'package:url_launcher/url_launcher.dart';

class CareerFairDirectory extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const CareerFairDirectory({super.key, required this.scaffoldKey});

  final String title = "Directory";
  @override
  State<CareerFairDirectory> createState() => _CareerFairDirectoryState();
}

class CareerFairCompany implements Comparable<CareerFairCompany> {
  final String id;
  final String company;
  final String? website;
  final String industrySector;
  final String? positionsAvailable;
  final String? hiringLocations;
  final String? logo;
  final String days;
  final bool useAlternativeDisplay;
  
  CareerFairCompany({
    required this.id,
    required this.company, 
    required this.industrySector,
    this.positionsAvailable,
    this.hiringLocations,
    this.website, 
    this.logo,
    required this.days,
    required this.useAlternativeDisplay
  }); 

  factory CareerFairCompany.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    String? optionalString(String key) {
      final value = data[key];
      if (value == null) return null;
      final text = value.toString().trim();
      return text.isEmpty ? null : text;
    }

    return CareerFairCompany(
      id: doc.id,
      // Keep the misspelled key as a fallback for older Firestore documents.
      company: optionalString('company') ??
          optionalString('comapny') ??
          'Unknown Company',
      website: optionalString('website'),
      industrySector:
          optionalString('industrySector') ?? 'Unspecified Industry',
      positionsAvailable: optionalString('positionsAvailable'),
      hiringLocations: optionalString('hiringLocations'),
      logo: optionalString('Logo') ?? optionalString('logo'),
      useAlternativeDisplay: data['useAlternativeDisplay'] == true,
      days: optionalString('days') ?? 'No date given',
    );
  }


  @override
  int compareTo(CareerFairCompany other) {
    return (company.toLowerCase().compareTo(other.company.toLowerCase()));
  }
}

class CareerFairCompanyItem extends StatelessWidget {
  Widget memberLogoImage(String? url, BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return ResilientImage(
      imageUrl: url,
      placeholderAsset: 'assets/icons/default_company.png',
      fit: BoxFit.contain,
      height: screenWidth * .15,
    );
  }

  final CareerFairCompany member;

  const CareerFairCompanyItem (this.member, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    if (member.useAlternativeDisplay) {
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
    } else {
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
              vertical: screenHeight * .005,
              horizontal: screenWidth * 0.01,
            ),
            child: Column(
              children: [
                ListTile(
                  leading: ResilientCircleImage(imageUrl: member.logo, placeholderAsset: 'assets/icons/default_company.png', size: screenWidth * 0.1),
                  title: AutoSizeText(
                    member.company,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    minFontSize: 11,
                    maxLines: 2,
                  ),
                  subtitle: AutoSizeText(
                    member.industrySector,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 11.0,
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                    minFontSize: 9,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

  }
}

class _CareerFairDirectoryState extends State<CareerFairDirectory> {
  String _searchQuery = '';
  bool _isLoading = true;
  List<CareerFairCompany> companyList = [];
  Map<String, bool> sectorButtonStates = {};

  Future<List<CareerFairCompany>> fetchDataFromFirestore() async {
    final List<CareerFairCompany> companies = [];

    try {
      // Get a reference to the Firestore database
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      ErrorLogger.logInfo('Career Fair', 'Fetching companies from Firestore');
      
      final QuerySnapshot querySnapshot =
          await firestore.collection('careerFairCompanies').get();
      ErrorLogger.logInfo('Career Fair', 'Fetched ${querySnapshot.size} companies from Firestore');
      for (final doc in querySnapshot.docs) {
        companies.add(CareerFairCompany.fromDocument(doc));
      }
    } catch (e) {
      // Handle any errors that occur
      ErrorLogger.logError('SponsorsDirectory', 'Error fetching data', error: e);
    }

    return companies;
  }

  @override
  void initState() {
    super.initState();

    fetchDataFromFirestore().then((companyData) {
      if (!mounted) return;

      companyData.sort();
      final sectors = companyData
          .map((company) => company.industrySector)
          .toSet()
          .toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      setState(() {
        companyList = companyData;
        sectorButtonStates = {for (final sector in sectors) sector: false};
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    OutlinedButton createSectorButton(String sector) {
      final bool isActive = sectorButtonStates[sector] ?? false;
      return OutlinedButton(
        onPressed: () {
          setState(() {
            sectorButtonStates[sector] = !isActive;
          });
        },
        style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero, // Rounded corners
            ),
            textStyle: const TextStyle(fontSize: 13),
            side: const BorderSide(
                color: Colors.black, width: 1), // Border color and width
            minimumSize: const Size(75, 25), // Minimum size constraint
            backgroundColor: !isActive ? Colors.transparent : AppColors.welcomeLightYellow),
        child: Text(sector,
            style: TextStyle(
                fontSize: 14, color: !isActive ? AppColors.welcomeLightYellow : AppColors.calPolyGreen,
                fontWeight: FontWeight.w600)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.calPolyGreen,
      body: Padding(
        padding: const EdgeInsets.only(right: 16.0, left: 16.0, top: 16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: CalPolyMenuBar(scaffoldKey: widget.scaffoldKey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Image.asset(
                  'assets/icons/default_company.png', // CHANGE THIS LATER TO COMPANY ICON
                  color: AppColors.welcomeLightYellow,
                  width: 26,
                  height: 28,
                ),
                const SizedBox(width: 6),
                const Text(
                  "Career Fair Directory",
                  style: TextStyle(
                    fontFamily: AppFonts.sansProSemiBold,
                    fontSize: 21,
                    color: AppColors.welcomeLightYellow,
                  ),
                ),
              ],
            ),
            Padding(
              padding:
                  const EdgeInsets.only(left: 16.0, top: 12.0, right: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      //controller: _searchController,
                      onChanged: (text) {
                        setState(() {
                          _searchQuery = text.trim().toLowerCase();
                        });
                      },
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        // contentPadding: EdgeInsets.all(2.0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(
                            color: Colors.black,
                            width: 2.0,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(
                            color: Colors.black,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(
                            color: Colors.black,
                          ),
                        ),
                        hintText: 'Search companies',
                        // border: OutlineInputBorder(
                        //   borderRadius: BorderRadius.circular(10.0),
                        // ),
                        fillColor: Colors.white,
                        filled: true,
                        // Add Container with colored background for the button
                      ),
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 20, right: 20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: sectorButtonStates.keys
                      .map(
                        (sector) => Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: createSectorButton(sector),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (_isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.welcomeLightYellow,
                      ),
                    );
                  }

                  final selectedSectors = sectorButtonStates.entries
                      .where((entry) => entry.value)
                      .map((entry) => entry.key)
                      .toSet();

                  final displayList = companyList.where((company) {
                    final matchesSearch = _searchQuery.isEmpty ||
                        company.company.toLowerCase().contains(_searchQuery);
                    final matchesSector = selectedSectors.isEmpty ||
                        selectedSectors.contains(company.industrySector);
                    return matchesSearch && matchesSector;
                  }).toList();

                  final List<Widget> sectionedList = [];

                  for (final sector in sectorButtonStates.keys) {
                    final companiesInSector = displayList
                        .where((company) => company.industrySector == sector)
                        .toList();
                    _addSectorSection(
                      sector,
                      companiesInSector,
                      context,
                      sectionedList,
                    );
                  }

                  if (sectionedList.isEmpty) {
                    sectionedList.add(
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No companies match the selected filters.',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  }

                  return ListView(
                    children: sectionedList,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addSectorSection(
    String sector,
    List<CareerFairCompany> companies,
    BuildContext context,
    List<Widget> sectionedList,
  ) {
    if (companies.isEmpty) return;

    sectionedList.add(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Text(
          sector,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: AppColors.welcomeLightYellow,
          ),
        ),
      ),
    );

    sectionedList.addAll(
      companies.map(
        (company) => GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return CareerFairCompanyPopUp(
                  company: company,
                  onClose: () => Navigator.pop(context),
                );
              },
            );
          },
          child: CareerFairCompanyItem(company),
        ),
      ),
    );
  }


}








class CareerFairCompanyPopUp extends StatefulWidget {
  final CareerFairCompany company;
  final VoidCallback onClose;

  const CareerFairCompanyPopUp({
    required this.company,
    required this.onClose,
    Key? key,
  }) : super(key: key);

  @override
  _CareerFairCompanyPopUpState createState() => _CareerFairCompanyPopUpState();
}

class _CareerFairCompanyPopUpState extends State<CareerFairCompanyPopUp> {
  Future<void> _copyToClipboard(String label, String value) async {
    try {
      await Clipboard.setData(ClipboardData(text: value));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$label copied to clipboard')));
    } catch (e) {}
  }

  Future<void> _launchUriOrCopy(Uri uri, String fallbackLabel) async {
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await Clipboard.setData(ClipboardData(text: uri.toString()));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$fallbackLabel copied to clipboard')));
      }
    } catch (e) {
      try {
        await Clipboard.setData(ClipboardData(text: uri.toString()));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$fallbackLabel copied to clipboard')));
      } catch (_) {}
    }
  }

  Future<void> _openEmailOrCopy(String email) async {
    final mailUri = Uri(scheme: 'mailto', path: email);
    await _launchUriOrCopy(mailUri, 'Email');
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
                      Padding(
                        padding: EdgeInsets.only(
                          left: screenWidth * .02,
                          top: screenHeight * .012,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              height: screenHeight * .03,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.black,
                                ),
                                onPressed: widget.onClose,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(screenWidth * 0.015),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: screenHeight * 0.14,
                              height: screenHeight * 0.14,
                              child: ResilientCircleImage(imageUrl: widget.company.logo, placeholderAsset: 'assets/icons/default_company.png', size: screenWidth * 0.1)
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(screenHeight * 0.015),
                        child: Column(
                          children: [
                            SizedBox(
                              width: screenWidth * 0.7,
                              child: AutoSizeText(
                                widget.company.company,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                                minFontSize: 16,
                                maxLines: 2,
                              ),
                            ),
                            SizedBox(height: screenHeight * .0015),
                            // Show event time (start - end)
                            Builder(builder: (context) {
                              

                            
              
                              return Column(
                                children: [
                                  Text(
                                    widget.company.days,
                                    style: const TextStyle(
                                        color: Colors.black87, fontSize: 14),
                                  ),
                                  SizedBox(height: screenHeight * 0.006),
                                  if ((widget.company.website ?? '')
                                      .isNotEmpty)
                                    InkWell(
                                      onTap: () {
                                        final uri = Uri.tryParse(
                                            widget.company.website!);
                                        if (uri != null)
                                          _launchUriOrCopy(uri, 'Website');
                                      },
                                      onLongPress: () => _copyToClipboard(
                                          'Website',
                                          widget.company.website!),
                                      child: Text(
                                        widget.company.website!,
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                          fontWeight: FontWeight.w400,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Container(
            color: AppColors.calPolyGreen,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Positions Available",
                      style: TextStyle(
                        color: AppColors.lightGold,
                        fontSize: 22.0,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Builder(builder: (_) {
                      final raw = widget.company.positionsAvailable ?? '';
                      final items = raw
                          .split('|')
                          .map((s) => s.trim())
                          .where((s) => s.isNotEmpty)
                          .toList();
                      if (items.isEmpty) {
                        return const Text('No Position Info',
                            style:
                                TextStyle(color: Colors.white, fontSize: 14.0));
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: items
                            .map((p) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6.0),
                                  child: Text(p,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 14.0)),
                                ))
                            .toList(),
                      );
                    }),
                    const SizedBox(height: 4),
                    const Divider(),
                    const SizedBox(height: 4),
                    Builder(builder: (_) {
                      final rawLoc = widget.company.hiringLocations ?? '';
                      final locs = rawLoc
                          .split('|')
                          .map((s) => s.trim())
                          .where((s) => s.isNotEmpty)
                          .toList();
                      if (locs.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Location(s)',
                              style: TextStyle(
                                  color: AppColors.lightGold,
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 6),
                          ...locs.map((l) => Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Text(l,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 14.0)),
                              )),
                        ],
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
