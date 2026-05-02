import 'dart:convert';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'home_page.dart';
import 'app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:appwrite/appwrite.dart';
import '../services/appwrite_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final uniqueCodeController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool _isObscure = true;
  bool _isConfirmObscure = true;

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

  static const String _backendBaseUrl = "https://pasteshub404-navikarana-backend.hf.space";
  static const String _registerFaceEndpoint = "$_backendBaseUrl/register-face";


  @override
  void initState() {
    super.initState();
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
                        color: isSelected ? AppTheme.kGreen : Colors.black87
                      )),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.kGreen) : null,
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

  Future<void> _registerUserInAppwrite() async {
  await AppwriteService.databases.createDocument(
    databaseId: '69ecebfb0033cf785741',
    collectionId: 'users',
    documentId: ID.unique(),
    data: {
      'name': nameController.text.trim(),
      'username': uniqueCodeController.text.trim(),
      'password': passwordController.text.trim(),
      'department': _selectedSchool,
      'latitude': latitude?.toString(),
      'longitude': longitude?.toString(),
    },
  );
}

  Future<void> _onRegisterPressed() async {
    if (_localPhoto == null) { _showSnackBar("Please add a photo first."); return; }
    if (latitude == null || longitude == null) { _showSnackBar("Please fetch your location first."); return; }
    if (passwordController.text != confirmPasswordController.text) { _showSnackBar("Passwords do not match."); return; }
    if (_selectedSchool == null) { _showSnackBar("Please select your school."); return; }

    final existingUser = await AppwriteService.databases.listDocuments(
  databaseId: '69ecebfb0033cf785741',
  collectionId: 'users',
  queries: [
    Query.equal('username', uniqueCodeController.text.trim()),
  ],
);
    if (existingUser.documents.isNotEmpty) { _showSnackBar("Unique ID already exists."); return; }

    setState(() => _registeringFace = true);
    try {
      final faceError = await _registerFaceOnBackend();
      if (faceError != null) {
        _showSnackBar(faceError);
        return;
      }
      await _registerUserInAppwrite();
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage(name: nameController.text.trim(), username: uniqueCodeController.text.trim())));
    } catch (e) {
      if (mounted) _showSnackBar("Registration failed: $e");
    } finally {
      if (mounted) setState(() => _registeringFace = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    nameController.dispose();
    uniqueCodeController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // --- REUSABLE UI TILES ---
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: AppTheme.labelSmall.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isSet = false,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: isSet ? AppTheme.kGreen : AppTheme.kBorder, width: 1.5),
          borderRadius: BorderRadius.circular(16),
          color: isSet ? AppTheme.kGreen.withValues(alpha: 0.05) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSet ? AppTheme.kGreen : Colors.grey, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: isSet ? FontWeight.bold : FontWeight.w500,
                  color: isSet ? AppTheme.kGreen : Colors.grey.shade700,
                ),
              ),
            ),
            if (isLoading)
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.kGreen))
            else if (isSet)
              const Icon(Icons.check_circle_rounded, color: AppTheme.kGreen, size: 20),
          ],
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kDark,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.of(context).pop())),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Go ahead and set up\nyour account", style: AppTheme.headingWhite.copyWith(fontSize: 28, height: 1.2)),
              const SizedBox(height: 10),
              Text("Create your account to enjoy the best managing experience", style: AppTheme.subheadingGrey)
            ])),
          Expanded(
            child: RisingSheet(
              child: Container(
                width: double.infinity,
                decoration: AppTheme.bottomSheet,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(children: [
                    AppTheme.sheetHandle,
                    _sectionTitle("BASIC INFORMATION"),
                    TextFormField(
                      controller: nameController, 
                      textInputAction: TextInputAction.next,
                      decoration: AppTheme.inputDecoration("Full Name", Icons.person_outline)
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: uniqueCodeController, 
                      textInputAction: TextInputAction.next,
                      decoration: AppTheme.inputDecoration("Unique ID", Icons.badge_outlined)
                    ),
                    const SizedBox(height: 16),

                    GestureDetector(
                      onTap: _showSchoolPicker,
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: AppTheme.inputDecoration(
                            _selectedSchool ?? "Select School", 
                            Icons.school_outlined, 
                            isDropdown: true
                          ),
                          style: GoogleFonts.poppins(color: _selectedSchool == null ? Colors.grey : Colors.black, fontSize: 14),
                        ),
                      ),
                    ),
                    
                    _sectionTitle("IDENTITY CHECK"),
                    _actionTile(
                      icon: Icons.camera_alt_outlined,
                      label: _localPhoto != null ? "Photo Captured" : "Add Profile Photo",
                      onTap: _pickPhoto,
                      isSet: _localPhoto != null,
                    ),
                    if (_localPhoto != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_localPhoto!, height: 120, width: double.infinity, fit: BoxFit.cover),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _actionTile(
                      icon: Icons.location_on_outlined,
                      label: latitude != null ? "Location Verified" : "Capture Location",
                      onTap: _getCurrentLocation,
                      isLoading: _fetchingLocation,
                      isSet: latitude != null,
                    ),

                    _sectionTitle("SECURITY"),
                    TextFormField(
                      controller: passwordController, 
                      obscureText: _isObscure, 
                      decoration: AppTheme.inputDecoration(
                        "Password", 
                        Icons.lock_outline,
                        suffix: IconButton(
                          icon: Icon(_isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey, size: 20),
                          onPressed: () => setState(() => _isObscure = !_isObscure),
                        ),
                      )
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: confirmPasswordController, 
                      obscureText: _isConfirmObscure, 
                      decoration: AppTheme.inputDecoration(
                        "Confirm Password", 
                        Icons.lock_reset,
                        suffix: IconButton(
                          icon: Icon(_isConfirmObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey, size: 20),
                          onPressed: () => setState(() => _isConfirmObscure = !_isConfirmObscure),
                        ),
                      )
                    ),
                    
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity, 
                      height: 55, 
                      child: ElevatedButton(
                        onPressed: _registeringFace ? null : _onRegisterPressed, 
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                        child: _registeringFace 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : const Text("Register Account", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))
                      )
                    ),
                    
                    // ---------------------------------------------------------------------------
                    // PROFESSIONAL LOGO FOOTER WITH PNG TINT & GLOW
                    // ---------------------------------------------------------------------------
                    const SizedBox(height: 50),
                    Center(
                      child: RepaintBoundary(
                        child: Opacity(
                          opacity: 0.6,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF6A8A73).withValues(alpha: 0.15),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: ColorFiltered(
                                  colorFilter: ColorFilter.mode(
                                    const Color(0xFF6A8A73).withValues(alpha: 0.1),
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
                                  color: const Color(0xFF6A8A73).withValues(alpha: 0.8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}