import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// KEEPING YOUR ORIGINAL IMPORTS
import 'home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // LOGIC SECTION (KEPT EXACTLY THE SAME)
  // ---------------------------------------------------------------------------
  final nameController = TextEditingController();
  final idController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  File? _localPhoto;
  double? latitude;
  double? longitude;

  bool _fetchingLocation = false;

  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
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
      'password': passwordController.text.trim(),
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

  // ---------------------------------------------------------------------------
  // UI SECTION (REDESIGNED)
  // ---------------------------------------------------------------------------

  // A custom input decoration that matches the clean white/border look in the image
  InputDecoration _modernInput(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: const Color(0xFF6A8A73)), // Sage Green Icon
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF6A8A73), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. The Background Color (Dark Top)
    return Scaffold(
      backgroundColor: const Color(0xFF101010), // Dark charcoal/black
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2. The Header Text (Top Section)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Go ahead and set up\nyour account",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Sign in-up to enjoy the best managing experience",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // 3. The White Bottom Container (Expanded)
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // "Tab" indicator visual (just for looks to match image style)
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // FORM FIELDS
                      TextFormField(
                        controller: nameController,
                        decoration: _modernInput("Full Name", Icons.person_outline),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: idController,
                        decoration: _modernInput("Username", Icons.badge_outlined),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: _modernInput("Password", Icons.lock_outline),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        decoration: _modernInput("Confirm Password", Icons.lock_reset),
                      ),
                      const SizedBox(height: 16),

                      // PHOTO PICKER (Styled as input)
                      GestureDetector(
                        onTap: _pickPhoto,
                        child: AbsorbPointer(
                          child: TextFormField(
                            decoration: _modernInput("Add a photo", Icons.camera_alt_outlined),
                          ),
                        ),
                      ),
                      
                      // PREVIEW IMAGE
                      if (_localPhoto != null) ...[
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            _localPhoto!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // LOCATION PICKER (Styled as input)
                      GestureDetector(
                        onTap: _getCurrentLocation,
                        child: AbsorbPointer(
                          child: TextFormField(
                            decoration: _modernInput(
                              _fetchingLocation
                                  ? "Fetching location..."
                                  : (latitude != null ? "Location Set" : "Get location"),
                              Icons.location_on_outlined,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // 4. The "Sage Green" Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A8A73), // The Sage Green
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            "Register",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}