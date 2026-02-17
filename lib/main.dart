import 'dart:convert';
import 'dart:io';
import 'dart:math';
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
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  File? _loginPhoto;

  final String loginBackendUrl =
      "http://172.20.10.3:5000/login-face"; // change if IP changes

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

  Future<String?> _verifyFaceWithBackend() async {
    if (_loginPhoto == null) {
      print("❌ No login photo available");
      return null;
    }

    try {
      print("🔵 Preparing request to backend...");

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(loginBackendUrl),
      );

      // ✅ Send username to backend
      request.fields['username'] = usernameController.text.trim();

      // ✅ Send image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          _loginPhoto!.path,
        ),
      );

      print("📤 Sending image + username to backend...");
      var response = await request.send();

      print("📥 Backend responded with status: ${response.statusCode}");

      var responseData = await response.stream.bytesToString();
      print("📦 Backend raw response: $responseData");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(responseData);

        if (decoded["verified"] == true) {
          print("✅ Face verified as: ${decoded["username"]}");
          return decoded["username"];
        } else {
          print("❌ Face not verified");
          return null;
        }
      } else {
        print("❌ Backend error status");
        return null;
      }
    } catch (e) {
      print("🚨 Face login exception: $e");
      return null;
    }
  }


  Future<void> _pickPhoto() async {
    if (Platform.isWindows) {
      final htmlPath =
          '${Directory.current.path}\\windows\\runner\\resources\\camera.html';
      await launchUrl(Uri.file(htmlPath),
          mode: LaunchMode.externalApplication);

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
          setState(() => _loginPhoto = files.first);
          return;
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }
      return;
    }

    final XFile? photo = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
      preferredCameraDevice: CameraDevice.front,
    );

    if (photo != null) {
      setState(() => _loginPhoto = File(photo.path));
    }
  }

  Future<void> _login() async {
    if (_loginPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("📸 Selfie required to clock in")));
      return;
    }

    ValueNotifier<String> statusText =
        ValueNotifier("Authenticating...");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          content: ValueListenableBuilder<String>(
            valueListenable: statusText,
            builder: (context, value, child) {
              return Row(
                children: [
                  const CircularProgressIndicator(
                      color: Color(0xFF6A8A73)),
                  const SizedBox(width: 20),
                  Expanded(
                      child: Text(value,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold))),
                ],
              );
            },
          ),
        ),
      ),
    );

    try {
      // -------------------------------
      // STEP 1: Validate Credentials
      // -------------------------------
      final username = usernameController.text.trim();
      final password = passwordController.text.trim();

      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .where('password', isEqualTo: password)
          .get();

      if (query.docs.isEmpty) {
        if (mounted) Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Invalid credentials")));
        return;
      }

      final doc = query.docs.first;
      final data = doc.data();

      // -------------------------------
      // STEP 2: FACE VERIFICATION FIRST
      // -------------------------------
      statusText.value = "Analyzing Biometrics...";

      print("🔵 Sending face to backend...");

      String? verifiedUsername =
          await _verifyFaceWithBackend();

      print("🟢 Backend returned: $verifiedUsername");

      if (verifiedUsername == null ||
          verifiedUsername != username) {
        if (mounted) Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Face not recognized")));
        return;
      }

      // -------------------------------
      // STEP 3: LOCATION CHECK
      // -------------------------------
      statusText.value = "Verifying Location...";

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        if (mounted) Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location permission required")));
        return;
      }

      final currentPosition =
          await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.best);

      if (Platform.isAndroid && currentPosition.isMocked) {
        if (mounted) Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Fake GPS detected")));
        return;
      }

      final double realTimeLat = currentPosition.latitude;
      final double realTimeLng = currentPosition.longitude;

      // -------------------------------
      // STEP 4: BOUNDARY CHECK (SAFE)
      // -------------------------------
      statusText.value = "Checking Geofence...";

      if (data['boundary'] == null) {
        if (mounted) Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Boundary not set by Admin")));
        return;
      }

      final boundaryData =
          Map<String, dynamic>.from(data['boundary']);

      final boundaryLat = boundaryData['lat'];
      final boundaryLng = boundaryData['lng'];

      if (boundaryLat == null || boundaryLng == null) {
        if (mounted) Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Invalid boundary configuration")));
        return;
      }

      final distance = _calculateDistanceMeters(
          realTimeLat, realTimeLng, boundaryLat, boundaryLng);

      final bytes = await _loginPhoto!.readAsBytes();
      final String base64Image = base64Encode(bytes);

      // -------------------------------
      // STEP 5: LOCATION MISMATCH
      // -------------------------------
      if (distance > 20) {
        await FirebaseFirestore.instance
            .collection('attendance_logs')
            .add({
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
                  "Access Denied: ${distance.toStringAsFixed(1)}m away"),
              backgroundColor: Colors.red),
        );
        return;
      }

      // -------------------------------
      // STEP 6: SUCCESS
      // -------------------------------
      statusText.value = "Finalizing Success...";

      await FirebaseFirestore.instance
          .collection('attendance_logs')
          .add({
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
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }


  double _calculateDistanceMeters(
      double lat1,
      double lon1,
      double lat2,
      double lon2) {
    const double earthRadius = 6371000;
    double dLat = (lat2 - lat1) * (pi / 180);
    double dLon = (lon2 - lon1) * (pi / 180);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) *
            cos(lat2 * (pi / 180)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return earthRadius *
        (2 * atan2(sqrt(a), sqrt(1 - a)));
  }

  InputDecoration _modernInput(
      String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon:
          Icon(icon, color: const Color(0xFF6A8A73)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
          vertical: 18, horizontal: 16),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
              color: Color(0xFF6A8A73), width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(),
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const AdminLoginPage())),
                    icon: const Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white70,
                        size: 20),
                    label: const Text("ADMIN",
                        style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: const [
                  Text("Attendance Check",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text("Verify identity to clock in.",
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16)),
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
                    decoration:
                        const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.only(
                        topLeft:
                            Radius.circular(30),
                        topRight:
                            Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding:
                          const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Center(
                              child: Container(
                                  width: 40,
                                  height: 4,
                                  margin:
                                      const EdgeInsets.only(
                                          bottom: 20),
                                  decoration: BoxDecoration(
                                      color: Colors
                                          .grey.shade300,
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                                  2)))),
                          TextFormField(
                              controller:
                                  usernameController,
                              decoration:
                                  _modernInput(
                                      "Username",
                                      Icons
                                          .person_outline)),
                          const SizedBox(
                              height: 16),
                          TextFormField(
                              controller:
                                  passwordController,
                              obscureText: true,
                              decoration:
                                  _modernInput(
                                      "Password",
                                      Icons
                                          .lock_outline)),
                          const SizedBox(
                              height: 16),
                          GestureDetector(
                            onTap: _pickPhoto,
                            child: Container(
                              height: 140,
                              width:
                                  double.infinity,
                              decoration:
                                  BoxDecoration(
                                color: Colors
                                    .grey.shade50,
                                borderRadius:
                                    BorderRadius
                                        .circular(16),
                                border: Border.all(
                                    color: _loginPhoto ==
                                            null
                                        ? Colors.grey
                                            .shade300
                                        : const Color(
                                            0xFF6A8A73),
                                    width: 2),
                              ),
                              child: _loginPhoto !=
                                      null
                                  ? ClipRRect(
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                                  14),
                                      child:
                                          Image.file(
                                        _loginPhoto!,
                                        fit: BoxFit
                                            .cover,
                                        width: double
                                            .infinity,
                                      ))
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment
                                              .center,
                                      children: const [
                                        Icon(
                                            Icons
                                                .camera_alt_outlined,
                                            size: 30,
                                            color:
                                                Colors
                                                    .grey),
                                        SizedBox(
                                            height: 8),
                                        Text(
                                            "Take Selfie",
                                            style: TextStyle(
                                                color:
                                                    Colors
                                                        .grey)),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(
                              height: 32),
                          SizedBox(
                            width:
                                double.infinity,
                            height: 55,
                            child:
                                ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton
                                  .styleFrom(
                                backgroundColor:
                                    const Color(
                                        0xFF6A8A73),
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                              30),
                                ),
                              ),
                              child: const Text(
                                  "Verify & Login",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                      color: Colors
                                          .white)),
                            ),
                          ),
                          const SizedBox(
                              height: 24),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                            children: [
                              const Text(
                                  "New Employee? ",
                                  style: TextStyle(
                                      color:
                                          Colors.grey)),
                              GestureDetector(
                                onTap: () =>
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const RegisterPage())),
                                child: const Text(
                                  "Register",
                                  style: TextStyle(
                                      color: Color(
                                          0xFF101010),
                                      fontWeight:
                                          FontWeight
                                              .bold),
                                ),
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
