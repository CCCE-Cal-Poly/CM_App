import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/common/providers/app_state.dart';
import 'package:ccce_application/common/widgets/resilient_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

Widget eventLogoImage(String? url, double width, double height) {
  return ResilientCircleImage(
    imageUrl: url,
    placeholderAsset: 'assets/icons/default_company.png',
    size: width,
  );
}

class CalEvent {
  String id;
  String eventName;
  DateTime startTime;
  DateTime endTime;
  String eventLocation;
  String eventType;
  String? logo;
  String? status;
  String? companyId; 
  DateTime? updatedAt;
  InfoSessionData? isd;
  String? seriesId;      // Parent series ID if this is a recurring instance
  bool isInstance;       // True if this is a generated occurrence instance

  CalEvent({
    required this.id,
    required this.eventName,
    required this.startTime,
    required this.endTime,
    required this.eventLocation,
    required this.eventType,
    this.logo,
    this.status,
    this.companyId,
    this.updatedAt,
    this.isd,
    this.seriesId,
    this.isInstance = false,
  });

  @override
  String toString() {
    return eventName;
  }

  factory CalEvent.fromSnapshot(DocumentSnapshot doc) {
    final dataRaw = doc.data();
    if (dataRaw == null) {
      throw Exception("Document ${doc.id} has no data");
    }
    final data = dataRaw as Map<String, dynamic>;

  final eventType = data["eventType"] ?? "";
  
    if (eventType == "club") {
    final clubName = data["clubName"] ?? data["company"] ?? "";
    final eventName = data["eventName"] ?? "";
    final displayName = clubName.isNotEmpty && eventName.isNotEmpty 
        ? "$clubName - $eventName" 
        : (eventName.isNotEmpty ? eventName : clubName);
    
    final start = (data["startTime"] is Timestamp)
        ? data["startTime"].toDate()
        : DateTime.now();

    final end = (data["endTime"] is Timestamp)
        ? data["endTime"].toDate()
        : start.add(const Duration(hours: 1));
    
    final updatedAt = data["updatedAt"] is Timestamp
        ? data["updatedAt"].toDate()
        : null;

    // final recurrence = data["recurrence"] ? null

    return CalEvent(
      id: doc.id,
      eventName: displayName,
      startTime: start,
      endTime: end,
      eventLocation: data["mainLocation"] ?? data["eventLocation"] ?? "",
      eventType: eventType,
      logo: data.containsKey("logo") ? data["logo"] : null,
      status: data["Status"] ?? data["status"] ?? "pending",
      companyId: null, 
      updatedAt: updatedAt,
      isd: null,
      seriesId: data["seriesId"],
      isInstance: data["isInstance"] == true,
    );
  } else {
    // Info session - support both new (companyId) and legacy (company name) approaches
    String openPositions = data["isHiring"] == "No" ? "" : (data["position"] ?? "");
    String? theLogo = data.containsKey("logo") && data["logo"] != null && data["logo"].toString().isNotEmpty 
        ? data["logo"] 
        : null;

    final displayName = data["company"] ?? data["eventName"] ?? "";
    
    final start = (data["startTime"] is Timestamp)
        ? data["startTime"].toDate()
        : DateTime.now();

    final end = (data["endTime"] is Timestamp)
        ? data["endTime"].toDate()
        : start.add(const Duration(hours: 1));

    final updatedAt = data["updatedAt"] is Timestamp
        ? data["updatedAt"].toDate()
        : null;

    return CalEvent(
      id: doc.id,
      eventName: displayName,
      startTime: start,
      endTime: end,
      eventLocation: data["mainLocation"] ?? data["eventLocation"] ?? "",
      eventType: eventType,
      logo: theLogo,
      status: data["Status"] ?? "pending",
      companyId: data["companyId"], 
      updatedAt: updatedAt,
      isd: InfoSessionData(
        data["website"],
        data["interviewLocation"],
        data["contactName"],
        data["contactEmail"],
        openPositions,
        data["jobLocations"],
        data["interviewLink"],
      ),
      seriesId: data["seriesId"],
      isInstance: data["isInstance"] == true,
    );
  }
}

  factory CalEvent.clubEventfromMap(Map<String, dynamic> data) {
    return CalEvent(
      id: data['id'] ?? '',
      eventName: data['eventName'] ?? '',
      startTime: (data['startTime']).toDate(),
      endTime: (data['endTime']).toDate(),
      eventLocation: data['eventLocation'] ?? '',
      eventType: data['eventType'] ?? '',
      logo: data['Logo'],
      status: data['Status'] ?? 'pending',
    );
  }

  factory CalEvent.infoSessionfromMap(Map<String, dynamic> data) {
    return CalEvent(
      id: data['id'] ?? '',
      eventName: data['eventName'] ?? '',
      startTime: (data['startTime']).toDate(),
      endTime: (data['endTime']).toDate(),
      eventLocation: data['eventLocation'] ?? '',
      eventType: data['eventType'] ?? '',
      logo: data['Logo'],
      status: data['Status'] ?? 'approved',
      isd: InfoSessionData(
        data["website"],
        data["interviewLocation"],
        data["recruiterName"],
        data["recruiterEmail"],
        data["openPositions"],
        data["jobLocations"],
        data["interviewLink"],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventName': eventName,
      'startTime': startTime,
      'endTime': endTime,
      'eventLocation': eventLocation,
      'eventType': eventType,
      'logo': logo,
      'status': status,
      'isd': isd != null
          ? {
              'website': isd!.website,
              'interviewLocation': isd!.interviewLocation,
              'recruiterName': isd!.recruiterName,
              'recruiterEmail': isd!.recruiterEmail,
              'openPositions': isd!.openPositions,
              'jobLocations': isd!.jobLocations,
              'interviewLink': isd!.interviewLink,
            }
          : null,
    };
  }
}

class InfoSessionData {
  String? website = "";
  String? interviewLocation = "";
  String? recruiterName = "";
  String? recruiterEmail = "";
  String? openPositions = "";
  String? jobLocations = "";
  String? interviewLink = "";

  InfoSessionData(
    this.website,
    this.interviewLocation,
    this.recruiterName,
    this.recruiterEmail,
    this.openPositions,
    this.jobLocations,
    this.interviewLink,
  );
}

class InfoSessionItem extends StatelessWidget {
  final CalEvent infoSession;

  const InfoSessionItem(this.infoSession, {Key? key}) : super(key: key);

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
            vertical: screenHeight * .005,
            horizontal: screenWidth * 0.01,
          ),
          child: Column(
            children: [
              ListTile(
                leading: eventLogoImage(
                  infoSession.logo,
                  screenWidth * .1,
                  screenWidth * .1,
                ),
                title: AutoSizeText(
                              infoSession.eventName,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  minFontSize: 11,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InfoSessionPopUp extends StatefulWidget {
  final CalEvent infoSession;
  final VoidCallback onClose;

  const InfoSessionPopUp({
    required this.infoSession,
    required this.onClose,
    Key? key,
  }) : super(key: key);

  @override
  _InfoSessionPopUpState createState() => _InfoSessionPopUpState();
}

class _InfoSessionPopUpState extends State<InfoSessionPopUp> {
  Future<void> _copyToClipboard(String label, String value) async {
    try {
      await Clipboard.setData(ClipboardData(text: value));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copied to clipboard')));
    } catch (e) {
    }
  }

  Future<void> _launchUriOrCopy(Uri uri, String fallbackLabel) async {
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await Clipboard.setData(ClipboardData(text: uri.toString()));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$fallbackLabel copied to clipboard')));
      }
    } catch (e) {
      try {
        await Clipboard.setData(ClipboardData(text: uri.toString()));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$fallbackLabel copied to clipboard')));
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
    final hiring = (widget.infoSession.isd?.openPositions != null && widget.infoSession.isd!.openPositions!.trim().isNotEmpty);
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
                              child: eventLogoImage(
                                widget.infoSession.logo,
                                screenHeight * 0.1,
                                screenHeight * 0.1,
                              ),
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
                                widget.infoSession.eventName,
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
                              final start = widget.infoSession.startTime;
                              final end = widget.infoSession.endTime;
                              String formatTime(DateTime d) {
                                final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
                                final minute = d.minute.toString().padLeft(2, '0');
                                final ampm = d.hour < 12 ? 'AM' : 'PM';
                                return '$hour:$minute $ampm';
                              }
                              String formatDate(DateTime d) => '${d.month}/${d.day}/${d.year}';
                final when = '${formatDate(start)} • ${formatTime(start)} - ${formatTime(end)}';
                              return Column(
                                children: [
                                  Text(
                                    when,
                                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                                  ),
                                  SizedBox(height: screenHeight * 0.006),
                                  if (widget.infoSession.eventLocation.isNotEmpty)
                                    Text(
                                      widget.infoSession.eventLocation,
                                      style: const TextStyle(color: Colors.black87, fontSize: 14),
                                    ),
                                  if (widget.infoSession.eventLocation.isNotEmpty)
                                    SizedBox(height: screenHeight * 0.006),
                                  if ((widget.infoSession.isd?.website ?? '').isNotEmpty)
                                    InkWell(
                                      onTap: () {
                                        final uri = Uri.tryParse(widget.infoSession.isd!.website!);
                                        if (uri != null) _launchUriOrCopy(uri, 'Website');
                                      },
                                      onLongPress: () => _copyToClipboard('Website', widget.infoSession.isd!.website!),
                                      child: Text(
                                        widget.infoSession.isd!.website!,
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
                            Padding(
                              padding: EdgeInsets.only(top: screenHeight * 0.015),
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    if (context.read<AppState>().isCheckedIn(widget.infoSession)) {
                                      context.read<AppState>().checkOutOf(widget.infoSession);
                                    } else {
                                      context.read<AppState>().checkInto(widget.infoSession);
                                    }
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  fixedSize: Size(
                                    screenWidth * 0.5,
                                    screenHeight * 0.05,
                                  ),
                                  backgroundColor: context.watch<AppState>().isCheckedIn(widget.infoSession)
                                      ? Colors.grey
                                      : AppColors.calPolyGreen,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * .03,
                                    vertical: screenHeight * .008,
                                  ),
                                ),
                                child: context.watch<AppState>().isCheckedIn(widget.infoSession)
                                    ? const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check, color: Colors.black),
                                          SizedBox(width: 6),
                                          Text(
                                            'CHECKED IN',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Text(
                                        'CHECK IN',
                                        style: TextStyle(
                                          color: AppColors.welcomeLightYellow,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),

                            if ((widget.infoSession.isd?.interviewLink ?? '').isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: screenHeight * 0.01),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    TextButton.icon(
                                      icon: const Icon(Icons.link, size: 18),
                                      label: const Text('Open interview link'),
                                      onPressed: () async {
                                        final link = widget.infoSession.isd!.interviewLink!;
                                        final uri = Uri.tryParse(link);
                                        if (uri != null) {
                                          await _launchUriOrCopy(uri, 'Interview link');
                                        } else {
                                          // fallback: copy to clipboard
                                          await Clipboard.setData(ClipboardData(text: link));
                                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Interview link copied to clipboard')));
                                        }
                                      },
                                      onLongPress: () async {
                                        final link = widget.infoSession.isd!.interviewLink!;
                                        await Clipboard.setData(ClipboardData(text: link));
                                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Interview link copied to clipboard')));
                                      },
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: screenWidth * 0.06,
                top: screenHeight * 0.02,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hiring ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Text(
                    hiring ? 'HIRING' : 'NOT HIRING',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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
                      "Contact Information",
                      style: TextStyle(
                        color: AppColors.lightGold,
                        fontSize: 22.0,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        width: screenWidth * .85,
                        color: Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                              child: Text(
                                widget.infoSession.isd?.recruiterName ?? 'No Listed Contact Name',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if ((widget.infoSession.isd?.recruiterEmail ?? '').isNotEmpty)
                              GestureDetector(
                                onLongPress: () => _copyToClipboard('Email', widget.infoSession.isd!.recruiterEmail!),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: () => _openEmailOrCopy(widget.infoSession.isd!.recruiterEmail!),
                                          child: Text(
                                            widget.infoSession.isd!.recruiterEmail!,
                                            style: const TextStyle(
                                              color: AppColors.darkGoldText,
                                              fontWeight: FontWeight.w400,
                                              fontSize: 13,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.email_outlined),
                                        onPressed: () => _openEmailOrCopy(widget.infoSession.isd!.recruiterEmail!),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.copy, size: 18),
                                        onPressed: () => _copyToClipboard('Email', widget.infoSession.isd!.recruiterEmail!),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 4),
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
                      final raw = widget.infoSession.isd?.openPositions ?? '';
                      final items = raw.split('|').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                      if (items.isEmpty) {
                        return const Text('No Position Info', style: TextStyle(color: Colors.white, fontSize: 14.0));
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: items.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Text(p, style: const TextStyle(color: Colors.white, fontSize: 14.0)),
                        )).toList(),
                      );
                    }),
                    const SizedBox(height: 4),
                    const Divider(),
                    const SizedBox(height: 4),
                    Builder(builder: (_) {
                      final rawLoc = widget.infoSession.isd?.jobLocations ?? '';
                      final locs = rawLoc.split('|').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                      if (locs.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Location(s)', style: TextStyle(color: AppColors.lightGold, fontSize: 18.0, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 6),
                          ...locs.map((l) => Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Text(l, style: const TextStyle(color: Colors.white, fontSize: 14.0)),
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