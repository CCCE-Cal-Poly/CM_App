import 'package:ccce_application/common/providers/company_provider.dart';
import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/common/widgets/cal_poly_menu_bar.dart';
import 'package:flutter/material.dart';
import 'package:ccce_application/common/collections/company.dart';
import 'package:provider/provider.dart';

class MemberDirectory extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const MemberDirectory({super.key, required this.scaffoldKey});

  final String title = "Directory";
  @override
  State<MemberDirectory> createState() => _MemberDirectoryState();
}

class _MemberDirectoryState extends State<MemberDirectory> {
  bool _isTextEntered = false;

  static List<Company> filteredCompanies = [];

  @override
  void initState() {
    super.initState();
  }

  Map<String, bool> buttonStates = {
    'Admin': false,
    'Faculty': false,
  };

  void sortAlphabetically() {
    setState(() {
      // Implementation moved to provider
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CompanyProvider>(
        builder: (context, companyProvider, child) {
      // OutlinedButton createButtonSorter(
      //     String txt, VoidCallback sortingFunction) {
      //   bool isActive = buttonStates[txt] ?? false;
      //   return OutlinedButton(
      //     onPressed: () {
      //       setState(() {
      //         sortingFunction(); // Call your sorting function
      //         buttonStates[txt] = !isActive; // Flip the boolean
      //       });
      //     },
      //     style: OutlinedButton.styleFrom(
      //         padding: const EdgeInsets.symmetric(horizontal: 10),
      //         shape: const RoundedRectangleBorder(
      //           borderRadius: BorderRadius.zero, // Rounded corners
      //         ),
      //         textStyle: const TextStyle(fontSize: 14),
      //         side: const BorderSide(
      //             color: Colors.black, width: 1), // Border color and width
      //         minimumSize: const Size(75, 25), // Minimum size constraint
      //         backgroundColor: !isActive
      //             ? Colors.transparent
      //             : AppColors.welcomeLightYellow),
      //     child: Text(txt,
      //         style: TextStyle(
      //             fontSize: 14,
      //             color: !isActive
      //                 ? AppColors.welcomeLightYellow
      //                 : AppColors.calPolyGreen,
      //             fontWeight: FontWeight.w600)),
      //   );
      // }

      // TODO: Enable button sorters when filtering is implemented
      /* 
    OutlinedButton createButtonSorter(String txt, VoidCallback sortingFunction) {
      bool isActive = buttonStates[txt] ?? false;
      return OutlinedButton(
        onPressed: () {
          setState(() {
            sortingFunction(); // Call your sorting function
            buttonStates[txt] = !isActive; // Flip the boolean
          });
        },
        style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero, // Rounded corners
            ),
            textStyle: const TextStyle(fontSize: 14),
            side: const BorderSide(
                color: Colors.black, width: 1), // Border color and width
            minimumSize: const Size(75, 25), // Minimum size constraint
            backgroundColor: !isActive ? Colors.transparent : AppColors.welcomeLightYellow),
        child: Text(txt,
            style: TextStyle(
                fontSize: 14, color: !isActive ? AppColors.welcomeLightYellow : AppColors.calPolyGreen,
                fontWeight: FontWeight.w600)),
      );
    }
    */

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
              const Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.group,
                      color: AppColors.welcomeLightYellow, size: 24),
                  SizedBox(width: 6),
                  Text(
                    "Member Directory",
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
                            _isTextEntered = text.isNotEmpty;
                            // Clear the previously filtered companies
                            filteredCompanies.clear();

                            // Iterate through the original list of companies if text is entered
                            if (_isTextEntered) {
                              for (Company company
                                  in companyProvider.allCompanies) {
                                // Check if the company name starts with the entered text substring
                                String name = company.name;
                                if (name
                                    .toLowerCase()
                                    .startsWith(text.toLowerCase())) {
                                  // If it does, add the company to the filtered list
                                  filteredCompanies.add(company);
                                }
                              }
                            }
                          });
                        },
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                          // contentPadding: EdgeInsets.all(2.0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: const BorderSide(
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
                          hintText: 'Member Directory',
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
                    children: [
                      SizedBox(width: 6, height: 10),
                      // TODO: Re-enable button sorters when filtering is implemented and REMOVE SIZED BOX
                      // createButtonSorter('Students', () => {}),
                      // const Padding(padding: EdgeInsets.symmetric(horizontal: 6)),
                      // createButtonSorter('Alumni', () => {}),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: _isTextEntered
                      ? filteredCompanies.length
                      : companyProvider.allCompanies.length,
                  itemBuilder: (context, index) {
                    final List<Company> displayList = _isTextEntered
                        ? filteredCompanies
                        : companyProvider.allCompanies;
                    return GestureDetector(
                      onTap: () {
                        Company companyData = displayList[index];
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return CompanyPopup(
                              company: companyData,
                              onClose: () =>
                                  Navigator.pop(context), // Close popup on tap
                            );
                          },
                        );
                      },
                      child: CompanyItem(
                          displayList[index]), // Existing CompanyItem widget
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
