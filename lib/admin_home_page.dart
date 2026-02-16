import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart'; 
import 'package:latlong2/latlong.dart'; 
import 'main.dart'; 

class AdminHomePage extends StatefulWidget {
  final String adminName;

  const AdminHomePage({super.key, required this.adminName});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _currentIndex = 0;

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
              tooltip: "Logout",
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false, 
                );
              },
            ),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentIndex == 0 ? "Dashboard" : "Manage Users",
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text("Welcome, ${widget.adminName}", style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF6A8A73), width: 2)),
                      child: const CircleAvatar(radius: 20, backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white)),
                    )
                  ],
                ),
              ),

              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                    child: _currentIndex == 0 
                        ? _buildDashboard(activeUserIds) 
                        : _buildUsersTab(userSnapshot.hasData ? userSnapshot.data!.docs : []),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.black12))),
            child: BottomNavigationBar(
              backgroundColor: Colors.white,
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              selectedItemColor: const Color(0xFF6A8A73),
              unselectedItemColor: Colors.grey.shade400,
              elevation: 0,
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
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF6A8A73), Color(0xFF567a61)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: const Color(0xFF6A8A73).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("Live Attendance", style: TextStyle(color: Colors.white70, fontSize: 14)),
                SizedBox(height: 5),
                Text("System Active", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            children: [
              const Icon(Icons.history, color: Colors.black87),
              const SizedBox(width: 8),
              const Text("Recent Logs", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.cleaning_services_outlined, color: Colors.grey, size: 20),
                tooltip: "Clean logs of deleted users",
                onPressed: () => _cleanupLogs(activeUserIds),
              )
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('attendance_logs').orderBy('timestamp', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF6A8A73)));
              final logs = snapshot.data!.docs;
              if (logs.isEmpty) return Center(child: Text("No attendance records found.", style: TextStyle(color: Colors.grey.shade500)));
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
                itemCount: logs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final data = logs[index].data() as Map<String, dynamic>;
                  String userId = data['userId'] ?? "";
                  bool isDeleted = !activeUserIds.contains(userId);
                  String status = data['status'] ?? "Present";
                  bool isMismatch = status == "Location Mismatch";
                  Color cardColor;
                  Color borderColor;
                  if (isDeleted) {
                    cardColor = Colors.red.shade50;
                    borderColor = Colors.red.shade200;
                  } else if (isMismatch) {
                    cardColor = Colors.orange.shade50;
                    borderColor = Colors.orange.shade200;
                  } else {
                    cardColor = Colors.white;
                    borderColor = Colors.grey.shade200;
                  }
                  String nameText = isDeleted ? "${data['name']} (Deleted)" : "${data['name']}";
                  DateTime date = DateTime.now();
                  if (data['timestamp'] != null) {
                    date = (data['timestamp'] as Timestamp).toDate();
                  }
                  String timeString = "${date.hour}:${date.minute.toString().padLeft(2, '0')}  ${date.day}/${date.month}";
                  String locString = "Unknown";
                  if (data['location'] != null) {
                    locString = "Lat: ${data['location']['lat'].toStringAsFixed(4)}, Lng: ${data['location']['lng'].toStringAsFixed(4)}";
                  }
                  Widget imageWidget;
                  if (data['photoBase64'] != null && data['photoBase64'].toString().isNotEmpty) {
                    try {
                      imageWidget = Image.memory(base64Decode(data['photoBase64']), fit: BoxFit.cover);
                    } catch (e) {
                      imageWidget = const Icon(Icons.broken_image, color: Colors.grey);
                    }
                  } else {
                    imageWidget = const Icon(Icons.person, color: Colors.grey);
                  }
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(height: 60, width: 60, child: imageWidget)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(nameText, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDeleted ? Colors.red.shade700 : Colors.black87)),
                              const SizedBox(height: 4),
                              Row(children: [const Icon(Icons.access_time, size: 14, color: Colors.grey), const SizedBox(width: 4), Text(timeString, style: const TextStyle(color: Colors.black54, fontSize: 13))]),
                              const SizedBox(height: 4),
                              Row(children: [const Icon(Icons.location_on, size: 14, color: Colors.grey), const SizedBox(width: 4), Text(locString, style: TextStyle(color: isMismatch ? Colors.orange.shade800 : Colors.grey.shade600, fontSize: 11))]),
                            ],
                          ),
                        ),
                        if (isMismatch) const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24)
                        else if (isDeleted) const Icon(Icons.delete_forever, color: Colors.red, size: 24)
                        else const Icon(Icons.check_circle_outline, color: Color(0xFF6A8A73), size: 24),
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

  Future<void> _cleanupLogs(Set<String> activeIds) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clean Old Logs?"),
        content: const Text("This will permanently delete logs of removed users."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context, true), child: const Text("Delete Logs", style: TextStyle(color: Colors.white))),
        ],
      ),
    ) ?? false;
    if (!confirm) return;
    final logs = await FirebaseFirestore.instance.collection('attendance_logs').get();
    int deletedCount = 0;
    for (var doc in logs.docs) {
      if (!activeIds.contains(doc['userId'])) {
        await doc.reference.delete();
        deletedCount++;
      }
    }
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Deleted $deletedCount orphaned logs.")));
  }

  Widget _buildUsersTab(List<QueryDocumentSnapshot> users) {
    if (users.isEmpty) return const Center(child: Text("No active users found", style: TextStyle(color: Colors.grey)));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final doc = users[index];
        final data = doc.data() as Map<String, dynamic>;
        return _buildUserCard(data, doc.id);
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> data, String userId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(backgroundColor: const Color(0xFF6A8A73).withOpacity(0.1), child: const Icon(Icons.person_outline, color: Color(0xFF6A8A73))),
        title: Text(data['name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("ID: ${data['username'] ?? 'No ID'}", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: const Icon(Icons.map_outlined, size: 18), label: const Text("Set Safe Boundary"), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A8A73), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () => _openBoundaryPicker(context, data, userId))),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: TextButton.icon(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), label: const Text("Delete User", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)), style: TextButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () => _deleteUser(userId, data['name'] ?? "User"))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(String userId, String userName) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete User?"),
        content: Text("Delete $userName permanently?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.white))),
        ],
      ),
    ) ?? false;
    if (confirm) {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User deleted")));
    }
  }

  // ---------------------------------------------------------------------------
  // 📍 UPDATED BOUNDARY LOGIC - FIXED TILE LOADING
  // ---------------------------------------------------------------------------
  void _openBoundaryPicker(BuildContext context, Map<String, dynamic> userData, String userId) {
    LatLng selectedLocation;
    if (userData['boundary'] != null) {
      selectedLocation = LatLng(userData['boundary']['lat'], userData['boundary']['lng']);
    } else {
      selectedLocation = LatLng(userData['latitude'] ?? 20.5937, userData['longitude'] ?? 78.9629);
    }

    final MapController mapController = MapController();

    showDialog(
      context: context,
      builder: (_) {
        LatLng currentSelection = selectedLocation;
        LatLng cursorLocation = selectedLocation; 

        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: SizedBox(
            height: 450,
            width: 600,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: StatefulBuilder(
                builder: (context, setStateMap) {
                  return Stack(
                    children: [
                      FlutterMap(
                        mapController: mapController,
                        options: MapOptions(
                          initialCenter: selectedLocation,
                          initialZoom: 15.0,
                          onTap: (tapPosition, point) {
                            setStateMap(() {
                              currentSelection = point;
                              cursorLocation = point; 
                            });
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            // ✅ CRITICAL FIX: EXPLICIT HEADERS TO PREVENT BLOCKING
                            tileProvider: NetworkTileProvider(
                              headers: {
                                'User-Agent': 'com.example.employee_tracker/1.0.0 (flutter_map)',
                              },
                            ),
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: currentSelection,
                                width: 40,
                                height: 40,
                                child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      // FOOTER 
                      Positioned(
                        bottom: 0, left: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))]
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final latController = TextEditingController(text: currentSelection.latitude.toString());
                                    final lngController = TextEditingController(text: currentSelection.longitude.toString());
                                    
                                    await showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text("Enter Precise Coordinates"),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextField(controller: latController, decoration: const InputDecoration(labelText: "Latitude")),
                                            TextField(controller: lngController, decoration: const InputDecoration(labelText: "Longitude")),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                                          ElevatedButton(
                                            onPressed: () {
                                              final lat = double.tryParse(latController.text);
                                              final lng = double.tryParse(lngController.text);
                                              if (lat != null && lng != null) {
                                                setStateMap(() {
                                                  currentSelection = LatLng(lat, lng);
                                                  mapController.move(currentSelection, 15);
                                                });
                                              }
                                              Navigator.pop(ctx);
                                            },
                                            child: const Text("Go to Location"),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("Target Coordinates (Tap to edit)", style: TextStyle(fontSize: 10, color: Colors.grey)),
                                      Text(
                                        "${currentSelection.latitude.toStringAsFixed(6)}, ${currentSelection.longitude.toStringAsFixed(6)}",
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF6A8A73)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A8A73), foregroundColor: Colors.white),
                                onPressed: () async {
                                  await FirebaseFirestore.instance.collection('users').doc(userId).update({
                                    'boundary': {'lat': currentSelection.latitude, 'lng': currentSelection.longitude}
                                  });
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Workplace Boundary Saved!")));
                                  }
                                },
                                child: const Text("Save Boundary"),
                              )
                            ],
                          ),
                        ),
                      )
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}