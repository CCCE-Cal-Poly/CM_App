import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/common/collections/conference_session.dart';
import 'package:ccce_application/common/providers/conference_provider.dart';
import 'package:ccce_application/common/widgets/cal_poly_menu_bar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class Asc2026Screen extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const Asc2026Screen({super.key, required this.scaffoldKey});

  Future<void> _openPresentation(
      BuildContext context, ConferenceSession session) async {
    final provider = Provider.of<ConferenceProvider>(context, listen: false);
    try {
      final url = await provider.getPresentationLaunchUrl(session);
      if (url == null || url.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'No presentation file available for #${session.sessionNumber}.')),
        );
        return;
      }

      final ok =
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Unable to open the presentation file.')),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Unable to load the presentation file right now.')),
      );
    }
  }

  Future<void> _openPaper(
      BuildContext context, ConferenceSession session) async {
    final provider = Provider.of<ConferenceProvider>(context, listen: false);
    try {
      final url = await provider.getPaperLaunchUrl(session);
      if (url == null || url.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'No paper file available for #${session.sessionNumber}.')),
        );
        return;
      }

      final ok =
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open the paper file.')),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Unable to load the paper file right now.')),
      );
    }
  }

  Widget _statusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'SansSerifProSemiBold',
          fontSize: 11,
          color: Colors.white,
        ),
      ),
    );
  }

  Color _presentationStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'uploaded':
        return AppColors.calPolyGreen;
      case 'pending_author':
        return Colors.orange.shade700;
      case 'not_attending':
        return Colors.red.shade700;
      case 'missing':
      default:
        return Colors.red.shade600;
    }
  }

  Color _paperStatusColor(String status) {
    return status.toLowerCase() == 'uploaded'
        ? AppColors.calPolyGreen
        : Colors.orange.shade700;
  }

  Widget _sessionCard(BuildContext context, ConferenceSession session) {
    final timeLabel =
        '${DateFormat('h:mm a').format(session.startTime)} - ${DateFormat('h:mm a').format(session.endTime)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '#${session.sessionNumber} ${session.title}',
            style: const TextStyle(
              fontFamily: 'SansSerifProSemiBold',
              fontSize: 16,
              color: AppColors.calPolyGreen,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$timeLabel  |  ${session.location}',
            style: const TextStyle(
              fontFamily: 'SansSerifPro',
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
          if (session.moderators.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Moderator: ${session.moderators.join(', ')}',
              style: const TextStyle(
                fontFamily: 'SansSerifPro',
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ],
          if (session.notes != null && session.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              session.notes!,
              style: TextStyle(
                fontFamily: 'SansSerifProItalic',
                fontSize: 12,
                color: Colors.grey.shade800,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _statusChip('Slides: ${session.presentationStatus}',
                  _presentationStatusColor(session.presentationStatus)),
              _statusChip('Paper: ${session.paperStatus}',
                  _paperStatusColor(session.paperStatus)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: session.hasPresentationAsset
                      ? () => _openPresentation(context, session)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightGold,
                    foregroundColor: Colors.black,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero),
                  ),
                  child: const Text('Open Slides'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: session.hasPaperAsset
                      ? () => _openPaper(context, session)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightGold,
                    foregroundColor: Colors.black,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero),
                  ),
                  child: const Text('Open Paper'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAgenda(BuildContext context, ConferenceProvider provider) {
    if (!provider.isLoaded) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (provider.errorMessage != null && provider.sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'SansSerifPro',
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => provider.fetchSessions(forceServer: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (provider.sessions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'No ASC 2026 sessions are published yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'SansSerifPro',
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    final grouped = <DateTime, List<ConferenceSession>>{};
    for (final session in provider.sessions) {
      final key = DateTime(session.startTime.year, session.startTime.month,
          session.startTime.day);
      grouped.putIfAbsent(key, () => <ConferenceSession>[]).add(session);
    }

    final dayKeys = grouped.keys.toList()..sort((a, b) => a.compareTo(b));
    final missingSessionNumbers = provider.sessions
        .where((session) => session.isPresentationMissing)
        .map((session) => session.sessionNumber)
        .where((number) => number > 0)
        .toList();

    return RefreshIndicator(
      onRefresh: () => provider.fetchSessions(forceServer: true),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 14),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Conference Hub',
                  style: TextStyle(
                    fontFamily: 'SansSerifProSemiBold',
                    fontSize: 20,
                    color: AppColors.calPolyGreen,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${provider.sessions.length} sessions loaded',
                  style: const TextStyle(
                    fontFamily: 'SansSerifPro',
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${provider.missingPresentationCount} presentations need follow-up',
                  style: const TextStyle(
                    fontFamily: 'SansSerifPro',
                    fontSize: 14,
                  ),
                ),
                if (missingSessionNumbers.isNotEmpty)
                  Text(
                    'Missing/pending IDs: ${missingSessionNumbers.join(', ')}',
                    style: TextStyle(
                      fontFamily: 'SansSerifPro',
                      fontSize: 13,
                      color: Colors.orange.shade900,
                    ),
                  ),
              ],
            ),
          ),
          for (final day in dayKeys) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                DateFormat('EEEE, MMM d').format(day),
                style: const TextStyle(
                  fontFamily: 'SansSerifProSemiBold',
                  fontSize: 18,
                  color: AppColors.tanText,
                ),
              ),
            ),
            for (final session in grouped[day]!) _sessionCard(context, session),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      color: AppColors.calPolyGreen,
      child: SafeArea(
        child: Column(
          children: [
            CalPolyMenuBar(scaffoldKey: scaffoldKey),
            Expanded(
              child: Column(
                children: [
                  SizedBox(height: screenHeight * 0.02),
                  const Text(
                    'ASC 2026',
                    style: TextStyle(
                      fontFamily: 'SansSerifProSemiBold',
                      fontSize: 30,
                      color: AppColors.tanText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Agenda, Moderators, Slides, and Papers',
                    style: TextStyle(
                      fontFamily: 'SansSerifPro',
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Consumer<ConferenceProvider>(
                      builder: (context, provider, _) =>
                          _buildAgenda(context, provider),
                    ),
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
