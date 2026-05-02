import 'dart:async';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'class_detail_page.dart';
import 'main.dart';
import 'app_theme.dart';
import 'profile_page.dart';
import 'services/appwrite_service.dart';

class HomePage extends StatefulWidget {
  final String name;
  final String username;

  const HomePage({super.key, required this.name, required this.username});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<models.Document> _classes = [];
  bool _loading = true;
  RealtimeSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _fetchClasses();
    _sub = AppwriteService.realtime
        .subscribe(['databases.main_db.collections.classes.documents']);
    _sub!.stream.listen((_) {
      if (mounted) _fetchClasses();
    });
  }

  @override
  void dispose() {
    _sub?.close();
    super.dispose();
  }

  Future<void> _fetchClasses() async {
    try {
      final result = await AppwriteService.databases.listDocuments(
        databaseId: 'main_db',
        collectionId: 'classes',
        queries: [Query.contains('studentIds', widget.username)],
      );
      if (mounted) {
        setState(() {
          _classes = result.documents;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
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

              try {
                final classQuery = await AppwriteService.databases.listDocuments(
                  databaseId: 'main_db',
                  collectionId: 'classes',
                  queries: [Query.equal('classCode', code)],
                );

                if (classQuery.documents.isEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Invalid class code.")),
                    );
                  }
                  return;
                }

                final classDoc = classQuery.documents.first;
                final List<String> currentStudents =
                    List<String>.from(classDoc.data['studentIds'] ?? []);
                if (!currentStudents.contains(widget.username)) {
                  currentStudents.add(widget.username);
                }

                await AppwriteService.databases.updateDocument(
                  databaseId: 'main_db',
                  collectionId: 'classes',
                  documentId: classDoc.$id,
                  data: {'studentIds': currentStudents},
                );

                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Joined class successfully!")),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e")),
                  );
                }
              }
            },
            child: const Text("Join"),
          ),
        ],
      ),
    );
  }

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
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ProfilePage(username: widget.username))),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Welcome back,", style: AppTheme.subheadingGrey),
                      const SizedBox(height: 4),
                      Text(widget.name, style: AppTheme.headingWhite),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: RisingSheet(
              child: Container(
                width: double.infinity,
                decoration: AppTheme.bottomSheet,
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppTheme.kGreen))
                    : _classes.isEmpty
                        ? _buildEmptyState(context)
                        : _buildClassList(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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

  Widget _buildClassList(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: AppTheme.sheetHandle,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _ActivePeriodsBanner(
              classDocs: _classes,
              username: widget.username,
            ),
          ),
        ),
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
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final doc = _classes[index];
                final data = doc.data;
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
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              title: Hero(
                                tag: 'class_header_${doc.$id}',
                                child: Material(
                                  color: Colors.transparent,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        data['className'] ?? "Unknown Class",
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        "Code: ${data['classCode'] ?? 'Unknown'}",
                                        style: AppTheme.labelSmall
                                            .copyWith(fontSize: 11),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              trailing: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                  color: Colors.grey),
                              onTap: () {
                                final boundary = data['boundary'];
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (_, anim, sa) =>
                                        ClassDetailPage(
                                      classId: doc.$id,
                                      className:
                                          data['className'] ?? 'Class',
                                      boundary: boundary is Map<String, dynamic>
                                          ? boundary
                                          : null,
                                      username: widget.username,
                                    ),
                                    transitionsBuilder: (context, animation,
                                        secondaryAnimation, child) {
                                      const begin = Offset(0.0, 0.2);
                                      const end = Offset.zero;
                                      const curve = Curves.fastOutSlowIn;
                                      final slideTween =
                                          Tween(begin: begin, end: end).chain(
                                              CurveTween(curve: curve));
                                      final fadeTween =
                                          Tween<double>(begin: 0.0, end: 1.0)
                                              .chain(CurveTween(
                                                  curve: Curves.easeIn));
                                      final scaleTween =
                                          Tween<double>(begin: 0.98, end: 1.0)
                                              .chain(CurveTween(curve: curve));
                                      return FadeTransition(
                                        opacity: animation.drive(fadeTween),
                                        child: ScaleTransition(
                                          scale: animation.drive(scaleTween),
                                          child: SlideTransition(
                                            position:
                                                animation.drive(slideTween),
                                            child: child,
                                          ),
                                        ),
                                      );
                                    },
                                    transitionDuration:
                                        const Duration(milliseconds: 400),
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
              childCount: _classes.length,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// _ActivePeriodsBanner — shows active/upcoming sessions for all joined classes
// =============================================================================
class _ActivePeriodsBanner extends StatefulWidget {
  final List<models.Document> classDocs;
  final String username;

  const _ActivePeriodsBanner(
      {required this.classDocs, required this.username});

  @override
  State<_ActivePeriodsBanner> createState() => _ActivePeriodsBannerState();
}

class _ActivePeriodsBannerState extends State<_ActivePeriodsBanner> {
  final Map<String, List<Map<String, dynamic>>> _periodsMap = {};
  RealtimeSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _fetchAllPeriods();
    _sub = AppwriteService.realtime
        .subscribe(['databases.main_db.collections.periods.documents']);
    _sub!.stream.listen((_) {
      if (mounted) _fetchAllPeriods();
    });
  }

  @override
  void didUpdateWidget(covariant _ActivePeriodsBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.classDocs.length != widget.classDocs.length) {
      _fetchAllPeriods();
    }
  }

  @override
  void dispose() {
    _sub?.close();
    super.dispose();
  }

  Future<void> _fetchAllPeriods() async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final Map<String, List<Map<String, dynamic>>> newMap = {};

    for (final classDoc in widget.classDocs) {
      final classId = classDoc.$id;
      final className = classDoc.data['className'] ?? 'Unknown Class';
      final boundary = classDoc.data['boundary'];

      try {
        final result = await AppwriteService.databases.listDocuments(
          databaseId: 'main_db',
          collectionId: 'periods',
          queries: [
            Query.equal('classId', classId),
            Query.equal('date', todayStr),
          ],
        );

        final periods = result.documents.map((doc) {
          return <String, dynamic>{
            'id': doc.$id,
            'classId': classId,
            'className': className,
            'boundary': boundary,
            ...doc.data,
          };
        }).toList();

        newMap[classId] = periods;
      } catch (_) {
        newMap[classId] = [];
      }
    }

    if (mounted) setState(() => _periodsMap..clear()..addAll(newMap));
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> allPeriods = [];
    for (final list in _periodsMap.values) {
      allPeriods.addAll(list);
    }

    if (allPeriods.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();

    allPeriods.sort((a, b) {
      final aTs = a['startTime'] as String?;
      final bTs = b['startTime'] as String?;
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              final startStr = period['startTime'] as String?;
              final endStr = period['endTime'] as String?;
              if (startStr == null || endStr == null) {
                return const SizedBox.shrink();
              }

              final realStart = DateTime.parse(startStr);
              final realEnd = DateTime.parse(endStr);
              final reportStart =
                  realStart.subtract(const Duration(minutes: 10));
              final reportEnd = realEnd.add(const Duration(minutes: 10));

              final isUpcoming = now.isBefore(reportStart);
              final isPast = now.isAfter(reportEnd);
              final isActive = !isUpcoming && !isPast;

              final accentColor = isActive
                  ? Colors.green
                  : (isUpcoming ? Colors.orange : Colors.grey);
              final statusText = isActive
                  ? "Active Now"
                  : (isUpcoming ? "Upcoming" : "Ended");

              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: accentColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isActive
                              ? Icons.sensors
                              : Icons.access_time_filled,
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
                          color: Colors.grey.shade600, fontSize: 12),
                    ),
                    const Spacer(),
                    if (isActive)
                      SizedBox(
                        width: double.infinity,
                        height: 28,
                        child: ElevatedButton(
                          onPressed: () {
                            final boundary = period['boundary'];
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ClassDetailPage(
                                  classId: period['classId'],
                                  className: period['className'],
                                  boundary:
                                      boundary is Map<String, dynamic>
                                          ? boundary
                                          : null,
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
                                borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          child: const Text(
                            "Open to Report",
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold),
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
