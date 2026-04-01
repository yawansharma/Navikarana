import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'class_detail_page.dart';
import 'main.dart';
import 'app_theme.dart';
import 'profile_page.dart';

class HomePage extends StatelessWidget {
  final String name;
  final String username;

  const HomePage({super.key, required this.name, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kDark,
      appBar: AppBar(
        title: const Text("Dashboard"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.logout),
          tooltip: "Logout",
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false,
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: "Profile",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(username: username))),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Header Area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome back,",
                        style: AppTheme.subheadingGrey,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: AppTheme.headingWhite,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // White Container
          Expanded(
            child: RisingSheet(
              child: Container(
                width: double.infinity,
                decoration: AppTheme.bottomSheet,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('classes')
                    .where('studentIds', arrayContains: username)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.kGreen,
                      ),
                    );
                  }

                  final classDocs = snapshot.data!.docs;

                  if (classDocs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          AppTheme.sheetHandle,
                          const Spacer(),
                          Icon(Icons.school_outlined, size: 80, color: Colors.grey.shade300),
                          const SizedBox(height: 24),
                          Text("No Classes Joined", style: AppTheme.sectionTitle),
                          const SizedBox(height: 8),
                          Text(
                            "You haven't joined any classes yet.\nJoin one to start tracking attendance.",
                            textAlign: TextAlign.center,
                            style: AppTheme.subheadingGrey,
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: 160,
                            child: ElevatedButton.icon(
                              onPressed: () => _showJoinClassDialog(context),
                              icon: const Icon(Icons.add_circle_outline, size: 20),
                              label: const Text("Join Now"),
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    );
                  }

                  return CustomScrollView(
                    slivers: [
                      // Sheet handle
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                          child: AppTheme.sheetHandle,
                        ),
                      ),

                      // Today's Sessions banner
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _ActivePeriodsBanner(
                            classDocs: classDocs,
                            username: username,
                          ),
                        ),
                      ),

                      // "Your Classes" header + Join button
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Your Classes", style: AppTheme.sectionTitle),
                              ElevatedButton.icon(
                                onPressed: () => _showJoinClassDialog(context),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text("Join"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.kGreen,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(80, 36),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Class list
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final doc = classDocs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: IntrinsicHeight(
                                    child: Row(
                                      children: [
                                        Container(width: 5, color: AppTheme.kGreen),
                                        Expanded(
                                          child: ListTile(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                            title: Hero(
                                              tag: 'class_header_${doc.id}',
                                              child: Material(
                                                color: Colors.transparent,
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      data['className'] ?? "Unknown Class",
                                                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    Text(
                                                      "Code: ${data['classCode'] ?? 'Unknown'}",
                                                      style: AppTheme.labelSmall.copyWith(fontSize: 11),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            subtitle: null,
                                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                PageRouteBuilder(
                                                  pageBuilder: (_, anim, sa) =>
                                                      ClassDetailPage(
                                                    classId: doc.id,
                                                    className:
                                                        data['className'] ??
                                                            'Class',
                                                    boundary: data['boundary']
                                                        as Map<String,
                                                            dynamic>?,
                                                    username: username,
                                                  ),
                                                  transitionsBuilder: (context,
                                                      animation,
                                                      secondaryAnimation,
                                                      child) {
                                                    const begin =
                                                        Offset(0.0, 0.2);
                                                    const end = Offset.zero;
                                                    const curve =
                                                        Curves.fastOutSlowIn;

                                                    var slideTween =
                                                        Tween(begin: begin, end: end)
                                                            .chain(CurveTween(
                                                                curve: curve));
                                                    var fadeTween = Tween<
                                                                double>(
                                                            begin: 0.0, end: 1.0)
                                                        .chain(CurveTween(
                                                            curve:
                                                                Curves.easeIn));
                                                    var scaleTween = Tween<
                                                                double>(
                                                            begin: 0.98, end: 1.0)
                                                        .chain(CurveTween(
                                                            curve: curve));

                                                    return FadeTransition(
                                                      opacity: animation
                                                          .drive(fadeTween),
                                                      child: ScaleTransition(
                                                        scale: animation
                                                            .drive(scaleTween),
                                                        child: SlideTransition(
                                                          position: animation
                                                              .drive(slideTween),
                                                          child: child,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  transitionDuration:
                                                      const Duration(
                                                          milliseconds: 400),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                            childCount: classDocs.length,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showJoinClassDialog(BuildContext context) {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Join a Class",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: codeCtrl,
          decoration: const InputDecoration(
            labelText: "Class Code",
            hintText: "Enter the code provided by admin",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A8A73),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final code = codeCtrl.text.trim();
              if (code.isEmpty) return;

              final classQuery = await FirebaseFirestore.instance
                  .collection('classes')
                  .where('classCode', isEqualTo: code)
                  .get();
              if (classQuery.docs.isEmpty) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Invalid class code.")),
                  );
                }
                return;
              }

              final classDoc = classQuery.docs.first;
              await classDoc.reference.update({
                'studentIds': FieldValue.arrayUnion([username]),
              });

              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Joined class successfully!")),
                );
              }
            },
            child: const Text("Join"),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _ActivePeriodsBanner — shows active/upcoming sessions for all classes
// =============================================================================
class _ActivePeriodsBanner extends StatefulWidget {
  final List<QueryDocumentSnapshot> classDocs;
  final String username;

  const _ActivePeriodsBanner({required this.classDocs, required this.username});

  @override
  State<_ActivePeriodsBanner> createState() => _ActivePeriodsBannerState();
}

class _ActivePeriodsBannerState extends State<_ActivePeriodsBanner> {
  final Map<String, List<Map<String, dynamic>>> _periodsMap = {};
  final List<StreamSubscription> _subs = [];

  @override
  void initState() {
    super.initState();
    _setupSubscriptions();
  }

  @override
  void didUpdateWidget(covariant _ActivePeriodsBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.classDocs.length != widget.classDocs.length) {
      _setupSubscriptions();
    }
  }

  void _setupSubscriptions() {
    for (var sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
    _periodsMap.clear();

    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    for (var classDoc in widget.classDocs) {
      final classId = classDoc.id;
      final classData = classDoc.data() as Map<String, dynamic>;
      final className = classData['className'] ?? 'Unknown Class';
      final boundary = classData['boundary'];

      final sub = FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('periods')
          .where('date', isEqualTo: todayStr)
          .snapshots()
          .listen((snap) {
            if (!mounted) return;
            List<Map<String, dynamic>> periods = [];
            for (var doc in snap.docs) {
              final data = doc.data() as Map<String, dynamic>;
              periods.add({
                'id': doc.id,
                'classId': classId,
                'className': className,
                'boundary': boundary,
                ...data,
              });
            }
            setState(() {
              _periodsMap[classId] = periods;
            });
          });
      _subs.add(sub);
    }
  }

  @override
  void dispose() {
    for (var sub in _subs) {
      sub.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> allPeriods = [];
    _periodsMap.values.forEach((list) => allPeriods.addAll(list));

    if (allPeriods.isEmpty) {
      return const SizedBox.shrink(); // No periods today
    }

    final now = DateTime.now();

    // Sort periods by start time
    allPeriods.sort((a, b) {
      final aTs = a['startTime'] as Timestamp?;
      final bTs = b['startTime'] as Timestamp?;
      if (aTs == null) return 1;
      if (bTs == null) return -1;
      return aTs.compareTo(bTs);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Today's Classes",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${allPeriods.length} Sessions",
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: allPeriods.length,
            clipBehavior: Clip.none,
            itemBuilder: (context, index) {
              final period = allPeriods[index];
              final startTs = period['startTime'] as Timestamp?;
              final endTs = period['endTime'] as Timestamp?;

              if (startTs == null || endTs == null)
                return const SizedBox.shrink();

              final realStart = startTs.toDate();
              final realEnd = endTs.toDate();

              final reportStart = realStart.subtract(
                const Duration(minutes: 10),
              );
              final reportEnd = realEnd.add(const Duration(minutes: 10));

              bool isUpcoming = now.isBefore(reportStart);
              bool isPast = now.isAfter(reportEnd);
              bool isActive = !isUpcoming && !isPast;

              Color accentColor = isActive
                  ? Colors.green
                  : (isUpcoming ? Colors.orange : Colors.grey);
              String statusText = isActive
                  ? "Active Now"
                  : (isUpcoming ? "Upcoming" : "Ended");

              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isActive ? Icons.sensors : Icons.access_time_filled,
                          color: accentColor,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      period['className'] ?? "Unknown Class",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${DateFormat('hh:mm a').format(realStart)} - ${DateFormat('hh:mm a').format(realEnd)}",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    if (isActive)
                      SizedBox(
                        width: double.infinity,
                        height: 28,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ClassDetailPage(
                                  classId: period['classId'],
                                  className: period['className'],
                                  boundary: period['boundary'],
                                  username: widget.username,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "Open to Report",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
