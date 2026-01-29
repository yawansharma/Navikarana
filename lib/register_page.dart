import 'dart:io';
import 'dart:io' show Platform;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'camera_page.dart';
import 'home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final nameController = TextEditingController();
  final idController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  File? _localPhoto; // UI ONLY
  double? latitude;
  double? longitude;

  bool _fetchingLocation = false;

  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  // 📸 PHOTO PICK
  Future<void> _pickPhoto() async {
  if (!Platform.isWindows) {
    final XFile? photo =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() => _localPhoto = File(photo.path));
    }
    return;
  }

  final htmlPath =
      '${Directory.current.path}\\windows\\runner\\resources\\camera.html';

  await launchUrl(
    Uri.file(htmlPath),
    mode: LaunchMode.externalApplication,
  );

  final downloadsDir =
      Directory('${Platform.environment['USERPROFILE']}\\Downloads');

  final startTime = DateTime.now();

  // 🔁 POLL for up to 15 seconds
  while (DateTime.now().difference(startTime).inSeconds < 15) {
    final files = downloadsDir
        .listSync()
        .whereType<File>()
        .where((f) =>
            f.path.endsWith('captured_photo.png') &&
            f.lastModifiedSync().isAfter(startTime))
        .toList();

    if (files.isNotEmpty) {
      setState(() => _localPhoto = files.first);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("📸 Photo captured successfully")),
      );
      return;
    }

    await Future.delayed(const Duration(milliseconds: 500));
  }

  // ❌ Timeout
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("❌ Photo capture timed out")),
  );
}



  // 📍 LOCATION
  Future<void> _getCurrentLocation() async {
    setState(() => _fetchingLocation = true);

    bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      setState(() => _fetchingLocation = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() => _fetchingLocation = false);
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      latitude = pos.latitude;
      longitude = pos.longitude;
      _fetchingLocation = false;
    });
  }

  // 🧾 REGISTER USER
  Future<void> _registerUser() async {
    final existingUser = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: idController.text.trim())
        .get();

    if (existingUser.docs.isNotEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Username already exists")));
      return;
    }

    await FirebaseFirestore.instance.collection('users').add({
      'name': nameController.text.trim(),
      'username': idController.text.trim(),
      'password': passwordController.text.trim(), // demo only
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': FieldValue.serverTimestamp(),
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomePage(
          name: nameController.text.trim(),
          latitude: latitude!,
          longitude: longitude!,
          photo: _localPhoto,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    nameController.dispose();
    idController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _input(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  TextFormField(controller: nameController, decoration: _input("Name", Icons.person)),
                  const SizedBox(height: 12),
                  TextFormField(controller: idController, decoration: _input("Username", Icons.badge)),
                  const SizedBox(height: 12),
                  TextFormField(controller: passwordController, obscureText: true, decoration: _input("Password", Icons.lock)),
                  const SizedBox(height: 12),
                  TextFormField(controller: confirmPasswordController, obscureText: true, decoration: _input("Confirm Password", Icons.lock_outline)),
                  const SizedBox(height: 12),

                  TextFormField(
                    readOnly: true,
                    onTap: _pickPhoto,
                    decoration: _input("Add a photo", Icons.camera_alt),
                  ),
                  if (_localPhoto != null) ...[
  const SizedBox(height: 12),
  Image.file(
    _localPhoto!,
    height: 120,
    fit: BoxFit.cover,
  ),
],


                  const SizedBox(height: 12),

                  TextFormField(
                    readOnly: true,
                    onTap: _getCurrentLocation,
                    decoration: _input(
                      _fetchingLocation ? "Fetching location..." : "Get location",
                      Icons.location_on,
                    ),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
  onPressed: () {
    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("📍 Please fetch location first")),
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    _registerUser();
  },
  child: const Text("Register"),
)

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
