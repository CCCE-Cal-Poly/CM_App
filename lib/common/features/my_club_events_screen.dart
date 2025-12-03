import 'package:ccce_application/common/collections/calevent.dart';
import 'package:ccce_application/common/providers/user_provider.dart';
import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/common/widgets/cal_poly_menu_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MyClubEventsScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  
  const MyClubEventsScreen({super.key, required this.scaffoldKey});

  @override
  State<MyClubEventsScreen> createState() => _MyClubEventsScreenState();
}

class _MyClubEventsScreenState extends State<MyClubEventsScreen> {
  bool _showUpcomingOnly = true;
  List<CalEvent> _events = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final clubIds = userProvider.clubsAdminOf;

      if (clubIds.isEmpty) {
        setState(() {
          _events = [];
          _isLoading = false;
        });
        return;
      }

      // Query all club events
      final snapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('eventType', isEqualTo: 'club')
          .get();

      // Filter events for clubs the user administers
      final events = <CalEvent>[];
      for (final doc in snapshot.docs) {
        try {
          final event = CalEvent.fromSnapshot(doc);
          final eventData = doc.data();
          final eventClubId = eventData['clubId'] as String?;
          
          if (eventClubId != null && clubIds.contains(eventClubId)) {
            events.add(event);
          }
        } catch (e) {
          debugPrint('Error parsing event ${doc.id}: $e');
        }
      }

      // Sort by start time (newest first)
      events.sort((a, b) => b.startTime.compareTo(a.startTime));

      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load events: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteEvent(CalEvent event) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Event?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.eventName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'This will permanently delete the event and cancel all scheduled notifications. This action cannot be undone.',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Show loading indicator
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Deleting event...'),
            ],
          ),
          duration: Duration(seconds: 60),
        ),
      );

      // Call Cloud Function to delete the event
      final functions = FirebaseFunctions.instance;
      final result = await functions.httpsCallable('deleteClubEvent').call({
        'eventId': event.id,
      });

      if (!mounted) return;
      
      // Hide loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (result.data['success'] == true) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Event "${event.eventName}" deleted successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Reload events
        await _loadEvents();
      } else {
        throw Exception(result.data['message'] ?? 'Unknown error');
      }
    } catch (e) {
      if (!mounted) return;
      
      // Hide loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete event: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<CalEvent> get _filteredEvents {
    if (!_showUpcomingOnly) return _events;
    
    final now = DateTime.now();
    return _events.where((event) => event.endTime.isAfter(now)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final filteredEvents = _filteredEvents;

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
          // Header with filter toggle
          Container(
            color: AppColors.calPolyGreen,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Club Events',
                  style: TextStyle(
                    color: AppColors.lightGold,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'Show Upcoming Only',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: _showUpcomingOnly,
                      onChanged: (value) {
                        setState(() {
                          _showUpcomingOnly = value;
                        });
                      },
                      activeColor: AppColors.lightGold,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Events list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.white,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadEvents,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : filteredEvents.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                _showUpcomingOnly
                                    ? 'No upcoming events'
                                    : 'No events found',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadEvents,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: filteredEvents.length,
                              itemBuilder: (context, index) {
                                final event = filteredEvents[index];
                                return _EventCard(
                                  event: event,
                                  onDelete: () => _deleteEvent(event),
                                  screenWidth: screenWidth,
                                  screenHeight: screenHeight,
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      )
    );
  }
}

class _EventCard extends StatelessWidget {
  final CalEvent event;
  final VoidCallback onDelete;
  final double screenWidth;
  final double screenHeight;

  const _EventCard({
    required this.event,
    required this.onDelete,
    required this.screenWidth,
    required this.screenHeight,
  });

  String _formatDateTime(DateTime dt) {
    return DateFormat('MMM d, yyyy • h:mm a').format(dt);
  }

  bool get _isUpcoming {
    return event.endTime.isAfter(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event logo (if available)
            if (event.logo != null && event.logo!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ClipOval(
                  child: Image.network(
                    event.logo!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.event,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Event details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.eventName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!_isUpcoming)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'PAST',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _formatDateTime(event.startTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (event.eventLocation.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.eventLocation,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Delete button
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
              tooltip: 'Delete event',
            ),
          ],
        ),
      ),
    );
  }
}
