import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:appwrite/models.dart' as models;
import '../services/distribution_service.dart';
import 'admin_scan_page.dart';

class AdminDistributionTab extends StatefulWidget {
  final String adminId;
  final String adminName;

  const AdminDistributionTab(
      {super.key, required this.adminId, required this.adminName});

  @override
  State<AdminDistributionTab> createState() => _AdminDistributionTabState();
}

class _AdminDistributionTabState extends State<AdminDistributionTab> {
  List<models.Document> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    setState(() => _loading = true);
    try {
      final events =
          await DistributionService.getAdminActiveEvents(widget.adminId);
      if (mounted) setState(() => _events = events);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF6A8A73)));
    }

    if (_events.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              "No active events assigned",
              style: GoogleFonts.poppins(
                  color: Colors.grey.shade500, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              "The Super Admin will assign you to distribution events",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  color: Colors.grey.shade400, fontSize: 12),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: _fetchEvents,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text("Refresh"),
              style:
                  TextButton.styleFrom(foregroundColor: const Color(0xFF6A8A73)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF6A8A73),
      onRefresh: _fetchEvents,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        itemCount: _events.length,
        itemBuilder: (ctx, i) => _EventCard(
          event: _events[i],
          adminId: widget.adminId,
          adminName: widget.adminName,
        ),
      ),
    );
  }
}

// =============================================================================
// Event card for admin
// =============================================================================

class _EventCard extends StatelessWidget {
  final models.Document event;
  final String adminId;
  final String adminName;

  const _EventCard(
      {required this.event, required this.adminId, required this.adminName});

  @override
  Widget build(BuildContext context) {
    final d = event.data;
    final issued = d['issuedCount'] as int? ?? 0;
    final total = d['totalRecipients'] as int? ?? 0;
    final date = d['scheduledDate'] != null
        ? DateFormat('MMM dd, yyyy')
            .format(DateTime.parse(d['scheduledDate'] as String))
        : '—';
    final progress = total > 0 ? issued / total : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF388E3C),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "ACTIVE",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF388E3C),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  d['title'] as String? ?? 'Untitled Event',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 13, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(date,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.grey.shade500)),
                    if ((d['location'] as String? ?? '').isNotEmpty) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          d['location'] as String? ?? '',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.grey.shade500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Issued",
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.grey.shade500)),
                    Text("$issued / $total",
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF388E3C))),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade200,
                    color: const Color(0xFF6A8A73),
                    minHeight: 7,
                  ),
                ),
              ],
            ),
          ),

          // Scan button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminScanPage(
                      eventId: event.$id,
                      eventTitle: d['title'] as String? ?? 'Event',
                      adminId: adminId,
                    ),
                  ),
                ),
                icon: const Icon(Icons.qr_code_scanner, size: 20),
                label: Text("Start Scanning",
                    style:
                        GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A8A73),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
