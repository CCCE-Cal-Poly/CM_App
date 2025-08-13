import 'package:ccce_application/common/collections/company.dart';
import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/common/widgets/cal_poly_menu_bar.dart';
import 'package:ccce_application/common/widgets/debug_outline.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:ccce_application/common/collections/job.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JobBoard extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const JobBoard({super.key, required this.scaffoldKey});

  final String title = "Directory";
  @override
  State<JobBoard> createState() => _JobBoardState();
}

  final Company exampleComp = Company(
  name: 'CCCE',
  location: 'San Luis Obispo, CA',
  aboutMsg: 'We are CCCE.',
  msg: 'Excited to connect with talented individuals!',
  recruiterName: 'Jeong Woo',
  recruiterTitle: 'Bossman',
  recruiterEmail: 'jeong.woo@CCCE.com',
  logo: 'https://example.com/logo.png',
  offeredJobs: {},
);

class _JobBoardState extends State<JobBoard> {
  

  final TextEditingController _searchController = TextEditingController();
  bool _isTextEntered = false;

  static List<Job> jobList = [];
  static List<Job> filteredJobs = [];

  final Job testJob = Job(
    id: 'job001',
    company: exampleComp,
    title: 'Marketing Intern - Fall 2025',
    description: '''Join our dynamic marketing team this fall to assist with campaign development, social media engagement, and customer outreach strategies. You'll collaborate with senior strategists, conduct competitor research, and help design promotional content. Ideal candidates are enthusiastic, creative, and eager to learn. Some experience with Canva, Excel, or Adobe tools is preferred but not required. This is a hybrid position based in San Luis Obispo.''',
    contactName: 'Emily Rivera',
    contactEmail: 'emily.rivera@company.com',
    contactPhone: '+1 (805) 555-1234',
    contactTitle: 'Professional Manager Dude',
    location: 'San Francisco'
  );

  @override
  void initState() {
    super.initState();

    fetchDataFromFirestore().then((jobData) {
      setState(() {
        jobList.add(testJob);
        jobList.sort();
      });
    });

    // Fetch company data from a source (e.g., API call, database)
    // and populate the companies list
  }
  
  void addJobtoCompany(Job job, Company comp){
    comp.offeredJobs.add(job);
  }

  Map<String, bool> buttonStates = {
  'Internship': false,
  'Full Time': false,
  'Part Time': false,
  };

  @override
  Widget build(BuildContext context) {
    addJobtoCompany(testJob, exampleComp);
    void sortAlphabetically() {
      setState(() {
        jobList = jobList.reversed.toList();
      });
    }

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
            padding: const EdgeInsets.symmetric(horizontal: 8),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero, // Rounded corners
            ),
            textStyle: const TextStyle(fontSize: 12),
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
              children: [
                Icon(Icons.share, color: AppColors.welcomeLightYellow
                ),
                SizedBox(width: 6),
                Text(
                  "Job Board",
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
                          filteredJobs.clear();

                          // Iterate through the original list of companies if text is entered
                          if (_isTextEntered) {
                            for (Job job in jobList) {
                              // Check if the company name starts with the entered text substring
                              String name = job.title;
                              if (name
                                  .toLowerCase()
                                  .startsWith(text.toLowerCase())) {
                                // If it does, add the company to the filtered list
                                filteredJobs.add(job);
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
                        hintText: 'Job Board',
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
                    createButtonSorter('Internship', sortAlphabetically),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 6)),
                    createButtonSorter('Full Time', () => {}),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 6)),
                    createButtonSorter('Part Time', () => {}),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  final List<Job> displayList =
                      _isTextEntered ? filteredJobs : jobList;

                  // Split into admin and job
                  final List<Job> partTimeList =
                      displayList.where((j) => j.partTime).toList();
                  final List<Job> fullTimeList =
                      displayList.where((j) => !j.partTime).toList();

                  // Combine with section headers
                  final List<Widget> sectionedList = [];

      // Full Time section
      (!(buttonStates['Part Time']!) || (buttonStates['Part Time']!&&buttonStates['Full Time']!)) ? (sectionedList.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Text(
            "Full Time",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: AppColors.welcomeLightYellow,
            ),
          ),
        ),
      )) : null;
      if (!(buttonStates['Part Time']!) || (buttonStates['Part Time']!&&buttonStates['Full Time']!)) {
        if (fullTimeList.isEmpty) {
          sectionedList.add(
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Text("None", style: TextStyle(color: Colors.grey)),
            ),
          );
        }
        else{
        sectionedList.addAll(
          fullTimeList.map((j) => GestureDetector(
            onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return JobPopUp(
              job: j, 
              onClose: () => Navigator.of(context).pop(),
              );
          }
        );
      },
      child: JobItem(j),
    )).toList(),
          );
      }
      }
      else{
        const SizedBox(height: 10);
      }

      // Part Time section

      (!(buttonStates['Full Time']!) || (buttonStates['Part Time']!&&buttonStates['Full Time']!)) ? (sectionedList.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Text(
            "Part Time",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: AppColors.welcomeLightYellow,
            ),
          ),
        ),
      )) : null;
      if (!(buttonStates['Full Time']!) || (buttonStates['Part Time']! && buttonStates['Full Time']!)){
        if (partTimeList.isEmpty) {
        sectionedList.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Text("None", style: TextStyle(color: Colors.grey)),
          ),
        );
      } 
      else {
        sectionedList.addAll(
          partTimeList.map((j) => GestureDetector(
            onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return JobPopUp(
              job: j, 
              onClose: () => Navigator.of(context).pop(),
              );
          },
        );
      },
      child: JobItem(j),
    )).toList(),
          );
      }
      }
      else{
        const SizedBox(height: 10);
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
  
  Future<List<Job>> fetchDataFromFirestore() async {
    List<Job> jobList = [];
    return jobList;
  }
}