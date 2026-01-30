import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import 'firebase_options.dart';
import 'home_page.dart';
import 'register_page.dart';
import 'admin_login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  File? _loginPhoto;

  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (!Platform.isWindows) {
      final XFile? photo = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 50);
      if (photo != null) setState(() => _loginPhoto = File(photo.path));
      return;
    }

    final htmlPath = '${Directory.current.path}\\windows\\runner\\resources\\camera.html';
    await launchUrl(Uri.file(htmlPath), mode: LaunchMode.externalApplication);
    
    final downloadsDir = Directory('${Platform.environment['USERPROFILE']}\\Downloads');
    final startTime = DateTime.now();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Waiting for photo capture...")));

    while (DateTime.now().difference(startTime).inSeconds < 15) {
      final files = downloadsDir.listSync().whereType<File>().where((f) =>
          f.path.endsWith('captured_photo.png') &&
          f.lastModifiedSync().isAfter(startTime)).toList();

      if (files.isNotEmpty) {
        setState(() => _loginPhoto = files.first);
        return;
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  // ---------------------------------------------------------------------------
  // 🔐 NEW: LOGIN LOGIC WITH FAILED ATTEMPT LOGGING
  // ---------------------------------------------------------------------------
  Future<void> _login() async {
    if (_loginPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("📸 Selfie required to clock in")));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF6A8A73))),
    );

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: usernameController.text.trim())
          .where('password', isEqualTo: passwordController.text.trim())
          .get();

      if (!mounted) return;
      Navigator.of(context).pop(); // Dismiss Loading

      if (query.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid credentials")));
        return;
      }

      final doc = query.docs.first;
      final data = doc.data();

      // Boundary Check
      if (data['boundary'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Access denied: Boundary not set")));
        return;
      }

      final userLat = data['latitude'];
      final userLng = data['longitude'];
      final boundaryLat = data['boundary']['lat'];
      final boundaryLng = data['boundary']['lng'];

      if (userLat == null || userLng == null) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Location data missing")));
         return;
      }

      final distance = _calculateDistanceMeters(userLat, userLng, boundaryLat, boundaryLng);

      // Prepare Image
      final bytes = await _loginPhoto!.readAsBytes();
      final String base64Image = base64Encode(bytes);

      // 🔴 FAIL: GEOFENCE MISMATCH
      if (distance > 20) {
        // Log the FAILED attempt so Admin can see it
        await FirebaseFirestore.instance.collection('attendance_logs').add({
          'userId': doc.id,
          'name': data['name'],
          'username': data['username'],
          'timestamp': FieldValue.serverTimestamp(),
          'photoBase64': base64Image,
          'location': {'lat': userLat, 'lng': userLng},
          'status': 'Location Mismatch', // ⚠️ Special Status
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Access Denied: You are ${distance.toStringAsFixed(1)}m away. Attempt logged."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // ✅ SUCCESS: PRESENT
      await FirebaseFirestore.instance.collection('attendance_logs').add({
        'userId': doc.id,
        'name': data['name'],
        'username': data['username'],
        'timestamp': FieldValue.serverTimestamp(),
        'photoBase64': base64Image,
        'location': {'lat': userLat, 'lng': userLng},
        'status': 'Present', // ✅ Success Status
      });

      if(!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(
            name: data['name'],
            latitude: userLat,
            longitude: userLng,
            photo: _loginPhoto,
          ),
        ),
      );

    } catch (e) {
      if (Navigator.canPop(context)) Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  double _calculateDistanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000;
    double dLat = (lat2 - lat1) * (pi / 180);
    double dLon = (lon2 - lon1) * (pi / 180);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) * cos(lat2 * (pi / 180)) * sin(dLon / 2) * sin(dLon / 2);
    return earthRadius * (2 * atan2(sqrt(a), sqrt(1 - a)));
  }

  InputDecoration _modernInput(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: const Color(0xFF6A8A73)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF6A8A73), width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(),
                  TextButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminLoginPage())),
                    icon: const Icon(Icons.admin_panel_settings, color: Colors.white70, size: 20),
                    label: const Text("ADMIN", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("Attendance Check", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text("Verify identity to clock in.", style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            ),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 30), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                          
                          TextFormField(controller: usernameController, decoration: _modernInput("Username", Icons.person_outline)),
                          const SizedBox(height: 16),
                          TextFormField(controller: passwordController, obscureText: true, decoration: _modernInput("Password", Icons.lock_outline)),
                          const SizedBox(height: 16),
                          
                          GestureDetector(
                            onTap: _pickPhoto,
                            child: Container(
                              height: 140,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _loginPhoto == null ? Colors.grey.shade300 : const Color(0xFF6A8A73), width: 2),
                              ),
                              child: _loginPhoto != null
                                  ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(_loginPhoto!, fit: BoxFit.cover, width: double.infinity))
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.camera_alt_outlined, size: 30, color: Colors.grey),
                                        SizedBox(height: 8),
                                        Text("Tap to take Selfie (Required)", style: TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A8A73), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                              child: const Text("Verify & Login", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("New Employee? ", style: TextStyle(color: Colors.grey)),
                              GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
                                child: const Text("Register", style: TextStyle(color: Color(0xFF101010), fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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