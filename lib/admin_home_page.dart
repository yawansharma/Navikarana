import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart'; 
import 'main.dart';

class AdminHomePage extends StatefulWidget {
  final String adminName;
  const AdminHomePage({super.key, required this.adminName});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _currentIndex = 0;
  DateTimeRange? _dateRange;

  // Helper function to extract shortforms from school names
  String _getShortSchoolName(String fullName) {
    // Logic: Look for text inside brackets
    if (fullName.contains('(') && fullName.contains(')')) {
      return fullName.substring(fullName.indexOf('(') + 1, fullName.indexOf(')'));
    }
    // Specific manual mapping for items without brackets
    if (fullName == "School of Law") return "Law";
    return fullName;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, userSnapshot) {
        Set<String> activeUserIds = {};
        if (userSnapshot.hasData) {
          for (var doc in userSnapshot.data!.docs) {
            activeUserIds.add(doc.id);
          }
        }

        return Scaffold(
          backgroundColor: const Color(0xFF101010),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false),
            ),
            actions: [
              if (_currentIndex == 0)
                IconButton(
                  icon: const Icon(Icons.calendar_month_outlined, color: Colors.white),
                  tooltip: "Filter Logs",
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(primary: Color(0xFF6A8A73), onPrimary: Colors.white, surface: Color(0xFF202020)),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) setState(() => _dateRange = picked);
                  },
                ),
              if (_dateRange != null && _currentIndex == 0)
                IconButton(icon: const Icon(Icons.close, color: Colors.redAccent), onPressed: () => setState(() => _dateRange = null))
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 25),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_currentIndex == 0 ? "Dashboard" : "Manage Users", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text("Welcome, ${widget.adminName}", style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                      ],
                    ),
                    const CircleAvatar(radius: 22, backgroundColor: Color(0xFF202020), child: Icon(Icons.admin_panel_settings, color: Colors.white70, size: 20))
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8F9FB), 
                    borderRadius: BorderRadius.vertical(top: Radius.circular(35))
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
                    child: _currentIndex == 0 ? _buildDashboard(activeUserIds) : _buildUsersTab(userSnapshot.hasData ? userSnapshot.data!.docs : []),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))]
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              backgroundColor: Colors.white,
              selectedItemColor: const Color(0xFF6A8A73),
              unselectedItemColor: Colors.grey.shade400,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: "Dashboard"),
                BottomNavigationBarItem(icon: Icon(Icons.group_outlined), label: "Users"),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDashboard(Set<String> activeUserIds) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF6A8A73), Color(0xFF567a61)]), 
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: const Color(0xFF6A8A73).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))]
            ),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Filter Status", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text(
                    _dateRange == null ? "Showing All Logs" : "${DateFormat('MMM dd').format(_dateRange!.start)} - ${DateFormat('MMM dd').format(_dateRange!.end)}",
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            children: [
              const Text("Recent Logs", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E))),
              const Spacer(),
              IconButton(icon: const Icon(Icons.download_rounded, color: Color(0xFF6A8A73)), onPressed: _exportLogsToCSV),
              IconButton(icon: const Icon(Icons.cleaning_services_rounded, color: Colors.grey), onPressed: () => _cleanupLogs(activeUserIds))
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('attendance_logs').orderBy('timestamp', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF6A8A73)));
              
              var logs = snapshot.data!.docs;

              if (_dateRange != null) {
                logs = logs.where((doc) {
                  if (doc['timestamp'] == null) return false;
                  DateTime dt = (doc['timestamp'] as Timestamp).toDate();
                  return dt.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) && 
                         dt.isBefore(_dateRange!.end.add(const Duration(days: 1)));
                }).toList();
              }

              if (logs.isEmpty) return const Center(child: Text("No records found for this period.", style: TextStyle(color: Colors.grey)));

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final logDoc = logs[index];
                  final data = logDoc.data() as Map<String, dynamic>;
                  bool isDeleted = !activeUserIds.contains(data['userId']);
                  bool isMismatch = data['status'] == "Location Mismatch";
                  bool isPresent = data['status'] == "Present";
                  DateTime date = data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate() : DateTime.now();
                  String photoBase64 = data['photoBase64'] ?? '';
                  double? latitude = data['location']?['lat'];
                  double? longitude = data['location']?['lng'];
                  
                  return _buildLogCard(
                    logDoc: logDoc,
                    data: data,
                    date: date,
                    photoBase64: photoBase64,
                    latitude: latitude,
                    longitude: longitude,
                    isMismatch: isMismatch,
                    isPresent: isPresent,
                    isDeleted: isDeleted,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLogCard({
    required DocumentSnapshot logDoc,
    required Map<String, dynamic> data,
    required DateTime date,
    required String photoBase64,
    required double? latitude,
    required double? longitude,
    required bool isMismatch,
    required bool isPresent,
    required bool isDeleted,
  }) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(data['userId']).get(),
      builder: (context, userSnapshot) {
        String department = "N/A";
        if (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          // MODIFICATION: Transform full school name to shortform
          department = _getShortSchoolName(userData?['department'] ?? "N/A");
        }

        String userId = data['userId'] ?? "Unknown";
        String deviceId = data['deviceId'] ?? _generateDeviceId(userId, date);
        
        Color statusColor = Colors.grey;
        if (isDeleted) statusColor = Colors.red;
        else if (isMismatch) statusColor = Colors.orange;
        else if (isPresent) statusColor = const Color(0xFF6A8A73);

        return StatefulBuilder(
          builder: (context, setCardState) {
            bool isExpanded = false;
            String adminNotes = data['adminNotes'] ?? '';
            String quickNotes = data['quickNotes'] ?? '';
            final TextEditingController notesController = TextEditingController(text: adminNotes);
            final TextEditingController quickNotesController = TextEditingController(text: quickNotes);

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 14, height: 14,
                        decoration: BoxDecoration(
                          color: statusColor, 
                          shape: BoxShape.circle, 
                          border: Border.all(color: statusColor.withOpacity(0.25), width: 4)
                        ),
                      ),
                      Expanded(child: Container(width: 2, color: Colors.grey.shade200)),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade100, width: 1),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 4))],
                      ),
                      child: StatefulBuilder(
                        builder: (context, setInnerState) => InkWell(
                          onTap: () => setInnerState(() => isExpanded = !isExpanded),
                          borderRadius: BorderRadius.circular(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    if (photoBase64.isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.memory(base64Decode(photoBase64), height: 56, width: 56, fit: BoxFit.cover),
                                      )
                                    else
                                      Container(
                                        height: 56, width: 56,
                                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
                                        child: const Icon(Icons.person, color: Colors.grey),
                                      ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(data['name'] ?? "Unknown", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF101010))),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              _buildStatusBadge(isMismatch, isPresent, isDeleted),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text("ID: $userId", style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontFamily: "Courier"), overflow: TextOverflow.ellipsis),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(DateFormat('hh:mm a').format(date), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2D3142))),
                                        Text(DateFormat('MMM dd').format(date), style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                                        const SizedBox(height: 4),
                                        Icon(isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade400, size: 20),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (isExpanded)
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFBFBFC),
                                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                                    border: Border(top: BorderSide(color: Colors.grey.shade100))
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            children: [
                                              _buildDataRow("School", department),
                                              const Divider(height: 16, color: Color(0xFFF0F0F0)),
                                              _buildDataRow("Device ID", deviceId),
                                              const Divider(height: 16, color: Color(0xFFF0F0F0)),
                                              _buildDataRow("Auth Status", _getAuthStatusText(isMismatch, isPresent, isDeleted)),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        if (latitude != null && longitude != null)
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 16),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(color: const Color(0xFF6A8A73).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                                  child: const Icon(Icons.location_on_outlined, color: Color(0xFF6A8A73), size: 20),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text("Location Coordinates", style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                                                      Text("$latitude, $longitude", style: const TextStyle(fontSize: 13, color: Color(0xFF101010), fontFamily: "Courier", fontWeight: FontWeight.bold)),
                                                    ],
                                                  ),
                                                ),
                                                IconButton(
                                                  onPressed: () => _openLocationMap(latitude, longitude),
                                                  icon: const Icon(Icons.map_rounded, color: Color(0xFF6A8A73)),
                                                  style: IconButton.styleFrom(backgroundColor: const Color(0xFF6A8A73).withOpacity(0.1)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        _buildNoteSection(
                                          icon: Icons.flash_on_rounded, 
                                          title: "Quick Notes", 
                                          controller: quickNotesController, 
                                          hint: "Add a quick remark...",
                                          onChanged: (val) => logDoc.reference.update({'quickNotes': val})
                                        ),
                                        const SizedBox(height: 12),
                                        _buildNoteSection(
                                          icon: Icons.admin_panel_settings_outlined, 
                                          title: "Admin Notes", 
                                          controller: notesController, 
                                          hint: "Add detailed notes...",
                                          onChanged: (val) => logDoc.reference.update({'adminNotes': val})
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNoteSection({required IconData icon, required String title, required TextEditingController controller, required String hint, required Function(String) onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.grey.shade600, size: 16),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: title == "Admin Notes" ? 3 : 2,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF6A8A73), width: 1.5)),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF101010)), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildStatusBadge(bool isMismatch, bool isPresent, bool isDeleted) {
    late Color badgeColor;
    late Color textColor;
    late IconData icon;
    late String label;

    if (isDeleted) {
      badgeColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
      icon = Icons.error_outline;
      label = "Deleted";
    } else if (isMismatch) {
      badgeColor = Colors.orange.shade50;
      textColor = Colors.orange.shade800;
      icon = Icons.warning_amber_rounded;
      label = "Mismatch";
    } else if (isPresent) {
      badgeColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
      icon = Icons.check_circle_outline;
      label = "Present";
    } else {
      badgeColor = Colors.grey.shade100;
      textColor = Colors.grey.shade700;
      icon = Icons.help_outline;
      label = "Unknown";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 12),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }

  void _openLocationMap(double latitude, double longitude) {
    LatLng location = LatLng(latitude, longitude);
    MapController mapController = MapController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SizedBox(
          height: 450, width: 600,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(initialCenter: location, initialZoom: 17),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.virtualvision.admin'),
                MarkerLayer(markers: [Marker(point: location, width: 40, height: 40, child: const Icon(Icons.location_on, color: Color(0xFF6A8A73), size: 40))]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _generateDeviceId(String userId, DateTime date) {
    String userPart = userId.length >= 5 ? userId.substring(0, 5).toUpperCase() : userId.toUpperCase();
    while (userPart.length < 5) userPart = userPart + '_';
    String dateStr = "${date.year % 100}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}";
    String deviceId = "$userPart-$dateStr";
    return deviceId.length > 12 ? deviceId.substring(0, 12) : deviceId;
  }

  String _getAuthStatusText(bool isMismatch, bool isPresent, bool isDeleted) {
    if (isDeleted) return "User Deleted";
    if (isMismatch) return "Location Mismatch";
    if (isPresent) return "Verified";
    return "Unknown";
  }

  Future<void> _exportLogsToCSV() async {
    if (!Platform.isWindows && !(await Permission.storage.request().isGranted)) await Permission.manageExternalStorage.request();
    final logsSnapshot = await FirebaseFirestore.instance.collection('attendance_logs').orderBy('timestamp', descending: true).get();
    List<List<dynamic>> rows = [["Name", "ID", "Date", "Time", "Status", "Lat", "Lng"]];
    var docs = logsSnapshot.docs;

    if (_dateRange != null) {
      docs = docs.where((doc) {
        if (doc['timestamp'] == null) return false;
        DateTime dt = (doc['timestamp'] as Timestamp).toDate();
        return dt.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) && dt.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    for (var doc in docs) {
      Map<String, dynamic> d = doc.data();
      DateTime dt = d['timestamp'] != null ? (d['timestamp'] as Timestamp).toDate() : DateTime.now();
      String department = "N/A";
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(d['userId']).get();
        if (userDoc.exists) department = userDoc.data()?['department'] ?? "N/A";
      } catch (e) {
        department = "N/A";
      }

      String userIdForDevice = d['userId'] as String? ?? 'UNKN';
      String userPart = userIdForDevice.length >= 5 ? userIdForDevice.substring(0, 5).toUpperCase() : userIdForDevice.toUpperCase();
      while (userPart.length < 5) userPart = userPart + '_';
      String deviceId = d['deviceId'] ?? "$userPart-${dt.year % 100}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}";
      if (deviceId.length > 12) deviceId = deviceId.substring(0, 12);
      String authStatus = d['status'] == 'Location Mismatch' ? 'Location Mismatch' : (d['status'] == 'Present' ? 'Verified' : 'Unknown');

      rows.add(["${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}", d['userId'] ?? 'Unknown', d['name'] ?? 'Unknown', department, deviceId, authStatus, d['location']?['lat'] ?? '', d['location']?['lng'] ?? '', d['quickNotes'] ?? '', d['adminNotes'] ?? '']);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    Directory? dir = Platform.isWindows ? Directory('${Platform.environment['USERPROFILE']}\\Downloads') : await getExternalStorageDirectory();
    if (dir == null) return;
    final path = "${dir.path}/report_${DateTime.now().millisecondsSinceEpoch}.csv";
    await File(path).writeAsString(csvData);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Saved to $path")));
  }

  Future<void> _cleanupLogs(Set<String> activeIds) async {
    final logs = await FirebaseFirestore.instance.collection('attendance_logs').get();
    for (var doc in logs.docs) {
      if (!activeIds.contains(doc['userId'])) await doc.reference.delete();
    }
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Logs cleaned")));
  }

  Widget _buildUsersTab(List<QueryDocumentSnapshot> users) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final data = users[index].data() as Map<String, dynamic>;
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ExpansionTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFFF1F4F2), child: Icon(Icons.person, color: Color(0xFF6A8A73))),
            title: Text(data['name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("ID: ${data['username']}"),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A8A73), foregroundColor: Colors.white, minimumSize: const Size.fromHeight(45), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () => _openBoundaryPicker(context, data, users[index].id, data['name'] ?? "Unknown"), child: const Text("Set Boundary")),
                  const SizedBox(height: 8),
                  TextButton(onPressed: () => FirebaseFirestore.instance.collection('users').doc(users[index].id).delete(), child: const Text("Delete User", style: TextStyle(color: Colors.red)))
                ]),
              )
            ],
          ),
        );
      },
    );
  }

  void _openBoundaryPicker(BuildContext context, Map<String, dynamic> userData, String userId, String fullName) {
    LatLng pos = userData['boundary'] != null ? LatLng(userData['boundary']['lat'], userData['boundary']['lng']) : LatLng(userData['latitude'] ?? 20.59, userData['longitude'] ?? 78.96);
    LatLng current = pos;
    MapController mapController = MapController();
    showDialog(context: context, builder: (_) => AlertDialog(
      contentPadding: EdgeInsets.zero, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), 
      content: SizedBox(height: 500, width: 600, child: Column(children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF6A8A73),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))
          ),
          child: Row(children: [
            const Icon(Icons.person, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Set Boundary", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
              Text(fullName, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ])),
            IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
          ]),
        ),
        Expanded(
          child: StatefulBuilder(builder: (ctx, setSt) => Stack(children: [
            FlutterMap(
              mapController: mapController,
              options: MapOptions(initialCenter: pos, initialZoom: 15, onTap: (_, p) => setSt(() => current = p)),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.virtualvision.admin'),
                MarkerLayer(markers: [Marker(point: current, width: 40, height: 40, child: const Icon(Icons.location_on, color: Colors.red, size: 40))])
              ],
            ),
            Positioned(bottom: 0, left: 0, right: 0, child: Container(
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))), 
              padding: const EdgeInsets.all(12), 
              child: Row(children: [
                Expanded(child: InkWell(
                  onTap: () async {
                    final latC = TextEditingController(text: current.latitude.toString());
                    final lngC = TextEditingController(text: current.longitude.toString());
                    await showDialog(context: context, builder: (c) => AlertDialog(
                      title: const Text("Coordinates"),
                      content: Column(mainAxisSize: MainAxisSize.min, children: [
                        TextField(controller: latC, decoration: const InputDecoration(labelText: "Latitude")),
                        TextField(controller: lngC, decoration: const InputDecoration(labelText: "Longitude"))
                      ]),
                      actions: [
                        ElevatedButton(onPressed: (){
                          final la = double.tryParse(latC.text);
                          final ln = double.tryParse(lngC.text);
                          if(la!=null&&ln!=null) {
                            setSt(() {
                              current = LatLng(la, ln);
                              mapController.move(current, 15);
                            });
                          }
                          Navigator.pop(c);
                        }, child: const Text("Update"))
                      ],
                    ));
                  },
                  child: Text("${current.latitude.toStringAsFixed(5)}, ${current.longitude.toStringAsFixed(5)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))
                )),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A8A73), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: () {
                    FirebaseFirestore.instance.collection('users').doc(userId).update({'boundary': {'lat': current.latitude, 'lng': current.longitude}});
                    Navigator.pop(context);
                  },
                  child: const Text("Save", style: TextStyle(color: Colors.white))
                )
              ])
            ))
          ]))
        ),
      ]))
    ));
  }
}