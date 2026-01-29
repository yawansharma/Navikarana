import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
    return Scaffold(
      body: _currentIndex == 0 ? _home() : _usersList(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Users"),
        ],
      ),
    );
  }

  // ---------------- HOME TAB ----------------
  Widget _home() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.admin_panel_settings,
              size: 80, color: Colors.white),
          const SizedBox(height: 20),
          const Text(
            "Welcome Admin",
            style: TextStyle(color: Colors.white70, fontSize: 20),
          ),
          const SizedBox(height: 6),
          Text(
            widget.adminName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- USERS LIST TAB ----------------
  Widget _usersList() {
    return Scaffold(
      appBar: AppBar(title: const Text("Users")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          if (users.isEmpty) {
            return const Center(child: Text("No users found"));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final doc = users[index];
              final data = doc.data() as Map<String, dynamic>;
              return _userCard(data, doc.id);
            },
          );
        },
      ),
    );
  }

  // ---------------- USER CARD ----------------
  Widget _userCard(Map<String, dynamic> data, String userId) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ExpansionTile(
        leading: const Icon(Icons.person),
        title: Text(data['name'] ?? "Unknown"),
        subtitle: const Text("Tap to expand"),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Latitude: ${data['latitude']}"),
                Text("Longitude: ${data['longitude']}"),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.location_on),
                    label: const Text("Set Boundary"),
                    onPressed: () {
                      _openBoundaryPicker(context, data, userId);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- MAP POPUP ----------------
  void _openBoundaryPicker(
    BuildContext context,
    Map<String, dynamic> userData,
    String userId,
  ) {
    LatLng selectedLocation = LatLng(
      userData['latitude'],
      userData['longitude'],
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: Text("Set Boundary for ${userData['name']}"),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: StatefulBuilder(
              builder: (context, setState) {
                return GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: selectedLocation,
                    zoom: 15,
                  ),
                  onTap: (latLng) {
                    setState(() {
                      selectedLocation = latLng;
                    });
                  },
                  markers: {
                    Marker(
                      markerId: const MarkerId("boundary"),
                      position: selectedLocation,
                    )
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .update({
                  'boundary': {
                    'lat': selectedLocation.latitude,
                    'lng': selectedLocation.longitude,
                  }
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Boundary updated")),
                );
              },
              child: const Text("Save Boundary"),
            ),
          ],
        );
      },
    );
  }
}
