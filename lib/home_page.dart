import 'dart:io';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:unknown/eye_test_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';

class HomePage extends StatelessWidget {
  final String name;
  final double latitude;
  final double longitude;
  final File? photo; // ✅ NEW

  const HomePage({
    super.key,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.photo,
  });

  // 🧪 OPEN EYE TEST WINDOW (CENTERED)
  Future<void> _openEyeTest() async {
    if (!Platform.isWindows) return;

    final htmlPath =
        '${Directory.current.path}\\windows\\runner\\resources\\camera.html';

    await launchUrl(
      Uri.file(htmlPath),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            Text(
              "Welcome, $name 👋",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // 📸 SHOW PHOTO
            if (photo != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  photo!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              const Text("No photo available"),

            const SizedBox(height: 30),

            _infoTile("Latitude", latitude.toString()),
            const SizedBox(height: 10),
            _infoTile("Longitude", longitude.toString()),

            const SizedBox(height: 40),

            // 🧪 EYE TEST BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
  icon: const Icon(Icons.visibility),
  label: const Text(
    "Perform Eye Test",
    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  ),
  onPressed: () async {
    final htmlPath =
        '${Directory.current.path}\\windows\\runner\\resources\\camera.html';

    await launchUrl(
      Uri.file(htmlPath),
      mode: LaunchMode.externalApplication,
    );
  },
),


            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(
            "$label:",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
