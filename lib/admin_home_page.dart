import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:appwrite/appwrite.dart' hide Permission;
import 'package:appwrite/models.dart' as models;
import 'main.dart';
import 'community_page.dart';
import 'app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/appwrite_service.dart';

// =============================================================================
// AdminHomePage â€” 3-tab shell: Classes | Analytics | Settings
// =============================================================================
class AdminHomePage extends StatefulWidget {
  final String adminName;
  final String adminId;
  final bool isDean;
  const AdminHomePage(
      {super.key,
      required this.adminName,
      required this.adminId,
      this.isDean = false});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _currentIndex = 0;
  int _prevIndex = 0;
  DateTimeRange? _dateRange;
  String? _classFilter;

  // Classes tab state
  List<models.Document> _classes = [];
  bool _classesLoading = true;

  // Global logs tab state
  List<models.Document> _logs = [];
  bool _logsLoading = true;

  // Log selection state
  bool _selectionMode = false;
  final Set<String> _selectedLogIds = {};

  // Realtime subscriptions
  RealtimeSubscription? _classesSub;
  RealtimeSubscription? _logsSub;

  @override
  void initState() {
    super.initState();
    _fetchClasses();
    _fetchLogs();
    _classesSub = AppwriteService.realtime
        .subscribe(['databases.main_db.collections.classes.documents']);
    _classesSub!.stream.listen((_) {
      if (mounted) _fetchClasses();
    });
    _logsSub = AppwriteService.realtime
        .subscribe(['databases.main_db.collections.attendance_logs.documents']);
    _logsSub!.stream.listen((_) {
      if (mounted) _fetchLogs();
    });
  }

  @override
  void dispose() {
    _classesSub?.close();
    _logsSub?.close();
    super.dispose();
  }

  Future<void> _fetchClasses() async {
    try {
      final result = await AppwriteService.databases.listDocuments(
        databaseId: '69ecebfb0033cf785741',
        collectionId: 'classes',
        queries: [Query.equal('createdBy', widget.adminId)],
      );
      if (mounted) {
        setState(() {
          _classes = result.documents;
          _classesLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _classesLoading = false);
    }
  }

  Future<void> _fetchLogs() async {
    try {
      final result = await AppwriteService.databases.listDocuments(
        databaseId: '69ecebfb0033cf785741',
        collectionId: 'attendance_logs',
        queries: [
          Query.equal('adminId', widget.adminId),
          Query.orderDesc('timestamp'),
          Query.limit(500),
        ],
      );
      if (mounted) {
        setState(() {
          _logs = result.documents;
          _logsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _logsLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Scaffold
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () {
            if (widget.isDean) {
              Navigator.pop(context);
            } else {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _tabTitle(),
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.kGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: AppTheme.kGreen.withValues(alpha: 0.3)),
              ),
              child: Text(
                "ADMIN: ${widget.adminName.toUpperCase()}",
                style: GoogleFonts.poppins(
                    color: AppTheme.kGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 0.5),
              ),
            ),
          ],
        ),
        actions: _buildAppBarActions(),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: RisingSheet(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F9FB),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(35)),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(35)),
                        child: _buildCurrentTab(),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: BottomNavigationBar(
                        currentIndex: _currentIndex,
                        onTap: (i) => setState(() {
                          _prevIndex = _currentIndex;
                          _currentIndex = i;
                          if (i != 1) {
                            _selectionMode = false;
                            _selectedLogIds.clear();
                          }
                        }),
                        backgroundColor: Colors.white,
                        selectedItemColor: AppTheme.kGreen,
                        unselectedItemColor: Colors.grey.shade400,
                        showSelectedLabels: true,
                        showUnselectedLabels: false,
                        elevation: 0,
                        type: BottomNavigationBarType.fixed,
                        items: const [
                          BottomNavigationBarItem(
                              icon: Icon(Icons.class_outlined, size: 22),
                              label: "Classes"),
                          BottomNavigationBarItem(
                              icon:
                                  Icon(Icons.analytics_outlined, size: 22),
                              label: "Analytics"),
                          BottomNavigationBarItem(
                              icon: Icon(Icons.more_horiz_rounded, size: 22),
                              label: "Settings"),
                        ],
                      ),
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

  String _tabTitle() {
    switch (_currentIndex) {
      case 0:
        return "Classes";
      case 1:
        return "Analytics";
      case 2:
        return "Settings";
      default:
        return "";
    }
  }

  List<Widget> _buildAppBarActions() {
    if (_currentIndex == 1) {
      return [
        if (_dateRange != null)
          IconButton(
            icon: const Icon(Icons.close, color: Colors.redAccent),
            onPressed: () => setState(() => _dateRange = null),
          ),
        IconButton(
          icon: const Icon(Icons.calendar_month_outlined,
              color: Colors.white),
          onPressed: () async {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2024),
              lastDate: DateTime.now(),
              builder: (context, child) => Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Color(0xFF6A8A73),
                    onPrimary: Colors.white,
                    surface: Color(0xFF202020),
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) setState(() => _dateRange = picked);
          },
        ),
      ];
    }
    return [];
  }

  Widget _buildCurrentTab() {
    final tabs = [
      _buildClassesTab(),
      _buildGlobalLogsTab(),
      _buildMoreTab(),
    ];
    final bool goingRight = _currentIndex > _prevIndex;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      transitionBuilder: (child, animation) {
        final isEntering = child.key == ValueKey<int>(_currentIndex);
        final begin = isEntering
            ? Offset(goingRight ? 1.0 : -1.0, 0)
            : Offset(goingRight ? -1.0 : 1.0, 0);
        final slide =
            Tween<Offset>(begin: begin, end: Offset.zero).animate(
                CurvedAnimation(
                    parent: animation, curve: Curves.easeOutCubic));
        return ClipRect(
          child: FadeTransition(
            opacity: CurvedAnimation(
                parent: animation, curve: Curves.easeIn),
            child: SlideTransition(position: slide, child: child),
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<int>(_currentIndex),
        child: tabs[_currentIndex],
      ),
    );
  }

  // ===========================================================================
  // TAB 0 â€” CLASSES
  // ===========================================================================
  Widget _buildClassesTab() {
    if (_classesLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF6A8A73)));
    }

    return Stack(
      children: [
        _classes.isEmpty
            ? const Center(
                child: Text("No classes yet. Create one!",
                    style: TextStyle(color: Colors.grey)))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                itemCount: _classes.length,
                itemBuilder: (context, index) {
                  final classDoc = _classes[index];
                  final data = classDoc.data;
                  final List<dynamic> studentIds =
                      data['studentIds'] as List<dynamic>? ?? [];
                  final bool hasBoundary = data['boundary'] != null;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                    color: Colors.white,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) =>
                              ClassManagementPage(
                            classId: classDoc.$id,
                            classData: data,
                            adminName: widget.adminName,
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
                                Tween<double>(begin: 0.0, end: 1.0).chain(
                                    CurveTween(curve: Curves.easeIn));
                            final scaleTween =
                                Tween<double>(begin: 0.98, end: 1.0)
                                    .chain(CurveTween(curve: curve));
                            return FadeTransition(
                              opacity: animation.drive(fadeTween),
                              child: ScaleTransition(
                                scale: animation.drive(scaleTween),
                                child: SlideTransition(
                                  position: animation.drive(slideTween),
                                  child: child,
                                ),
                              ),
                            );
                          },
                          transitionDuration:
                              const Duration(milliseconds: 400),
                        ),
                      ).then((_) => _fetchClasses()),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Hero(
                              tag: 'class_icon_${classDoc.$id}',
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F4F2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.class_,
                                    color: Color(0xFF6A8A73), size: 24),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Hero(
                                tag: 'class_header_${classDoc.$id}',
                                child: Material(
                                  color: Colors.transparent,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        data['className'] as String? ??
                                            "Unknown Class",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "Code: ${data['classCode'] as String? ?? classDoc.$id}",
                                        style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 11),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _miniChip(
                                  "${studentIds.length} students",
                                  Icons.people_alt_outlined,
                                  Colors.blue,
                                ),
                                const SizedBox(height: 4),
                                _miniChip(
                                  hasBoundary
                                      ? "Boundary Set"
                                      : "No Boundary",
                                  Icons.my_location,
                                  hasBoundary
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ],
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right,
                                color: Colors.grey, size: 18),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF6A8A73),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text("New Class",
                style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => _openCreateClassDialog(context),
          ),
        ),
      ],
    );
  }

  void _openCreateClassDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    Map<String, dynamic>? pendingBoundary;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text("Create Class",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                    labelText: "Class Name (e.g. CS101)"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(
                    labelText: "Join Code (e.g. CS101-2024)"),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final result = await _openBoundaryPickerForCreate(
                    ctx,
                    nameCtrl.text.trim().isEmpty
                        ? "New Class"
                        : nameCtrl.text.trim(),
                    pendingBoundary,
                  );
                  if (result != null) setSt(() => pendingBoundary = result);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: pendingBoundary != null
                        ? const Color(0xFF6A8A73).withValues(alpha: 0.08)
                        : Colors.red.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: pendingBoundary != null
                          ? const Color(0xFF6A8A73)
                          : Colors.red.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        pendingBoundary != null
                            ? Icons.location_on
                            : Icons.location_off_outlined,
                        color: pendingBoundary != null
                            ? const Color(0xFF6A8A73)
                            : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          pendingBoundary != null
                              ? "Boundary set â€” ${(pendingBoundary!['radiusMeters'] as num).toStringAsFixed(0)} m radius"
                              : "Set Boundary (required)",
                          style: TextStyle(
                            fontSize: 13,
                            color: pendingBoundary != null
                                ? const Color(0xFF6A8A73)
                                : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: pendingBoundary != null
                            ? const Color(0xFF6A8A73)
                            : Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            StatefulBuilder(
              builder: (_, setBtn) => ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A8A73),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                onPressed: nameCtrl.text.isNotEmpty &&
                        codeCtrl.text.isNotEmpty &&
                        pendingBoundary != null
                    ? () async {
                        await AppwriteService.databases.createDocument(
                          databaseId: '69ecebfb0033cf785741',
                          collectionId: 'classes',
                          documentId: ID.unique(),
                          data: {
                            'className': nameCtrl.text.trim(),
                            'classCode': codeCtrl.text.trim(),
                            'adminName': widget.adminName,
                            'createdBy': widget.adminId,
                            'studentIds': <String>[],
                            'boundary': pendingBoundary,
                          },
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        _fetchClasses();
                      }
                    : null,
                child: const Text("Create"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _openBoundaryPickerForCreate(
      BuildContext parentCtx,
      String className,
      Map<String, dynamic>? existing) async {
    LatLng pos;
    if (existing != null) {
      pos = LatLng((existing['lat'] as num).toDouble(),
          (existing['lng'] as num).toDouble());
    } else {
      try {
        final loc = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        pos = LatLng(loc.latitude, loc.longitude);
      } catch (_) {
        pos = const LatLng(20.59, 78.96);
      }
    }
    double radius = existing != null
        ? (existing['radiusMeters'] as num).toDouble()
        : 100.0;
    LatLng current = pos;
    final MapController mapController = MapController();

    return showDialog<Map<String, dynamic>>(
      context: parentCtx,
      builder: (dialogCtx) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SizedBox(
          height: 560,
          width: 600,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFF6A8A73),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.my_location,
                        color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Set Class Boundary",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          Text(className,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(dialogCtx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StatefulBuilder(builder: (_, setSt) {
                  return Stack(
                    children: [
                      FlutterMap(
                        mapController: mapController,
                        options: MapOptions(
                          initialCenter: pos,
                          initialZoom: 16,
                          onTap: (_, p) => setSt(() => current = p),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName:
                                'com.virtualvision.admin',
                          ),
                          CircleLayer(circles: [
                            CircleMarker(
                              point: current,
                              radius: radius,
                              useRadiusInMeter: true,
                              color: const Color(0xFF6A8A73)
                                  .withValues(alpha: 0.18),
                              borderColor: const Color(0xFF6A8A73),
                              borderStrokeWidth: 2,
                            ),
                          ]),
                          MarkerLayer(markers: [
                            Marker(
                              point: current,
                              width: 40,
                              height: 40,
                              child: const Icon(Icons.location_on,
                                  color: Colors.red, size: 40),
                            ),
                          ]),
                        ],
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20)),
                          ),
                          padding: const EdgeInsets.fromLTRB(
                              16, 12, 16, 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                const Icon(Icons.my_location,
                                    size: 13, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text(
                                  "${current.latitude.toStringAsFixed(5)}, ${current.longitude.toStringAsFixed(5)}",
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                              ]),
                              const SizedBox(height: 6),
                              Row(children: [
                                const Icon(Icons.radio_button_checked,
                                    size: 13,
                                    color: Color(0xFF6A8A73)),
                                const SizedBox(width: 6),
                                Text(
                                  "Radius: ${radius.toStringAsFixed(0)} m",
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                                Expanded(
                                  child: Slider(
                                    value: radius,
                                    min: 30,
                                    max: 500,
                                    divisions: 47,
                                    activeColor: const Color(0xFF6A8A73),
                                    onChanged: (v) =>
                                        setSt(() => radius = v),
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF6A8A73),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                  onPressed: () =>
                                      Navigator.pop(dialogCtx, {
                                    'lat': current.latitude,
                                    'lng': current.longitude,
                                    'radiusMeters': radius,
                                  }),
                                  child: const Text("Confirm Boundary",
                                      style: TextStyle(
                                          fontWeight:
                                              FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 1 â€” GLOBAL LOGS
  // ===========================================================================
  Widget _buildGlobalLogsTab() {
    if (_logsLoading) {
      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(children: [
              Text('All Logs',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Spacer(),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: 6,
              itemBuilder: (_, __) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      );
    }

    var logs = List<models.Document>.from(_logs);

    // Date filter
    if (_dateRange != null) {
      logs = logs.where((doc) {
        final ts = doc.data['timestamp'] as String?;
        if (ts == null) return false;
        final dt = DateTime.parse(ts);
        return dt.isAfter(
                _dateRange!.start.subtract(const Duration(days: 1))) &&
            dt.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Class filter
    if (_classFilter != null) {
      logs = logs
          .where((doc) => doc.data['classId'] == _classFilter)
          .toList();
    }

    // Hide soft-deleted entries
    logs = logs
        .where((doc) => doc.data['isHiddenFromAdmin'] != true)
        .toList();

    // Group by day for delete-by-day feature
    final Map<String, List<models.Document>> byDay = {};
    for (final doc in logs) {
      final ts = doc.data['timestamp'] as String?;
      final dayKey = ts != null
          ? DateFormat('yyyy-MM-dd').format(DateTime.parse(ts))
          : 'Unknown';
      byDay.putIfAbsent(dayKey, () => []).add(doc);
    }

    return Column(
      children: [
        // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
          child: Row(
            children: [
              Text(
                _selectionMode
                    ? '${_selectedLogIds.length} selected'
                    : 'All Logs',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _selectionMode
                      ? AppTheme.kGreen
                      : const Color(0xFF1A1C1E),
                ),
              ),
              const Spacer(),
              if (_selectionMode) ...[
                TextButton.icon(
                  onPressed: _selectedLogIds.isEmpty
                      ? null
                      : () => _deleteSelectedLogs(logs),
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: Colors.red),
                  label: const Text('Delete',
                      style: TextStyle(color: Colors.red)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => setState(() {
                    _selectionMode = false;
                    _selectedLogIds.clear();
                  }),
                ),
              ] else ...[
                IconButton(
                  icon: const Icon(Icons.checklist_rounded,
                      color: Color(0xFF6A8A73)),
                  tooltip: 'Select logs',
                  onPressed: () =>
                      setState(() => _selectionMode = true),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.delete_sweep_outlined,
                      color: Colors.redAccent),
                  tooltip: 'Delete logs',
                  onSelected: (val) =>
                      _handleDeleteOption(val, logs, byDay),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'all',
                        child: Row(children: [
                          Icon(Icons.delete_forever,
                              color: Colors.red, size: 18),
                          SizedBox(width: 10),
                          Text('Delete All Logs')
                        ])),
                    const PopupMenuItem(
                        value: 'day',
                        child: Row(children: [
                          Icon(Icons.today_outlined,
                              color: Colors.orange, size: 18),
                          SizedBox(width: 10),
                          Text('Delete by Day')
                        ])),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.download_rounded,
                      color: Color(0xFF6A8A73)),
                  tooltip: 'Export CSV',
                  onPressed: _exportLogsToCSV,
                ),
              ],
            ],
          ),
        ),

        // â”€â”€ Class filter chips â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        _buildClassFilterChips(),
        const SizedBox(height: 8),

        // â”€â”€ Log list â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Expanded(
          child: logs.isEmpty
              ? const Center(
                  child: Text('No records found.',
                      style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final doc = logs[index];
                    final data = doc.data;
                    final isSelected =
                        _selectedLogIds.contains(doc.$id);
                    return GestureDetector(
                      onLongPress: () => setState(() {
                        _selectionMode = true;
                        _selectedLogIds.add(doc.$id);
                      }),
                      onTap: _selectionMode
                          ? () => setState(() {
                                if (isSelected) {
                                  _selectedLogIds.remove(doc.$id);
                                } else {
                                  _selectedLogIds.add(doc.$id);
                                }
                              })
                          : null,
                      child: Stack(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: isSelected
                                  ? Border.all(
                                      color: AppTheme.kGreen, width: 2)
                                  : null,
                              color: isSelected
                                  ? AppTheme.kGreen
                                      .withValues(alpha: 0.05)
                                  : null,
                            ),
                            child: _buildGlobalLogCard(data),
                          ),
                          if (_selectionMode)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: AnimatedSwitcher(
                                duration:
                                    const Duration(milliseconds: 150),
                                child: Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  key: ValueKey(isSelected),
                                  color: isSelected
                                      ? AppTheme.kGreen
                                      : Colors.grey.shade400,
                                  size: 22,
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

  Future<void> _deleteSelectedLogs(
      List<models.Document> allLogs) async {
    final toDelete = allLogs
        .where((d) => _selectedLogIds.contains(d.$id))
        .toList();
    final confirm = await _confirmDelete(
        'Delete ${toDelete.length} selected log(s)?');
    if (!confirm) return;
    for (final doc in toDelete) {
      await AppwriteService.databases.updateDocument(
        databaseId: '69ecebfb0033cf785741',
        collectionId: 'attendance_logs',
        documentId: doc.$id,
        data: {'isHiddenFromAdmin': true},
      );
    }
    setState(() {
      _selectionMode = false;
      _selectedLogIds.clear();
    });
    await _fetchLogs();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logs deleted.')));
    }
  }

  Future<void> _handleDeleteOption(
    String option,
    List<models.Document> logs,
    Map<String, List<models.Document>> byDay,
  ) async {
    if (option == 'all') {
      final confirm = await _confirmDelete(
          'Delete ALL ${logs.length} logs? This cannot be undone.');
      if (!confirm) return;
      for (final doc in logs) {
        await AppwriteService.databases.updateDocument(
          databaseId: '69ecebfb0033cf785741',
          collectionId: 'attendance_logs',
          documentId: doc.$id,
          data: {'isHiddenFromAdmin': true},
        );
      }
      await _fetchLogs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All logs deleted.')));
      }
    } else if (option == 'day') {
      _showDeleteByDayDialog(byDay);
    }
  }

  void _showDeleteByDayDialog(
      Map<String, List<models.Document>> byDay) {
    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Delete by Day',
              style:
                  TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: days.length,
              itemBuilder: (ctx, i) {
                final day = days[i];
                final count = byDay[day]!.length;
                final label = DateFormat('EEE, MMM dd yyyy')
                    .format(DateTime.parse(day));
                return ListTile(
                  leading: const Icon(Icons.today_outlined,
                      color: Colors.orange),
                  title: Text(label,
                      style:
                          const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: Text('$count log${count > 1 ? "s" : ""}',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 12)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final confirm = await _confirmDelete(
                        'Delete $count log(s) for $label?');
                    if (!confirm) return;
                    for (final doc in byDay[day]!) {
                      await AppwriteService.databases.updateDocument(
                        databaseId: '69ecebfb0033cf785741',
                        collectionId: 'attendance_logs',
                        documentId: doc.$id,
                        data: {'isHiddenFromAdmin': true},
                      );
                    }
                    await _fetchLogs();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              'Deleted $count log(s) for $label.')));
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: Text(message),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(80, 40)),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildClassFilterChips() {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text("All"),
              selected: _classFilter == null,
              onSelected: (_) => setState(() => _classFilter = null),
              selectedColor:
                  const Color(0xFF6A8A73).withValues(alpha: 0.2),
              checkmarkColor: const Color(0xFF6A8A73),
            ),
          ),
          ..._classes.map((c) {
            final d = c.data;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(d['className'] as String? ?? c.$id),
                selected: _classFilter == c.$id,
                onSelected: (_) =>
                    setState(() => _classFilter = c.$id),
                selectedColor:
                    const Color(0xFF6A8A73).withValues(alpha: 0.2),
                checkmarkColor: const Color(0xFF6A8A73),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGlobalLogCard(Map<String, dynamic> data) {
    final String? tsStr = data['timestamp'] as String?;
    final DateTime date =
        tsStr != null ? DateTime.parse(tsStr) : DateTime.now();
    final bool isVerified = data['isVerified'] == true;
    final bool isWithinGeofence = data['isWithinGeofence'] == true;
    final String photoUrl = data['photoUrl'] as String? ?? '';
    final String userId = data['userId'] as String? ?? 'Unknown';
    final String className = data['className'] as String? ?? '';

    return FutureBuilder<models.Document>(
      future: AppwriteService.databases.getDocument(
        databaseId: '69ecebfb0033cf785741',
        collectionId: 'users',
        documentId: userId,
      ),
      builder: (context, userSnap) {
        String studentName = userId;
        if (userSnap.hasData) {
          studentName =
              userSnap.data!.data['name'] as String? ?? userId;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                if (photoUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(photoUrl,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _photoPlaceholder()),
                  )
                else
                  _photoPlaceholder(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(studentName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      if (className.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(className,
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 11)),
                      ],
                      const SizedBox(height: 6),
                      Row(children: [
                        _miniChip(
                          isWithinGeofence ? "In Zone" : "Out of Zone",
                          isWithinGeofence
                              ? Icons.location_on
                              : Icons.location_off,
                          isWithinGeofence ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 6),
                        _miniChip(
                          isVerified ? "Verified" : "Pending",
                          isVerified
                              ? Icons.verified
                              : Icons.hourglass_top,
                          isVerified
                              ? const Color(0xFF6A8A73)
                              : Colors.orange,
                        ),
                      ]),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(DateFormat('hh:mm a').format(date),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(DateFormat('MMM dd').format(date),
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12)),
      child: const Icon(Icons.person, color: Colors.grey, size: 28),
    );
  }

  Future<void> _exportLogsToCSV() async {
    if (!Platform.isWindows &&
        !(await Permission.storage.request().isGranted)) {
      await Permission.manageExternalStorage.request();
    }

    // Fetch all non-hidden logs for this admin
    final logsSnapshot = await AppwriteService.databases.listDocuments(
      databaseId: '69ecebfb0033cf785741',
      collectionId: 'attendance_logs',
      queries: [
        Query.equal('adminId', widget.adminId),
        Query.orderDesc('timestamp'),
        Query.limit(5000),
      ],
    );

    List<List<dynamic>> rows = [
      ["Student ID", "Class", "Date", "Time", "In Zone", "Verified"]
    ];
    for (final doc in logsSnapshot.documents) {
      final d = doc.data;
      if (d['isHiddenFromAdmin'] == true) continue;
      final String? tsStr = d['timestamp'] as String?;
      final DateTime dt =
          tsStr != null ? DateTime.parse(tsStr) : DateTime.now();
      rows.add([
        d['userId'] ?? 'Unknown',
        d['className'] ?? '',
        DateFormat('dd/MM/yyyy').format(dt),
        DateFormat('HH:mm').format(dt),
        d['isWithinGeofence'] == true ? 'Yes' : 'No',
        d['isVerified'] == true ? 'Yes' : 'No',
      ]);
    }

    final String csvData = const ListToCsvConverter().convert(rows);
    final Directory? dir = Platform.isWindows
        ? Directory(
            '${Platform.environment['USERPROFILE']}\\Downloads')
        : await getExternalStorageDirectory();
    if (dir == null) return;
    final path =
        "${dir.path}/attendance_${DateTime.now().millisecondsSinceEpoch}.csv";
    await File(path).writeAsString(csvData);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Saved to $path")));
    }
  }

  // ===========================================================================
  // TAB 2 â€” MORE / SETTINGS
  // ===========================================================================
  Widget _buildMoreTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 16),
        Center(
          child: CircleAvatar(
            radius: 42,
            backgroundColor: const Color(0xFFF1F4F2),
            child: Text(
              widget.adminName.isNotEmpty
                  ? widget.adminName[0].toUpperCase()
                  : "A",
              style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6A8A73)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(widget.adminName,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        Center(
          child: Text("Administrator",
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 13)),
        ),
        const SizedBox(height: 32),
        _moreItem(Icons.logout_rounded, "Logout", Colors.red, () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        }),
      ],
    );
  }

  Widget _moreItem(IconData icon, String label, Color color,
      VoidCallback onTap) {
    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      color: Colors.white,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing:
            const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _miniChip(String label, IconData icon, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// =============================================================================
// ClassManagementPage
// =============================================================================
class ClassManagementPage extends StatefulWidget {
  final String classId;
  final Map<String, dynamic> classData;
  final String adminName;

  const ClassManagementPage({
    super.key,
    required this.classId,
    required this.classData,
    required this.adminName,
  });

  @override
  State<ClassManagementPage> createState() => _ClassManagementPageState();
}

class _ClassManagementPageState extends State<ClassManagementPage> {
  late Map<String, dynamic> _classData;

  @override
  void initState() {
    super.initState();
    _classData = Map<String, dynamic>.from(widget.classData);
  }

  String get _className =>
      _classData['className'] as String? ?? 'Class';
  String get _classCode =>
      _classData['classCode'] as String? ?? widget.classId;

  void _openBoundaryPicker() async {
    final boundary = _classData['boundary'];
    LatLng pos;
    if (boundary != null && boundary is Map) {
      pos = LatLng((boundary['lat'] as num).toDouble(),
          (boundary['lng'] as num).toDouble());
    } else {
      try {
        final loc = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        pos = LatLng(loc.latitude, loc.longitude);
      } catch (_) {
        pos = const LatLng(20.59, 78.96);
      }
    }
    if (!mounted) return;
    double radius = (boundary != null && boundary is Map)
        ? (boundary['radiusMeters'] as num).toDouble()
        : 100.0;
    LatLng current = pos;
    final MapController mapController = MapController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        content: SizedBox(
          height: 560,
          width: 600,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFF6A8A73),
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.my_location,
                        color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Set Class Boundary",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          Text(_className,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StatefulBuilder(builder: (ctx, setSt) {
                  return Stack(
                    children: [
                      FlutterMap(
                        mapController: mapController,
                        options: MapOptions(
                          initialCenter: pos,
                          initialZoom: 16,
                          onTap: (_, p) =>
                              setSt(() => current = p),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName:
                                'com.virtualvision.admin',
                          ),
                          CircleLayer(circles: [
                            CircleMarker(
                              point: current,
                              radius: radius,
                              useRadiusInMeter: true,
                              color: const Color(0xFF6A8A73)
                                  .withValues(alpha: 0.18),
                              borderColor: const Color(0xFF6A8A73),
                              borderStrokeWidth: 2,
                            ),
                          ]),
                          MarkerLayer(markers: [
                            Marker(
                              point: current,
                              width: 40,
                              height: 40,
                              child: const Icon(Icons.location_on,
                                  color: Colors.red, size: 40),
                            ),
                          ]),
                        ],
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20)),
                          ),
                          padding: const EdgeInsets.fromLTRB(
                              16, 12, 16, 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                const Icon(Icons.my_location,
                                    size: 13, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text(
                                  "${current.latitude.toStringAsFixed(5)}, "
                                  "${current.longitude.toStringAsFixed(5)}",
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight:
                                          FontWeight.w600),
                                ),
                              ]),
                              const SizedBox(height: 6),
                              Row(children: [
                                const Icon(
                                    Icons.radio_button_checked,
                                    size: 13,
                                    color: Color(0xFF6A8A73)),
                                const SizedBox(width: 6),
                                Text(
                                  "Radius: ${radius.toStringAsFixed(0)} m",
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight:
                                          FontWeight.w600),
                                ),
                                Expanded(
                                  child: Slider(
                                    value: radius,
                                    min: 30,
                                    max: 500,
                                    divisions: 47,
                                    activeColor:
                                        const Color(0xFF6A8A73),
                                    onChanged: (v) =>
                                        setSt(() => radius = v),
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF6A8A73),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(
                                                10)),
                                  ),
                                  onPressed: () async {
                                    final newBoundary = {
                                      'lat': current.latitude,
                                      'lng': current.longitude,
                                      'radiusMeters': radius,
                                    };
                                    await AppwriteService.databases
                                        .updateDocument(
                                      databaseId: '69ecebfb0033cf785741',
                                      collectionId: 'classes',
                                      documentId: widget.classId,
                                      data: {
                                        'boundary': newBoundary
                                      },
                                    );
                                    setState(() =>
                                        _classData['boundary'] =
                                            newBoundary);
                                    if (mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      "Boundary saved.")));
                                    }
                                  },
                                  child: const Text("Save Boundary",
                                      style: TextStyle(
                                          fontWeight:
                                              FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteClass() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Class?",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          "Deleting \"$_className\" will permanently remove the class, all its periods, and all linked attendance records. This cannot be undone.",
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white),
            child: const Text("Delete Class"),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    // Delete all periods for this class
    final periodsSnap = await AppwriteService.databases.listDocuments(
      databaseId: '69ecebfb0033cf785741',
      collectionId: 'periods',
      queries: [
        Query.equal('classId', widget.classId),
        Query.limit(5000),
      ],
    );
    for (final doc in periodsSnap.documents) {
      await AppwriteService.databases.deleteDocument(
        databaseId: '69ecebfb0033cf785741',
        collectionId: 'periods',
        documentId: doc.$id,
      );
    }

    // Delete all attendance logs for this class
    final logsSnap = await AppwriteService.databases.listDocuments(
      databaseId: '69ecebfb0033cf785741',
      collectionId: 'attendance_logs',
      queries: [
        Query.equal('classId', widget.classId),
        Query.limit(5000),
      ],
    );
    for (final doc in logsSnap.documents) {
      await AppwriteService.databases.deleteDocument(
        databaseId: '69ecebfb0033cf785741',
        collectionId: 'attendance_logs',
        documentId: doc.$id,
      );
    }

    // Delete the class document
    await AppwriteService.databases.deleteDocument(
      databaseId: '69ecebfb0033cf785741',
      collectionId: 'classes',
      documentId: widget.classId,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("\"$_className\" deleted.")));
    }
  }

  Future<void> _exportClassCSV() async {
    if (!Platform.isWindows &&
        !(await Permission.storage.request().isGranted)) {
      await Permission.manageExternalStorage.request();
    }
    final logsSnapshot = await AppwriteService.databases.listDocuments(
      databaseId: '69ecebfb0033cf785741',
      collectionId: 'attendance_logs',
      queries: [
        Query.equal('classId', widget.classId),
        Query.orderDesc('timestamp'),
        Query.limit(5000),
      ],
    );
    List<List<dynamic>> rows = [
      ["Student ID", "Class", "Date", "Time", "In Zone", "Verified"]
    ];
    for (final doc in logsSnapshot.documents) {
      final d = doc.data;
      final String? tsStr = d['timestamp'] as String?;
      final DateTime dt =
          tsStr != null ? DateTime.parse(tsStr) : DateTime.now();
      rows.add([
        d['userId'] ?? 'Unknown',
        d['className'] ?? _className,
        DateFormat('dd/MM/yyyy').format(dt),
        DateFormat('HH:mm').format(dt),
        d['isWithinGeofence'] == true ? 'Yes' : 'No',
        d['isVerified'] == true ? 'Yes' : 'No',
      ]);
    }
    final String csvData = const ListToCsvConverter().convert(rows);
    final Directory? dir = Platform.isWindows
        ? Directory(
            '${Platform.environment['USERPROFILE']}\\Downloads')
        : await getExternalStorageDirectory();
    if (dir == null) return;
    final path =
        "${dir.path}/${_className}_${DateTime.now().millisecondsSinceEpoch}.csv";
    await File(path).writeAsString(csvData);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Saved to $path")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> studentIds =
        _classData['studentIds'] as List<dynamic>? ?? [];
    final bool hasBoundary = _classData['boundary'] != null;

    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        title: Hero(
          tag: 'class_header_${widget.classId}',
          child: Material(
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_className,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17)),
                Text("Code: $_classCode",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.white60)),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.forum_outlined, color: Colors.white),
            tooltip: "Community",
            onPressed: () {
              final ids =
                  (_classData['studentIds'] as List<dynamic>? ?? [])
                      .cast<String>();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CommunityPage(
                    classId: widget.classId,
                    className: _className,
                    username: widget.adminName,
                    isAdmin: true,
                    studentIds: ids,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded,
                color: Colors.white),
            tooltip: "Export CSV",
            onPressed: _exportClassCSV,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Colors.redAccent),
            tooltip: "Delete Class",
            onPressed: _deleteClass,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FB),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(35)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(35)),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  children: [
                    // --- BOUNDARY CARD ---
                    _sectionCard(
                      icon: Icons.my_location,
                      title: "Class Boundary",
                      trailing: hasBoundary
                          ? _statusChip("Set", Colors.green)
                          : _statusChip("Not Set", Colors.orange),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasBoundary &&
                              _classData['boundary'] is Map) ...[
                            Text(
                              "Lat: ${(_classData['boundary']['lat'] as num).toStringAsFixed(5)},  "
                              "Lng: ${(_classData['boundary']['lng'] as num).toStringAsFixed(5)}",
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                  fontFamily: 'Courier'),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Radius: ${(_classData['boundary']['radiusMeters'] as num).toStringAsFixed(0)} m",
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12),
                            ),
                            const SizedBox(height: 12),
                          ],
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: Icon(hasBoundary
                                  ? Icons.edit_location_alt
                                  : Icons.add_location_alt),
                              label: Text(hasBoundary
                                  ? "Edit Boundary"
                                  : "Set Boundary"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF6A8A73),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(10)),
                              ),
                              onPressed: _openBoundaryPicker,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // --- STUDENTS CARD ---
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: 0.03),
                              blurRadius: 12,
                              offset: const Offset(0, 3))
                        ],
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          iconColor: const Color(0xFF6A8A73),
                          collapsedIconColor: Colors.grey,
                          tilePadding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 8),
                          title: Row(
                            children: [
                              const Icon(
                                  Icons.people_alt_outlined,
                                  color: Color(0xFF6A8A73),
                                  size: 20),
                              const SizedBox(width: 8),
                              const Text("Enrolled Students",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.black)),
                              const Spacer(),
                              _statusChip(
                                  "${studentIds.length}", Colors.blue),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  18, 0, 18, 18),
                              child: studentIds.isEmpty
                                  ? const Text(
                                      "No students enrolled yet.",
                                      style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 13))
                                  : FutureBuilder<models.DocumentList>(
                                      future: AppwriteService.databases
                                          .listDocuments(
                                        databaseId: '69ecebfb0033cf785741',
                                        collectionId: 'users',
                                        queries: [
                                          Query.equal('\$id',
                                              studentIds.cast<String>())
                                        ],
                                      ),
                                      builder: (context, snap) {
                                        if (!snap.hasData) {
                                          return const Center(
                                              child:
                                                  CircularProgressIndicator(
                                                      color: Color(
                                                          0xFF6A8A73)));
                                        }
                                        return Container(
                                          constraints:
                                              const BoxConstraints(
                                                  maxHeight: 300),
                                          child: ListView(
                                            shrinkWrap: true,
                                            children: snap
                                                .data!.documents
                                                .map((s) {
                                              final sd = s.data;
                                              return ListTile(
                                                contentPadding:
                                                    EdgeInsets.zero,
                                                dense: true,
                                                leading:
                                                    const CircleAvatar(
                                                  radius: 18,
                                                  backgroundColor:
                                                      Color(0xFFF1F4F2),
                                                  child: Icon(
                                                      Icons.person,
                                                      color: Color(
                                                          0xFF6A8A73),
                                                      size: 16),
                                                ),
                                                title: Text(
                                                    sd['name'] as String? ??
                                                        "Unknown",
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight
                                                                .w600,
                                                        fontSize: 13)),
                                                subtitle: Text(
                                                    "ID: ${sd['username'] as String? ?? s.$id}",
                                                    style:
                                                        const TextStyle(
                                                            fontSize:
                                                                11)),
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
                    ),

                    const SizedBox(height: 16),

                    // --- PERIODS MANAGEMENT CARD ---
                    _PeriodsManagementSection(
                      classId: widget.classId,
                      adminName: widget.adminName,
                      studentIds: studentIds.cast<String>(),
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

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
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
              Icon(icon, color: const Color(0xFF6A8A73), size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              if (trailing != null) ...[const Spacer(), trailing],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold)),
    );
  }
}

// =============================================================================
// _PeriodsManagementSection â€” already on Appwrite, preserved as-is
// =============================================================================
class _PeriodsManagementSection extends StatefulWidget {
  final String classId;
  final String adminName;
  final List<String> studentIds;

  const _PeriodsManagementSection({
    required this.classId,
    required this.adminName,
    required this.studentIds,
  });

  @override
  State<_PeriodsManagementSection> createState() =>
      _PeriodsManagementSectionState();
}

class _PeriodsManagementSectionState
    extends State<_PeriodsManagementSection> {
  Future<void> _deletePeriod(String pId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Period?",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            "This will permanently remove this session and all linked attendance records."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white),
            child: const Text("Delete Period"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final logsSnap = await AppwriteService.databases.listDocuments(
        databaseId: '69ecebfb0033cf785741',
        collectionId: 'attendance_logs',
        queries: [Query.equal('periodId', pId)],
      );
      for (final doc in logsSnap.documents) {
        await AppwriteService.databases.deleteDocument(
          databaseId: '69ecebfb0033cf785741',
          collectionId: 'attendance_logs',
          documentId: doc.$id,
        );
      }
      await AppwriteService.databases.deleteDocument(
        databaseId: '69ecebfb0033cf785741',
        collectionId: 'periods',
        documentId: pId,
      );
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                "Period and linked attendance records deleted.")));
      }
    }
  }

  Future<void> _openAddPeriodDialog(BuildContext context) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6A8A73),
              onPrimary: Colors.white,
              surface: Color(0xFF202020)),
        ),
        child: child!,
      ),
    );
    if (selectedDate == null) return;

    TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: TimeOfDay.now().hour, minute: 0),
      helpText: "Select Start Time",
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6A8A73),
              onPrimary: Colors.white,
              surface: Color(0xFF202020)),
        ),
        child: child!,
      ),
    );
    if (startTime == null) return;

    TimeOfDay? endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
          hour: (startTime.hour + 1) % 24, minute: startTime.minute),
      helpText: "Select End Time",
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6A8A73),
              onPrimary: Colors.white,
              surface: Color(0xFF202020)),
        ),
        child: child!,
      ),
    );
    if (endTime == null) return;

    final startDT = DateTime(selectedDate.year, selectedDate.month,
        selectedDate.day, startTime.hour, startTime.minute);
    final endDT = DateTime(selectedDate.year, selectedDate.month,
        selectedDate.day, endTime.hour, endTime.minute);

    if (endDT.isBefore(startDT) || endDT.isAtSameMomentAs(startDT)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("End time must be after start time.")));
      }
      return;
    }

    final periodsSnap = await AppwriteService.databases.listDocuments(
      databaseId: '69ecebfb0033cf785741',
      collectionId: 'periods',
      queries: [Query.equal('classId', widget.classId)],
    );

    bool overlap = false;
    for (final doc in periodsSnap.documents) {
      final data = doc.data;
      if (data['startTime'] == null || data['endTime'] == null) {
        continue;
      }
      final existingStart = DateTime.parse(data['startTime'] as String);
      final existingEnd = DateTime.parse(data['endTime'] as String);
      if (startDT.isBefore(existingEnd) &&
          endDT.isAfter(existingStart)) {
        overlap = true;
        break;
      }
    }

    if (overlap) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Period overlaps with an existing one.")));
      }
      return;
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    await AppwriteService.databases.createDocument(
      databaseId: '69ecebfb0033cf785741',
      collectionId: 'periods',
      documentId: ID.unique(),
      data: {
        'classId': widget.classId,
        'startTime': startDT.toIso8601String(),
        'endTime': endDT.toIso8601String(),
        'date': dateStr,
        'createdAt': DateTime.now().toIso8601String(),
      },
    );

    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Period created successfully.")));
    }
  }

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
              const Icon(Icons.access_time_filled,
                  color: Color(0xFF6A8A73), size: 20),
              const SizedBox(width: 8),
              const Text("Class Periods",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text("Add"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A8A73),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 36),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _openAddPeriodDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FutureBuilder<models.DocumentList>(
            future: AppwriteService.databases.listDocuments(
              databaseId: '69ecebfb0033cf785741',
              collectionId: 'periods',
              queries: [
                Query.equal('classId', widget.classId),
                Query.orderDesc('startTime'),
              ],
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF6A8A73)));
              }
              if (snapshot.data!.documents.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                      child: Text("No periods added yet.",
                          style: TextStyle(color: Colors.grey))),
                );
              }

              final Map<String, List<models.Document>> grouped = {};
              for (final doc in snapshot.data!.documents) {
                final dateStr =
                    doc.data['date'] as String? ?? 'Unknown Date';
                grouped.putIfAbsent(dateStr, () => []).add(doc);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: grouped.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 12, bottom: 8),
                        child: Text(entry.key,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade500,
                                fontSize: 13)),
                      ),
                      ...entry.value.map((doc) {
                        final data = doc.data;
                        final startTS = data['startTime'] != null
                            ? DateTime.parse(
                                data['startTime'] as String)
                            : null;
                        final endTS = data['endTime'] != null
                            ? DateTime.parse(data['endTime'] as String)
                            : null;
                        final String timeStr =
                            (startTS != null && endTS != null)
                                ? "${DateFormat('hh:mm a').format(startTS)} - ${DateFormat('hh:mm a').format(endTS)}"
                                : "Unknown Time";

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                  color: Colors.grey.shade200)),
                          elevation: 0,
                          color: Colors.grey.shade50,
                          child: ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                            leading: const Icon(Icons.class_,
                                color: Color(0xFF6A8A73), size: 24),
                            title: Text(timeStr,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                      size: 20),
                                  onPressed: () =>
                                      _deletePeriod(doc.$id),
                                ),
                                const Icon(Icons.chevron_right,
                                    color: Colors.grey),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PeriodAttendancePage(
                                    classId: widget.classId,
                                    periodId: doc.$id,
                                    periodData: data,
                                    studentIds: widget.studentIds,
                                    adminName: widget.adminName,
                                  ),
                                ),
                              );
                            },
                          ),
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
}

// =============================================================================
// PeriodAttendancePage â€” already on Appwrite, preserved as-is
// =============================================================================
class PeriodAttendancePage extends StatefulWidget {
  final String classId;
  final String periodId;
  final Map<String, dynamic> periodData;
  final List<String> studentIds;
  final String adminName;

  const PeriodAttendancePage({
    super.key,
    required this.classId,
    required this.periodId,
    required this.periodData,
    required this.studentIds,
    required this.adminName,
  });

  @override
  State<PeriodAttendancePage> createState() =>
      _PeriodAttendancePageState();
}

class _PeriodAttendancePageState extends State<PeriodAttendancePage> {
  void _showPhotoDialog(BuildContext context, String photoUrl) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        contentPadding: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(photoUrl, fit: BoxFit.cover),
        ),
      ),
    );
  }

  Future<void> _setStatus(
      String studentId, String? logDocId, String status) async {
    if (logDocId != null) {
      await AppwriteService.databases.updateDocument(
        databaseId: '69ecebfb0033cf785741',
        collectionId: 'attendance_logs',
        documentId: logDocId,
        data: {
          'adminVerifiedStatus': status,
          'isVerified': status == "Present" || status == "Late",
        },
      );
    } else {
      await AppwriteService.databases.createDocument(
        databaseId: '69ecebfb0033cf785741',
        collectionId: 'attendance_logs',
        documentId: ID.unique(),
        data: {
          'userId': studentId,
          'classId': widget.classId,
          'periodId': widget.periodId,
          'timestamp': DateTime.now().toIso8601String(),
          'photoUrl': '',
          'isWithinGeofence': false,
          'isVerified': status == "Present" || status == "Late",
          'adminVerifiedStatus': status,
          'entryStatus': "Manual Entry",
          'verifiedBy': widget.adminName,
          'className': '',
        },
      );
    }
    setState(() {});
  }

  Widget _statusButtons(
      String selectedStatus, String studentId, String? logDocId) {
    return Wrap(
      spacing: 6,
      children: [
        _StatusBtn(
            label: 'Present',
            color: Colors.green,
            selected: selectedStatus == 'Present',
            onTap: () => _setStatus(studentId, logDocId, 'Present')),
        _StatusBtn(
            label: 'Late',
            color: Colors.orange,
            selected: selectedStatus == 'Late',
            onTap: () => _setStatus(studentId, logDocId, 'Late')),
        _StatusBtn(
            label: 'Absent',
            color: Colors.red,
            selected: selectedStatus == 'Absent',
            onTap: () => _setStatus(studentId, logDocId, 'Absent')),
      ],
    );
  }

  Widget _photoAvatar(String photoUrl, BuildContext context) {
    if (photoUrl.isNotEmpty) {
      return GestureDetector(
        onTap: () => _showPhotoDialog(context, photoUrl),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(photoUrl,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder()),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10)),
      child: const Icon(Icons.person, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    final startTS = widget.periodData['startTime'] != null
        ? DateTime.parse(widget.periodData['startTime'] as String)
        : null;
    final endTS = widget.periodData['endTime'] != null
        ? DateTime.parse(widget.periodData['endTime'] as String)
        : null;
    final String timeStr = (startTS != null && endTS != null)
        ? "${DateFormat('hh:mm a').format(startTS)} - ${DateFormat('hh:mm a').format(endTS)}"
        : "Unknown Time";
    final String dateStr =
        widget.periodData['date'] as String? ?? 'Unknown Date';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Period Attendance",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Colors.black)),
              Text("$dateStr | $timeStr",
                  style:
                      const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: const TabBar(
            indicatorColor: Color(0xFF6A8A73),
            labelColor: Color(0xFF6A8A73),
            unselectedLabelColor: Colors.grey,
            labelStyle:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(text: "Reported"),
              Tab(text: "Not Reported"),
            ],
          ),
        ),
        body: FutureBuilder<models.DocumentList>(
          future: AppwriteService.databases.listDocuments(
            databaseId: '69ecebfb0033cf785741',
            collectionId: 'attendance_logs',
            queries: [Query.equal('periodId', widget.periodId)],
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF6A8A73)));
            }

            final Map<String, Map<String, dynamic>> logsMap = {};
            final Map<String, String> logDocIds = {};
            for (final doc in snapshot.data!.documents) {
              final data = doc.data;
              final uId = data['userId'] as String? ?? '';
              logsMap[uId] = data;
              logDocIds[uId] = doc.$id;
            }

            if (widget.studentIds.isEmpty) {
              return const Center(
                  child: Text(
                      "No students enrolled in this class.",
                      style: TextStyle(color: Colors.grey)));
            }

            final reported = widget.studentIds
                .where((id) => logsMap.containsKey(id))
                .toList();
            final notReported = widget.studentIds
                .where((id) => !logsMap.containsKey(id))
                .toList();

            return TabBarView(
              children: [
                // â”€â”€ Reported â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                reported.isEmpty
                    ? const Center(
                        child: Text(
                            "No students have reported yet.",
                            style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                            16, 16, 16, 32),
                        itemCount: reported.length,
                        itemBuilder: (context, index) {
                          final studentId = reported[index];
                          final logData = logsMap[studentId]!;
                          final logDocId = logDocIds[studentId];
                          final photoUrl =
                              logData['photoUrl'] as String? ?? '';
                          final entryStatus =
                              logData['entryStatus'] as String? ?? '';
                          final isInZone =
                              logData['isWithinGeofence'] == true;
                          String currentStatus =
                              logData['adminVerifiedStatus']
                                      as String? ??
                                  'Pending';
                          if (currentStatus == 'Pending') {
                            currentStatus =
                                entryStatus == 'Late Window'
                                    ? 'Late'
                                    : 'Present';
                          }

                          return FutureBuilder<models.Document>(
                            future: AppwriteService.databases
                                .getDocument(
                              databaseId: '69ecebfb0033cf785741',
                              collectionId: 'users',
                              documentId: studentId,
                            ),
                            builder: (context, userSnap) {
                              String studentName = studentId;
                              if (userSnap.hasData) {
                                studentName =
                                    userSnap.data!.data['name']
                                            as String? ??
                                        studentId;
                              }
                              return Card(
                                margin: const EdgeInsets.only(
                                    bottom: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(16)),
                                elevation: 0,
                                color: Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          _photoAvatar(
                                              photoUrl, context),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                              children: [
                                                Text(studentName,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight
                                                                .bold,
                                                        fontSize: 14)),
                                                const SizedBox(
                                                    height: 3),
                                                if (entryStatus
                                                    .isNotEmpty)
                                                  Text(
                                                    entryStatus,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight
                                                              .w600,
                                                      color: entryStatus ==
                                                              'Late Window'
                                                          ? Colors.orange
                                                          : const Color(
                                                              0xFF6A8A73),
                                                    ),
                                                  ),
                                                Row(children: [
                                                  Icon(
                                                      isInZone
                                                          ? Icons
                                                              .location_on
                                                          : Icons
                                                              .location_off,
                                                      size: 11,
                                                      color: isInZone
                                                          ? Colors.green
                                                          : Colors.red),
                                                  const SizedBox(
                                                      width: 3),
                                                  Text(
                                                      isInZone
                                                          ? "In Zone"
                                                          : "Out of Zone",
                                                      style: TextStyle(
                                                          fontSize: 11,
                                                          color: isInZone
                                                              ? Colors
                                                                  .green
                                                              : Colors
                                                                  .red)),
                                                ]),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      _statusButtons(currentStatus,
                                          studentId, logDocId),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),

                // â”€â”€ Not Reported â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                notReported.isEmpty
                    ? const Center(
                        child: Text("All students have reported.",
                            style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                            16, 16, 16, 32),
                        itemCount: notReported.length,
                        itemBuilder: (context, index) {
                          final studentId = notReported[index];
                          return FutureBuilder<models.Document>(
                            future: AppwriteService.databases
                                .getDocument(
                              databaseId: '69ecebfb0033cf785741',
                              collectionId: 'users',
                              documentId: studentId,
                            ),
                            builder: (context, userSnap) {
                              String studentName = studentId;
                              if (userSnap.hasData) {
                                studentName =
                                    userSnap.data!.data['name']
                                            as String? ??
                                        studentId;
                              }
                              return Card(
                                margin: const EdgeInsets.only(
                                    bottom: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(16)),
                                elevation: 0,
                                color: Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          _placeholder(),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                              children: [
                                                Text(studentName,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight
                                                                .bold,
                                                        fontSize: 14)),
                                                const SizedBox(
                                                    height: 3),
                                                const Text(
                                                    "No report submitted",
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        color:
                                                            Colors.grey)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      _statusButtons(
                                          "", studentId, null),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatusBtn extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _StatusBtn(
      {required this.label,
      required this.color,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color:
              selected ? color : color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected
                  ? color
                  : color.withValues(alpha: 0.25)),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : color),
        ),
      ),
    );
  }
}
