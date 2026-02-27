import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
  final nameController = TextEditingController();
  final idController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  File? _localPhoto;
  double? latitude;
  double? longitude;
  bool _fetchingLocation = false;
  bool _registeringFace = false;

  // 🔥 CHANGE IF YOUR IP CHANGES
  final String backendUrl =
    "https://web-production-1beb.up.railway.app/register-face";

  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  Future<void> _pickPhoto() async {
    if (!Platform.isWindows) {
      final XFile? photo = await ImagePicker().pickImage(source: ImageSource.camera);
      if (photo != null) setState(() => _localPhoto = File(photo.path));
      return;
    }

    final htmlPath = '${Directory.current.path}\\windows\\runner\\resources\\camera.html';
    await launchUrl(Uri.file(htmlPath), mode: LaunchMode.externalApplication);
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _fetchingLocation = true);
    bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) { 
      await Geolocator.openLocationSettings();
      setState(() => _fetchingLocation = false); 
      return; 
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) { 
      setState(() => _fetchingLocation = false); 
      return; 
    }

    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() { 
      latitude = pos.latitude; 
      longitude = pos.longitude; 
      _fetchingLocation = false; 
    });
  }

  // 🔥 SEND FACE TO BACKEND
  Future<bool> _registerFace() async {
    if (_localPhoto == null) return false;

    try {
      var request = http.MultipartRequest('POST', Uri.parse(backendUrl));
      request.fields['username'] = idController.text.trim();

      request.files.add(
        await http.MultipartFile.fromPath('image', _localPhoto!.path),
      );

      var response = await request.send();

      return response.statusCode == 200;
    } catch (e) {
      print("Face registration error: $e");
      return false;
    }
  }

  Future<void> _registerUser() async {
    final existingUser = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: idController.text.trim())
        .get();

    if (existingUser.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Username already exists")),
      );
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
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.of(context).pop())),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("Go ahead and set up\nyour account", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, height: 1.2)),
                  SizedBox(height: 10),
                  Text("Sign in-up to enjoy the best managing experience", style: TextStyle(color: Colors.grey, fontSize: 14))
                ]
              )
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),

                      TextFormField(controller: nameController, decoration: _modernInput("Full Name", Icons.person_outline)),
                      const SizedBox(height: 16),

                      TextFormField(controller: idController, decoration: _modernInput("Username", Icons.badge_outlined)),
                      const SizedBox(height: 16),

                      TextFormField(controller: passwordController, obscureText: true, decoration: _modernInput("Password", Icons.lock_outline)),
                      const SizedBox(height: 16),

                      TextFormField(controller: confirmPasswordController, obscureText: true, decoration: _modernInput("Confirm Password", Icons.lock_reset)),
                      const SizedBox(height: 16),

                      GestureDetector(
                        onTap: _pickPhoto,
                        child: AbsorbPointer(
                          child: TextFormField(decoration: _modernInput("Add a photo", Icons.camera_alt_outlined))
                        )
                      ),

                      if (_localPhoto != null) ...[
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(_localPhoto!, height: 150, width: double.infinity, fit: BoxFit.cover)
                        )
                      ],

                      const SizedBox(height: 16),

                      GestureDetector(
                        onTap: _getCurrentLocation,
                        child: AbsorbPointer(
                          child: TextFormField(
                            decoration: _modernInput(
                              _fetchingLocation
                                  ? "Fetching location..."
                                  : (latitude != null ? "Location Set" : "Get location"),
                              Icons.location_on_outlined
                            )
                          )
                        )
                      ),

                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _registeringFace ? null : () async {

                            if (_localPhoto == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("📸 Please add photo first"))
                              );
                              return;
                            }

                            if (latitude == null || longitude == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("📍 Please fetch location first"))
                              );
                              return;
                            }

                            if (passwordController.text != confirmPasswordController.text) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Passwords do not match"))
                              );
                              return;
                            }

                            setState(() => _registeringFace = true);

                            bool faceOk = await _registerFace();

                            if (!faceOk) {
                              setState(() => _registeringFace = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("❌ Face detection failed"))
                              );
                              return;
                            }

                            await _registerUser();
                            setState(() => _registeringFace = false);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A8A73),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                          ),
                          child: _registeringFace
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("Register", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))
                        )
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
