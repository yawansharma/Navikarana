import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'app_theme.dart';

// =============================================================================
// AdminL2SupervisionPage
// Read-only dashboard shown to Admin Level 2 when they tap "Enter Supervision
// Mode" on one of their Level 3 admins.
//
// What L2 CAN do here:
//   • View all classes created by the L3 admin
//   • See each class's enrolled student count
//   • Drill into a class → see every period with present / absent / late counts
//
// What L2 CANNOT do here (all write operations are intentionally absent):
//   • Create / delete / rename classes
//   • Set / edit geo-boundaries
//   • Add / delete periods
//   • Override attendance status
//   • Remove students
// =============================================================================
class AdminL2SupervisionPage extends StatelessWidget {
  /// The L3 admin being supervised.
  final String l3AdminName;
  final String l3AdminId;

  const AdminL2SupervisionPage({
    super.key,
    required this.l3AdminName,
    required this.l3AdminId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Supervision Mode",
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            // "watch-only" badge — makes the restriction immediately obvious
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.remove_red_eye, color: Colors.orange, size: 10),
                  const SizedBox(width: 4),
                  Text(
                    "READ-ONLY  •  ${l3AdminName.toUpperCase()}",
                    style: GoogleFonts.poppins(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                        letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: RisingSheet(
              child: Container(
                width: double.infinity,
                decoration: AppTheme.bottomSheet,
                child: _ClassListView(l3AdminId: l3AdminId, l3AdminName: l3AdminName),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ClassListView — streams the L3 admin's classes (read-only)
// ---------------------------------------------------------------------------
class _ClassListView extends StatelessWidget {
  final String l3AdminId;
  final String l3AdminName;

  const _ClassListView({required this.l3AdminId, required this.l3AdminName});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .where('createdBy', isEqualTo: l3AdminId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.kGreen));
        }

        final classes = snapshot.data!.docs;

        if (classes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.class_outlined, size: 56, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text("No Classes Found",
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
                const SizedBox(height: 6),
                Text("$l3AdminName has not created any classes yet.",
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.grey.shade400)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          itemCount: classes.length,
          itemBuilder: (context, index) {
            final doc = classes[index];
            final data = doc.data() as Map<String, dynamic>;
            final int enrolledCount =
                (data['studentIds'] as List<dynamic>? ?? []).length;
            final bool hasBoundary = data['boundary'] != null;

            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey.shade200)),
              elevation: 0,
              color: Colors.white,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => _ClassStatsPage(
                      classId: doc.id,
                      classData: data,
                      l3AdminName: l3AdminName,
                    ),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: CurvedAnimation(
                            parent: animation, curve: Curves.easeIn),
                        child: SlideTransition(
                          position: Tween<Offset>(
                                  begin: const Offset(0, 0.08), end: Offset.zero)
                              .animate(CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.fastOutSlowIn)),
                          child: child,
                        ),
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 350),
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppTheme.kGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.class_,
                            color: AppTheme.kGreen, size: 24),
                      ),
                      const SizedBox(width: 14),
                      // Name + code
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['className'] ?? 'Unknown Class',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Code: ${data['classCode'] ?? doc.id}",
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                      // Stats chips
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _chip("$enrolledCount students",
                              Icons.people_alt_outlined, Colors.blue),
                          const SizedBox(height: 4),
                          _chip(
                            hasBoundary ? "Boundary Set" : "No Boundary",
                            Icons.my_location,
                            hasBoundary ? Colors.green : Colors.orange,
                          ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right,
                          color: Colors.grey.shade400, size: 18),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _chip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// =============================================================================
// _ClassStatsPage — read-only drilled-in view for one class
// Shows: enrolled count, and per-period present / late / absent breakdown.
// No write operations exposed anywhere.
// =============================================================================
class _ClassStatsPage extends StatelessWidget {
  final String classId;
  final Map<String, dynamic> classData;
  final String l3AdminName;

  const _ClassStatsPage({
    required this.classId,
    required this.classData,
    required this.l3AdminName,
  });

  String get _className => classData['className'] as String? ?? 'Class';
  String get _classCode => classData['classCode'] as String? ?? classId;
  List<String> get _studentIds =>
      (classData['studentIds'] as List<dynamic>? ?? []).cast<String>();

  @override
  Widget build(BuildContext context) {
    final bool hasBoundary = classData['boundary'] != null;

    return Scaffold(
      backgroundColor: AppTheme.kDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _className,
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17),
            ),
            Text(
              "Code: $_classCode",
              style: const TextStyle(fontSize: 11, color: Colors.white60),
            ),
          ],
        ),
        // No action buttons — strictly view-only
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: AppTheme.bottomSheet,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(35)),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
                  children: [
                    // ── Overview stat cards ─────────────────────────────────
                    _OverviewStats(
                      classId: classId,
                      studentCount: _studentIds.length,
                      hasBoundary: hasBoundary,
                    ),

                    const SizedBox(height: 22),

                    // ── Enrolled students (read-only expandable) ────────────
                    _EnrolledStudentsSection(studentIds: _studentIds),

                    const SizedBox(height: 22),

                    // ── Per-period attendance stats ─────────────────────────
                    _PeriodsStatsSection(
                      classId: classId,
                      studentIds: _studentIds,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _OverviewStats — top summary row: total students, boundary status, log count
// ---------------------------------------------------------------------------
class _OverviewStats extends StatelessWidget {
  final String classId;
  final int studentCount;
  final bool hasBoundary;

  const _OverviewStats({
    required this.classId,
    required this.studentCount,
    required this.hasBoundary,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance_logs')
          .where('classId', isEqualTo: classId)
          .snapshots(),
      builder: (context, snap) {
        final int logCount = snap.hasData
            ? snap.data!.docs
                .where((d) => (d.data() as Map)['isHiddenFromAdmin'] != true)
                .length
            : 0;

        return Row(
          children: [
            _StatCard(
              icon: Icons.people_alt_outlined,
              label: "Enrolled",
              value: "$studentCount",
              color: Colors.blue,
            ),
            const SizedBox(width: 12),
            _StatCard(
              icon: Icons.receipt_long_outlined,
              label: "Total Logs",
              value: "$logCount",
              color: AppTheme.kGreen,
            ),
            const SizedBox(width: 12),
            _StatCard(
              icon: Icons.my_location,
              label: "Boundary",
              value: hasBoundary ? "Set" : "None",
              color: hasBoundary ? Colors.green : Colors.orange,
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _EnrolledStudentsSection — expandable list (names only, read-only)
// ---------------------------------------------------------------------------
class _EnrolledStudentsSection extends StatelessWidget {
  final List<String> studentIds;
  const _EnrolledStudentsSection({required this.studentIds});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 3))
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppTheme.kGreen,
          collapsedIconColor: Colors.grey,
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          title: Row(
            children: [
              const Icon(Icons.people_alt_outlined,
                  color: AppTheme.kGreen, size: 20),
              const SizedBox(width: 8),
              Text("Enrolled Students",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text("${studentIds.length}",
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          children: [
            if (studentIds.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Text("No students enrolled yet.",
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where(FieldPath.documentId, whereIn: studentIds)
                      .snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.kGreen));
                    }
                    return Container(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: ListView(
                        shrinkWrap: true,
                        children: snap.data!.docs.map((s) {
                          final sd = s.data() as Map<String, dynamic>;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            leading: const CircleAvatar(
                              radius: 18,
                              backgroundColor: Color(0xFFF1F4F2),
                              child: Icon(Icons.person,
                                  color: AppTheme.kGreen, size: 16),
                            ),
                            title: Text(sd['name'] ?? 'Unknown',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            subtitle: Text("ID: ${sd['username'] ?? s.id}",
                                style: const TextStyle(fontSize: 11)),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _PeriodsStatsSection — lists every period with present / late / absent stats
// ---------------------------------------------------------------------------
class _PeriodsStatsSection extends StatelessWidget {
  final String classId;
  final List<String> studentIds;

  const _PeriodsStatsSection(
      {required this.classId, required this.studentIds});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 3))
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded,
                  color: AppTheme.kGreen, size: 22),
              const SizedBox(width: 8),
              Text("Attendance per Period",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 6),
          // Watchdog notice — reinforces read-only intent
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: Colors.orange, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "You are in watch-only mode. No changes can be made.",
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.orange.shade800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('classes')
                .doc(classId)
                .collection('periods')
                .orderBy('startTime', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.kGreen));
              }
              if (snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                      child: Text("No periods added yet.",
                          style: TextStyle(color: Colors.grey))),
                );
              }

              // Group by date
              final Map<String, List<DocumentSnapshot>> grouped = {};
              for (final doc in snapshot.data!.docs) {
                final dateStr =
                    (doc.data() as Map<String, dynamic>)['date'] as String? ??
                        'Unknown';
                grouped.putIfAbsent(dateStr, () => []).add(doc);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: grouped.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 12, bottom: 8),
                        child: Text(
                          _prettyDate(entry.key),
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade500,
                              fontSize: 12),
                        ),
                      ),
                      ...entry.value.map((doc) {
                        final data =
                            doc.data() as Map<String, dynamic>;
                        return _PeriodStatCard(
                          periodId: doc.id,
                          periodData: data,
                          totalStudents: studentIds.length,
                        );
                      }),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  String _prettyDate(String raw) {
    try {
      return DateFormat('EEEE, MMM dd yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }
}

// ---------------------------------------------------------------------------
// _PeriodStatCard — streams attendance logs for one period and shows
//   Present / Late / Absent / Pending counts. Read-only.
// ---------------------------------------------------------------------------
class _PeriodStatCard extends StatelessWidget {
  final String periodId;
  final Map<String, dynamic> periodData;
  final int totalStudents;

  const _PeriodStatCard({
    required this.periodId,
    required this.periodData,
    required this.totalStudents,
  });

  @override
  Widget build(BuildContext context) {
    final startTS = periodData['startTime'] as Timestamp?;
    final endTS = periodData['endTime'] as Timestamp?;
    final String timeStr = (startTS != null && endTS != null)
        ? "${DateFormat('hh:mm a').format(startTS.toDate())} – "
            "${DateFormat('hh:mm a').format(endTS.toDate())}"
        : "Unknown Time";

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance_logs')
          .where('periodId', isEqualTo: periodId)
          .snapshots(),
      builder: (context, snap) {
        // Count per status
        int present = 0, late = 0, absent = 0, pending = 0;
        if (snap.hasData) {
          for (final doc in snap.data!.docs) {
            final d = doc.data() as Map<String, dynamic>;
            final status =
                (d['adminVerifiedStatus'] as String? ?? 'Pending').trim();
            switch (status) {
              case 'Present':
                present++;
                break;
              case 'Late':
                late++;
                break;
              case 'Absent':
                absent++;
                break;
              default:
                pending++;
            }
          }
        }
        final int reported = present + late + absent + pending;
        final int notReported =
            totalStudents > reported ? totalStudents - reported : 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.kSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period time
              Row(
                children: [
                  const Icon(Icons.access_time_filled,
                      color: AppTheme.kGreen, size: 16),
                  const SizedBox(width: 6),
                  Text(timeStr,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  const Spacer(),
                  // Total reported badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.kGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "$reported / $totalStudents reported",
                      style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppTheme.kGreen,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Stat pills row
              Row(
                children: [
                  _AttendancePill(
                      label: "Present", count: present, color: Colors.green),
                  const SizedBox(width: 8),
                  _AttendancePill(
                      label: "Late", count: late, color: Colors.orange),
                  const SizedBox(width: 8),
                  _AttendancePill(
                      label: "Absent", count: absent, color: Colors.red),
                  const SizedBox(width: 8),
                  _AttendancePill(
                      label: "Not In",
                      count: notReported,
                      color: Colors.grey),
                ],
              ),
              if (totalStudents > 0) ...[
                const SizedBox(height: 10),
                // Visual attendance bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 6,
                    child: Row(
                      children: [
                        _BarSegment(
                            flex: present, color: Colors.green, total: totalStudents),
                        _BarSegment(
                            flex: late, color: Colors.orange, total: totalStudents),
                        _BarSegment(
                            flex: absent, color: Colors.red, total: totalStudents),
                        _BarSegment(
                            flex: notReported,
                            color: Colors.grey.shade300,
                            total: totalStudents),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _AttendancePill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _AttendancePill(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text("$count",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color)),
          Text(label,
              style: TextStyle(
                  fontSize: 9,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// A proportional colored segment for the attendance bar.
class _BarSegment extends StatelessWidget {
  final int flex;
  final Color color;
  final int total;

  const _BarSegment(
      {required this.flex, required this.color, required this.total});

  @override
  Widget build(BuildContext context) {
    if (flex <= 0 || total <= 0) return const SizedBox.shrink();
    return Flexible(
      flex: flex,
      child: Container(color: color),
    );
  }
}