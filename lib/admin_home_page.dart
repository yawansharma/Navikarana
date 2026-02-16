import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'main.dart';

class AdminHomePage extends StatefulWidget {
  final String adminName;
  const AdminHomePage({super.key, required this.adminName});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _currentIndex = 0;
  DateTimeRange? _dateRange; // 📅 1. DATE FILTER STATE

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
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false),
            ),
            actions: [
              // 📅 2. CALENDAR BUTTON
              if (_currentIndex == 0)
                IconButton(
                  icon: const Icon(Icons.calendar_today, color: Colors.white),
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
                IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => setState(() => _dateRange = null))
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_currentIndex == 0 ? "Dashboard" : "Manage Users", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text("Welcome, ${widget.adminName}", style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                      ],
                    ),
                    const CircleAvatar(radius: 20, backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white))
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    child: _currentIndex == 0 ? _buildDashboard(activeUserIds) : _buildUsersTab(userSnapshot.hasData ? userSnapshot.data!.docs : []),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            selectedItemColor: const Color(0xFF6A8A73),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: "Dashboard"),
              BottomNavigationBarItem(icon: Icon(Icons.group_outlined), label: "Users"),
            ],
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
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6A8A73), Color(0xFF567a61)]), borderRadius: BorderRadius.circular(20)),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Filter Status", style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 5),
                  // 📅 3. DISPLAY ACTIVE FILTER
                  Text(
                    _dateRange == null ? "Showing All Logs" : "${_dateRange!.start.day}/${_dateRange!.start.month} - ${_dateRange!.end.day}/${_dateRange!.end.month}",
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
              const Text("Recent Logs", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.download, color: Color(0xFF6A8A73)), onPressed: _exportLogsToCSV),
              IconButton(icon: const Icon(Icons.cleaning_services_outlined, color: Colors.grey), onPressed: () => _cleanupLogs(activeUserIds))
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('attendance_logs').orderBy('timestamp', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              
              var logs = snapshot.data!.docs;

              // 📅 4. APPLY FILTER TO LIST VIEW
              if (_dateRange != null) {
                logs = logs.where((doc) {
                  if (doc['timestamp'] == null) return false;
                  DateTime dt = (doc['timestamp'] as Timestamp).toDate();
                  return dt.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) && 
                         dt.isBefore(_dateRange!.end.add(const Duration(days: 1)));
                }).toList();
              }

              if (logs.isEmpty) return const Center(child: Text("No records found for this period."));

              return ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: logs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final data = logs[index].data() as Map<String, dynamic>;
                  bool isDeleted = !activeUserIds.contains(data['userId']);
                  bool isMismatch = data['status'] == "Location Mismatch";
                  DateTime date = data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate() : DateTime.now();
                  
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDeleted ? Colors.red.shade50 : (isMismatch ? Colors.orange.shade50 : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200)
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            height: 60, width: 60,
                            child: (data['photoBase64'] != null) ? Image.memory(base64Decode(data['photoBase64']), fit: BoxFit.cover) : const Icon(Icons.person)
                          )
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(data['name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text("${date.day}/${date.month} ${date.hour}:${date.minute}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(data['status'] ?? "", style: TextStyle(fontSize: 12, color: isMismatch ? Colors.orange : Colors.grey)),
                        ])),
                        if (isMismatch) const Icon(Icons.warning, color: Colors.orange)
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _exportLogsToCSV() async {
    if (!Platform.isWindows && !(await Permission.storage.request().isGranted)) await Permission.manageExternalStorage.request();
    
    final logsSnapshot = await FirebaseFirestore.instance.collection('attendance_logs').orderBy('timestamp', descending: true).get();
    List<List<dynamic>> rows = [["Name", "ID", "Date", "Time", "Status", "Lat", "Lng"]];
    
    var docs = logsSnapshot.docs;

    // 📅 5. APPLY FILTER TO CSV EXPORT
    if (_dateRange != null) {
      docs = docs.where((doc) {
        if (doc['timestamp'] == null) return false;
        DateTime dt = (doc['timestamp'] as Timestamp).toDate();
        return dt.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) && 
               dt.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    for (var doc in docs) {
      Map<String, dynamic> d = doc.data();
      DateTime dt = d['timestamp'] != null ? (d['timestamp'] as Timestamp).toDate() : DateTime.now();
      rows.add([d['name'], d['username'], "${dt.day}/${dt.month}/${dt.year}", "${dt.hour}:${dt.minute}", d['status'], d['location']?['lat'], d['location']?['lng']]);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    Directory? dir = Platform.isWindows ? Directory('${Platform.environment['USERPROFILE']}\\Downloads') : await getExternalStorageDirectory();
    if (dir == null) return;
    
    final path = "${dir.path}/report_${DateTime.now().millisecondsSinceEpoch}.csv";
    await File(path).writeAsString(csvData);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Saved to $path")));
  }

  // ... (Keep _cleanupLogs, _buildUsersTab, _buildUserCard, _deleteUser, _openBoundaryPicker exactly as they were)
  // Included purely for context, no changes needed below this line.
  Future<void> _cleanupLogs(Set<String> activeIds) async {
    final logs = await FirebaseFirestore.instance.collection('attendance_logs').get();
    for (var doc in logs.docs) {
      if (!activeIds.contains(doc['userId'])) await doc.reference.delete();
    }
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Logs cleaned")));
  }

  Widget _buildUsersTab(List<QueryDocumentSnapshot> users) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final data = users[index].data() as Map<String, dynamic>;
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ExpansionTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFFE0E0E0), child: Icon(Icons.person, color: Color(0xFF6A8A73))),
            title: Text(data['name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("ID: ${data['username']}"),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A8A73), foregroundColor: Colors.white), onPressed: () => _openBoundaryPicker(context, data, users[index].id), child: const Text("Set Boundary")),
                  TextButton(onPressed: () => FirebaseFirestore.instance.collection('users').doc(users[index].id).delete(), child: const Text("Delete User", style: TextStyle(color: Colors.red)))
                ]),
              )
            ],
          ),
        );
      },
    );
  }

  void _openBoundaryPicker(BuildContext context, Map<String, dynamic> userData, String userId) {
    LatLng pos = userData['boundary'] != null ? LatLng(userData['boundary']['lat'], userData['boundary']['lng']) : LatLng(userData['latitude'] ?? 20.59, userData['longitude'] ?? 78.96);
    LatLng current = pos;
    MapController mapController = MapController();
    showDialog(context: context, builder: (_) => AlertDialog(contentPadding: EdgeInsets.zero, content: SizedBox(height: 450, width: 600, child: StatefulBuilder(builder: (ctx, setSt) => Stack(children: [FlutterMap(mapController: mapController, options: MapOptions(initialCenter: pos, initialZoom: 15, onTap: (_, p) => setSt(() => current = p)), children: [TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.virtualvision.admin', tileProvider: NetworkTileProvider(headers: {'User-Agent': 'VirtualVisionAdmin/1.0'})), MarkerLayer(markers: [Marker(point: current, width: 40, height: 40, child: const Icon(Icons.location_on, color: Colors.red, size: 40))])]), Positioned(bottom: 0, left: 0, right: 0, child: Container(color: Colors.white, padding: const EdgeInsets.all(8), child: Row(children: [Expanded(child: InkWell(onTap: () async { final latC = TextEditingController(text: current.latitude.toString()); final lngC = TextEditingController(text: current.longitude.toString()); await showDialog(context: context, builder: (c) => AlertDialog(title: const Text("Coords"), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: latC, decoration: const InputDecoration(labelText: "Lat")), TextField(controller: lngC, decoration: const InputDecoration(labelText: "Lng"))]), actions: [ElevatedButton(onPressed: (){ final la = double.tryParse(latC.text); final ln = double.tryParse(lngC.text); if(la!=null&&ln!=null) { setSt(() { current = LatLng(la, ln); mapController.move(current, 15); }); } Navigator.pop(c); }, child: const Text("Go"))])); }, child: Text("${current.latitude.toStringAsFixed(5)}, ${current.longitude.toStringAsFixed(5)} (Tap to edit)", style: const TextStyle(fontWeight: FontWeight.bold)))), ElevatedButton(onPressed: () { FirebaseFirestore.instance.collection('users').doc(userId).update({'boundary': {'lat': current.latitude, 'lng': current.longitude}}); Navigator.pop(context); }, child: const Text("Save"))])))],))),));
  }
}