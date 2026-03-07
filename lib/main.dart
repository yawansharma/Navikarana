import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:async'; // Required for Splash Screen Timer
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

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
      home: SplashScreen(), // Changed to start with Splash Screen
    );
  }
}

// ---------------------------------------------------------------------------
// NEW: Animated Splash Screen with PNG Effect & Slow Disappear
// ---------------------------------------------------------------------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.8, curve: Curves.easeIn)),
    );

    // Phase 1: Logo Appears
    _controller.forward();

    // Phase 2: Logic to disappear slowly and then navigate
    Timer(const Duration(milliseconds: 2500), () async {
      if (!mounted) return;
      
      // Change duration to make the disappear phase slower (1 second)
      _controller.duration = const Duration(milliseconds: 1000);
      
      // Reverse the animation (logo shrinks and fades out)
      _controller.reverse(); 
      
      // Wait for the slow fade to finish
      await Future.delayed(const Duration(milliseconds: 1100));
      
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => const LoginPage(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 228, 228, 228),
      body: Center(
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              // --- PNG EFFECT: SOFT GLOW ---
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6A8A73).withValues(alpha: 0.2),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ColorFiltered(
                // --- PNG EFFECT: SAGE TINT ---
                colorFilter: ColorFilter.mode(
                  const Color(0xFF6A8A73).withValues(alpha: 0.08), 
                  BlendMode.srcATop,
                ),
                child: Image.asset(
                  'assets/navikarnaNew.png',
                  width: 250,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// LOGIN PAGE - ALL FUNCTIONS PRESERVED
// ---------------------------------------------------------------------------
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final uniqueCodeController = TextEditingController();
  final passwordController = TextEditingController();
  File? _loginPhoto;

  static const String _backendBaseUrl =
      "https://pasteshub-navikarana-backend.hf.space";

  static const String _loginFaceEndpoint = "$_backendBaseUrl/login-face";

  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
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
    uniqueCodeController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<_FaceVerificationResult> _verifyFaceWithBackend() async {
    if (_loginPhoto == null) {
      return _FaceVerificationResult(
        verified: false,
        errorMessage: "No photo selected.",
      );
    }

    try {
      final request =
          http.MultipartRequest('POST', Uri.parse(_loginFaceEndpoint));

      request.fields['username'] = uniqueCodeController.text.trim();
      request.files.add(
        await http.MultipartFile.fromPath('image', _loginPhoto!.path),
      );

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      debugPrint("Face login backend status: ${streamedResponse.statusCode}");
      debugPrint("Face login backend body: $responseBody");

      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;

      if (decoded['verified'] == true) {
        return _FaceVerificationResult(verified: true);
      }

      final reason = decoded['error'] as String? ?? "Face not recognised.";
      return _FaceVerificationResult(verified: false, errorMessage: reason);
    } catch (e) {
      debugPrint("Face login network error: $e");
      return _FaceVerificationResult(
        verified: false,
        errorMessage:
            "Could not reach the server. Please check your connection.",
      );
    }
  }

  Future<void> _pickPhoto() async {
    if (Platform.isWindows) {
      final htmlPath =
          '${Directory.current.path}\\windows\\runner\\resources\\camera.html';
      await launchUrl(Uri.file(htmlPath),
          mode: LaunchMode.externalApplication);

      final downloadsDir = Directory(
          '${Platform.environment['USERPROFILE']}\\Downloads');
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
          setState(() => _loginPhoto = files.first);
          return;
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }
      return;
    }

    final XFile? photo = await ImagePicker().pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      maxWidth: 640,
      maxHeight: 640,
      imageQuality: 100,
    );

    if (photo != null) {
      setState(() => _loginPhoto = File(photo.path));
    }
  }

  Future<void> _login() async {
    if (_loginPhoto == null) {
      _showSnackBar("A selfie is required to clock in.");
      return;
    }

    final statusText = ValueNotifier("Authenticating...");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          content: ValueListenableBuilder<String>(
            valueListenable: statusText,
            builder: (context, value, child) {
              return Row(
                children: [
                  const CircularProgressIndicator(color: Color(0xFF6A8A73)),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(value,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    try {
      final uniqueCode = uniqueCodeController.text.trim();
      final password = passwordController.text.trim();

      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: uniqueCode)
          .where('password', isEqualTo: password)
          .get();

      if (query.docs.isEmpty) {
        _dismissDialogAndShow(statusText, "Invalid credentials.");
        return;
      }

      final doc = query.docs.first;
      final data = doc.data();

      statusText.value = "Analyzing Biometrics...";

      final faceResult = await _verifyFaceWithBackend();

      final bytes = await _loginPhoto!.readAsBytes();
      final String base64Image = base64Encode(bytes);

      if (!faceResult.verified) {
        await FirebaseFirestore.instance.collection('attendance_logs').add({
          'userId': doc.id,
          'name': data['name'],
          'username': data['username'],
          'timestamp': FieldValue.serverTimestamp(),
          'photoBase64': base64Image,
          'status': 'Face Not Recognized',
        });

        _dismissDialogAndShow(
            statusText, faceResult.errorMessage ?? "Face not recognised.");
        return;
      }

      statusText.value = "Verifying Location...";

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        _dismissDialogAndShow(statusText, "Location permission is required.");
        return;
      }

      final currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);

      if (Platform.isAndroid && currentPosition.isMocked) {
        _dismissDialogAndShow(statusText, "Fake GPS detected. Access denied.");
        return;
      }

      final double realTimeLat = currentPosition.latitude;
      final double realTimeLng = currentPosition.longitude;

      statusText.value = "Checking Geofence...";

      if (data['boundary'] == null) {
        _dismissDialogAndShow(
            statusText, "Boundary not set by admin. Contact your administrator.");
        return;
      }

      final boundaryData = Map<String, dynamic>.from(data['boundary']);
      final boundaryLat = boundaryData['lat'];
      final boundaryLng = boundaryData['lng'];

      if (boundaryLat == null || boundaryLng == null) {
        _dismissDialogAndShow(
            statusText, "Invalid boundary configuration. Contact your administrator.");
        return;
      }

      final distance = _calculateDistanceMeters(
          realTimeLat, realTimeLng, boundaryLat, boundaryLng);

      if (distance > 20) {
        await FirebaseFirestore.instance.collection('attendance_logs').add({
          'userId': doc.id,
          'name': data['name'],
          'username': data['username'],
          'timestamp': FieldValue.serverTimestamp(),
          'photoBase64': base64Image,
          'location': {'lat': realTimeLat, 'lng': realTimeLng},
          'status': 'Location Mismatch',
        });

        if (mounted) Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Access denied: ${distance.toStringAsFixed(1)}m outside boundary."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      statusText.value = "Finalizing...";

      await FirebaseFirestore.instance.collection('attendance_logs').add({
        'userId': doc.id,
        'name': data['name'],
        'username': data['username'],
        'timestamp': FieldValue.serverTimestamp(),
        'photoBase64': base64Image,
        'location': {'lat': realTimeLat, 'lng': realTimeLng},
        'status': 'Present',
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(doc.id)
          .update({
        'latitude': realTimeLat,
        'longitude': realTimeLng,
        'lastLogin': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.of(context).pop();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(
            name: data['name'],
            latitude: realTimeLat,
            longitude: realTimeLng,
            photo: _loginPhoto,
          ),
        ),
      );
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.of(context).pop();
      if (mounted) _showSnackBar("An unexpected error occurred: $e");
    }
  }

  void _dismissDialogAndShow(ValueNotifier<String> statusText, String message) {
    if (mounted && Navigator.canPop(context)) Navigator.of(context).pop();
    _showSnackBar(message);
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  double _calculateDistanceMeters(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000;
    final double dLat = (lat2 - lat1) * (pi / 180);
    final double dLon = (lon2 - lon1) * (pi / 180);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) *
            cos(lat2 * (pi / 180)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return earthRadius * (2 * atan2(sqrt(a), sqrt(1 - a)));
  }

  InputDecoration _modernInput(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF6A8A73), size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6A8A73), width: 2)),
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
                  const Text(
                    "Navikarana",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 1.2),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AdminLoginPage())),
                    icon: const Icon(Icons.admin_panel_settings_outlined,
                        color: Colors.white70, size: 18),
                    label: const Text(
                      "ADMIN",
                      style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome Back",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Verify your unique code and identity.",
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8F9FB),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(35),
                        topRight: Radius.circular(35),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 30),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          TextFormField(
                            controller: uniqueCodeController,
                            decoration: _modernInput(
                                "Unique Code", Icons.badge_outlined),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: passwordController,
                            obscureText: true,
                            decoration:
                                _modernInput("Password", Icons.lock_outline),
                          ),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: _pickPhoto,
                            child: Container(
                              height: 160,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _loginPhoto == null
                                      ? Colors.grey.shade200
                                      : const Color(0xFF6A8A73),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: _loginPhoto != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: Image.file(
                                        _loginPhoto!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                            Icons.face_retouching_natural_rounded,
                                            size: 40,
                                            color: Colors.grey.shade400),
                                        const SizedBox(height: 10),
                                        Text(
                                          "Capture Selfie Verification",
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6A8A73),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                "Verify & Clock In",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "First day at work? ",
                                style: TextStyle(color: Colors.grey),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const RegisterPage()),
                                ),
                                child: const Text(
                                  "Register here",
                                  style: TextStyle(
                                    color: Color(0xFF6A8A73),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          // --- PNG EFFECT LOGO FOOTER ---
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
                          const SizedBox(height: 80),
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

class _FaceVerificationResult {
  final bool verified;
  final String? errorMessage;
  _FaceVerificationResult({required this.verified, this.errorMessage});
}