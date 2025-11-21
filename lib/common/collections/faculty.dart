import 'package:auto_size_text/auto_size_text.dart';
import 'package:ccce_application/common/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class Faculty implements Comparable<Faculty> {
  dynamic fname;
  dynamic lname;
  dynamic title;
  dynamic email;
  dynamic phone;
  dynamic hours;
  dynamic office;
  bool administration;
  Faculty(this.fname, this.lname, this.title, this.email, this.phone,
      this.hours, this.office, this.administration);

  @override
  int compareTo(Faculty other) {
    if (lname == null && other.lname == null) return 0;
    if (lname == null) return 1;
    if (other.lname == null) return -1;
    
    return (lname.toLowerCase().compareTo(other.lname.toLowerCase()));
  }
}

class FacultyItem extends StatelessWidget {
  final Faculty faculty;

  const FacultyItem(this.faculty, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: IntrinsicHeight(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.zero,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 6.0),
            child: Padding(
              padding: const EdgeInsets.only(left: 18.0, top: 4.0, bottom: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    faculty.fname != null && faculty.fname.toString().isNotEmpty
                        ? "${faculty.lname ?? ''}, ${faculty.fname}"
                        : faculty.lname ?? '',
                    style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                  if (faculty.title != null && faculty.title.toString().isNotEmpty)
                    Text(faculty.title ?? '',
                        style: const TextStyle(
                            color: AppColors.darkGoldText,
                            fontWeight: FontWeight.w400,
                            fontSize: 11)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FacultyPopUp extends StatefulWidget {
  final Faculty faculty;
  final VoidCallback onClose;

  const FacultyPopUp({required this.faculty, required this.onClose, Key? key})
      : super(key: key);

  @override
  State<FacultyPopUp> createState() => _FacultyPopUpState();
}

class _FacultyPopUpState extends State<FacultyPopUp> {
  String expandDayAcronyms(String hours) {
    // You can expand this map as needed
    const dayMap = {
      'M': 'Monday',
      'T': 'Tuesday',
      'W': 'Wednesday',
      'R': 'Thursday',
      'F': 'Friday',
      'S': 'Saturday',
      'U': 'Sunday',
    };

    // Replace each acronym with its full name
    String result = hours;
    dayMap.forEach((abbr, full) {
      // Use RegExp to match only standalone day letters (not inside words)
      result = result.replaceAllMapped(
        RegExp(r'\b' + abbr + r'\b'),
        (match) => full,
      );
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      backgroundColor: Colors.white,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            SizedBox(
                              height: 32,
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back, size: 20),
                                color: Colors.black,
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ),
                            Text(
                              widget.faculty.fname != null && widget.faculty.fname.toString().isNotEmpty
                                  ? '${widget.faculty.lname ?? ''}, ${widget.faculty.fname}'
                                  : widget.faculty.lname ?? '',
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const Padding(padding: EdgeInsets.only(left: 8.0)),
                      const Expanded(
                        child: Padding(padding: EdgeInsets.all(0.5)),
                      ),
                      const Padding(padding: EdgeInsets.only(right: 8.0)),
                    ],
                  ),
                  Row(children: [
                    const Padding(padding: EdgeInsets.only(left: 48.0)),
                    Expanded(
                      child: AutoSizeText(
                        widget.faculty.title ?? '',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.darkGoldText,
                            fontWeight: FontWeight.w500),
                        minFontSize: 7,
                        maxLines: 2,
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 48.0),
                        child: Text(
                          "Office: ",
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black),
                        ),
                      ),
                      const Icon(
                        Icons.location_on,
                        color: AppColors.darkGoldText,
                        size: 16,
                      ),
                      Text(
                        ' ' + (widget.faculty.office ?? 'N/A'),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.darkGoldText),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 48.0),
                        child: Text(
                          "Hours: ",
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black),
                        ),
                      ),
                      Text(
                        expandDayAcronyms(
                            (widget.faculty.hours ?? 'N/A').replaceAll(';', '\n')),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.darkGoldText),
                      ),
                    ],
                  ),
                ]),
            const SizedBox(height: 8),
            Padding(
              padding:
                  const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            color: AppColors.calPolyGreen,
                            shape: BoxShape.circle,
                          ),
                          height: 24,
                          width: 24,
                          alignment: Alignment.center,
                          child: IconButton(
                              icon: const Icon(
                                Icons.mail,
                                size: 13,
                              ),
                              padding: EdgeInsets.zero,
                              color: AppColors.lightGold,
                              onPressed: () {}),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(right: 5.0),
                        ),
                        InkWell(
                          onTap: () async {
                            final email = widget.faculty.email;
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
                          child: AutoSizeText(
                            widget.faculty.email ?? '',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.darkGoldText,
                                decoration: TextDecoration.underline),
                            minFontSize: 9,
                            maxLines: 1,
                          ),
                        ),
                        const Padding(padding: EdgeInsets.only(right: 5.0)),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            color: AppColors.calPolyGreen,
                            shape: BoxShape.circle,
                          ),
                          height: 24,
                          width: 24,
                          alignment: Alignment.center,
                          child: IconButton(
                              icon: const Icon(
                                Icons.phone,
                                size: 13,
                              ),
                              padding: EdgeInsets.zero,
                              color: AppColors.lightGold,
                              onPressed: () {}),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(right: 5.0),
                        ),
                        InkWell(
                          onTap: () async {
                            final phone = widget.faculty.phone;
                            if (phone != null && phone.isNotEmpty) {
                              final uri = Uri(scheme: 'tel', path: phone);
                              try {
                                await launchUrl(uri);
                              } catch (e) {
                                await Clipboard.setData(ClipboardData(text: phone));
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Phone number copied to clipboard')),
                                );
                              }
                            }
                          },
                          child: AutoSizeText(
                            widget.faculty.phone ?? '',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.darkGoldText,
                                decoration: TextDecoration.underline),
                            minFontSize: 9,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ]),
            ),
          ],
        ),
      ),
    );
  }
}
