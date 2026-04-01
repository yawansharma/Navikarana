import 'dart:convert';
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

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final nameController = TextEditingController();
  final uniqueCodeController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Selection state
  String? _selectedSchool;
  final List<String> _schools = [
    "School of Computing (SoC)",
    "School of Electrical & Electronics Engineering (SEEE)",
    "School of Mechanical Engineering (SoME)",
    "School of Civil Engineering (SoCE)",
    "School of Chemical & Biotechnology (SCBT)",
    "School of Law",
    "School of Management (SoM)",
    "School of Arts, Sciences, Humanities & Education (SASHE)"
  ];

  File? _localPhoto;
  double? latitude;
  double? longitude;
  bool _fetchingLocation = false;
  bool _registeringFace = false;

  static const String _backendBaseUrl = "https://pasteshub-navikarana-backend.hf.space";
  static const String _registerFaceEndpoint = "$_backendBaseUrl/register-face";

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

  // --- NEW UX: BOTTOM SHEET SELECTOR ---
  void _showSchoolPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              const Text("Select Your School", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _schools.length,
                  itemBuilder: (context, index) {
                    final school = _schools[index];
                    final isSelected = _selectedSchool == school;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 30),
                      title: Text(school, style: TextStyle(
                        fontSize: 14, 
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFF6A8A73) : Colors.black87
                      )),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF6A8A73)) : null,
                      onTap: () {
                        setState(() => _selectedSchool = school);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickPhoto() async {
    if (!Platform.isWindows) {
      final XFile? photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 640,
        maxHeight: 640,
        imageQuality: 100,
      );
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
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
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

  Future<String?> _registerFaceOnBackend() async {
    if (_localPhoto == null) return "No photo selected.";
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_registerFaceEndpoint));
      request.fields['username'] = uniqueCodeController.text.trim();
      request.files.add(await http.MultipartFile.fromPath('image', _localPhoto!.path));
      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      if (streamedResponse.statusCode == 200) return null;
      try {
        final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
        return decoded['error'] as String? ?? "Face registration failed.";
      } catch (_) {
        return "Face registration failed (status ${streamedResponse.statusCode}).";
      }
    } catch (e) {
      return "Could not reach the server. Please check your connection.";
    }
  }

  Future<void> _registerUserInFirestore() async {
    await FirebaseFirestore.instance.collection('users').doc(uniqueCodeController.text.trim()).set({
      'name': nameController.text.trim(),
      'username': uniqueCodeController.text.trim(),
      'password': passwordController.text.trim(),
      'department': _selectedSchool,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _onRegisterPressed() async {
    if (_localPhoto == null) { _showSnackBar("Please add a photo first."); return; }
    if (latitude == null || longitude == null) { _showSnackBar("Please fetch your location first."); return; }
    if (passwordController.text != confirmPasswordController.text) { _showSnackBar("Passwords do not match."); return; }
    if (_selectedSchool == null) { _showSnackBar("Please select your school."); return; }

    final existingUser = await FirebaseFirestore.instance.collection('users').where('username', isEqualTo: uniqueCodeController.text.trim()).get();
    if (existingUser.docs.isNotEmpty) { _showSnackBar("Unique ID already exists."); return; }

    setState(() => _registeringFace = true);
    final faceError = await _registerFaceOnBackend();
    if (faceError != null) {
      setState(() => _registeringFace = false);
      _showSnackBar(faceError);
      return;
    }
    await _registerUserInFirestore();
    setState(() => _registeringFace = false);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage(name: nameController.text.trim(), username: uniqueCodeController.text.trim())));
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _controller.dispose();
    nameController.dispose();
    uniqueCodeController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _modernInput(String label, IconData icon, {bool isDropdown = false}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF6A8A73)),
      suffixIcon: isDropdown ? const Icon(Icons.arrow_drop_down_rounded, color: Colors.grey) : null,
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
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 10, 24, 30),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Go ahead and set up\nyour account", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, height: 1.2)),
                SizedBox(height: 10),
                Text("Sign in-up to enjoy the best managing experience", style: TextStyle(color: Colors.grey, fontSize: 14))
              ])),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(children: [
                    Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                    TextFormField(controller: nameController, decoration: _modernInput("Full Name", Icons.person_outline)),
                    const SizedBox(height: 16),
                    TextFormField(controller: uniqueCodeController, decoration: _modernInput("Unique ID", Icons.badge_outlined)),
                    const SizedBox(height: 16),

                    // POLISHED SELECTION UX
                    GestureDetector(
                      onTap: _showSchoolPicker,
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: _modernInput(
                            _selectedSchool ?? "Select School", 
                            Icons.school_outlined, 
                            isDropdown: true
                          ),
                          style: TextStyle(color: _selectedSchool == null ? Colors.grey : Colors.black),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(controller: passwordController, obscureText: true, decoration: _modernInput("Password", Icons.lock_outline)),
                    const SizedBox(height: 16),
                    TextFormField(controller: confirmPasswordController, obscureText: true, decoration: _modernInput("Confirm Password", Icons.lock_reset)),
                    const SizedBox(height: 16),
                    GestureDetector(onTap: _pickPhoto, child: AbsorbPointer(child: TextFormField(decoration: _modernInput("Add a photo", Icons.camera_alt_outlined)))),
                    if (_localPhoto != null) ...[
                      const SizedBox(height: 16),
                      ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(_localPhoto!, height: 150, width: double.infinity, fit: BoxFit.cover))
                    ],
                    const SizedBox(height: 16),
                    GestureDetector(onTap: _getCurrentLocation, child: AbsorbPointer(child: TextFormField(decoration: _modernInput(_fetchingLocation ? "Fetching location..." : (latitude != null ? "Location Set" : "Get location"), Icons.location_on_outlined)))),
                    const SizedBox(height: 32),
                    SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: _registeringFace ? null : _onRegisterPressed, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A8A73), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: _registeringFace ? const CircularProgressIndicator(color: Colors.white) : const Text("Register", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)))),
                    
                    // ---------------------------------------------------------------------------
                    // PROFESSIONAL LOGO FOOTER WITH PNG TINT & GLOW
                    // ---------------------------------------------------------------------------
                    const SizedBox(height: 50),
                    Center(
                      child: Opacity(
                        opacity: 0.6,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6A8A73).withOpacity(0.15),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ColorFiltered(
                                colorFilter: ColorFilter.mode(
                                  const Color(0xFF6A8A73).withOpacity(0.1), 
                                  BlendMode.srcATop,
                                ),
                                child: Image.asset(
                                  'assets/navikarnaNew.png',
                                  width: 90, 
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "POWERED BY NAVIKARANA",
                              style: TextStyle(
                                color: const Color(0xFF6A8A73).withOpacity(0.8),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}