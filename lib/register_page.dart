import 'dart:io';
import 'dart:io' show Platform;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:unknown/home_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';


class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  // Controllers
  final nameController = TextEditingController();
  final idController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Camera & Location
  final ImagePicker _picker = ImagePicker();
  final Location location = Location();

  File? _capturedImage;
  double? latitude;
  double? longitude;

  // Location state
  bool _fetchingLocation = false;
  bool _serviceEnabled = false;
  PermissionStatus? _permissionGranted;
  LocationData? _locationData;

  // Animations
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward();
  }

  Future<void> _registerUser() async {
    try {
      // 1️⃣ Check username already exists
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

      // 2️⃣ Upload image
      final ref = FirebaseStorage.instance
          .ref()
          .child('user_photos')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      await ref.putFile(_capturedImage!);
      final imageUrl = await ref.getDownloadURL();

      // 3️⃣ Save user data
      await FirebaseFirestore.instance.collection('users').add({
        'username': idController.text.trim(),
        'password': passwordController.text.trim(), // ⚠️ plain text
        'imageUrl': imageUrl,
        'latitude': latitude,
        'longitude': longitude,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4️⃣ Go to home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(
            imageUrl: imageUrl,
            latitude: latitude!,
            longitude: longitude!,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  // 📍 YOUR LOCATION FUNCTION (USED DIRECTLY)
  Future<void> _requestLocation() async {
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        setState(() => _fetchingLocation = false);
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        setState(() => _fetchingLocation = false);
        return;
      }
    }

    _locationData = await location.getLocation();

    setState(() {
      latitude = _locationData?.latitude;
      longitude = _locationData?.longitude;
      _fetchingLocation = false;
    });
  }

  

  Future<void> getWindowsLocation() async {
    final response =
        await http.get(Uri.parse('https://ipapi.co/json/'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      latitude = data['latitude'];
      longitude = data['longitude'];
    }
  }

  // 📸 CAMERA + 📍 LOCATION
  Future<void> _takePhoto() async {
  // -------------------------------
  // WINDOWS DESKTOP
  // -------------------------------
  if (Platform.isWindows) {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result == null) return;

    setState(() {
      _capturedImage = File(result.files.single.path!);
    });

    await getWindowsLocation(); // 🌍 IP-based
    return;
  }


  // -------------------------------
  // MOBILE (ANDROID / IOS)
  // -------------------------------
  final XFile? photo =
      await _picker.pickImage(source: ImageSource.camera);

  if (photo == null) return;

  setState(() {
    _capturedImage = File(photo.path);
    _fetchingLocation = true;
  });

  await _requestLocation();
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

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white.withOpacity(0.9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667EEA),
              Color(0xFF764BA2),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 30,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Create Account",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 30),

                        TextFormField(
                          controller: nameController,
                          decoration:
                              _inputDecoration("Name", Icons.person),
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: idController,
                          decoration:
                              _inputDecoration("User ID / Email", Icons.badge),
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          decoration:
                              _inputDecoration("Create Password", Icons.lock),
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: confirmPasswordController,
                          obscureText: true,
                          decoration: _inputDecoration(
                              "Re-enter Password", Icons.lock_outline),
                        ),

                        const SizedBox(height: 16),

                        // 📷 TAKE PHOTO FIELD
                        TextFormField(
                          readOnly: true,
                          onTap: _takePhoto,
                          decoration: _inputDecoration(
                            _fetchingLocation
                                ? "Fetching location..."
                                : latitude == null
                                    ? "Take a photo"
                                    : "Photo & location captured",
                            Icons.camera_alt,
                          ),
                        ),

                        if (_capturedImage != null) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _capturedImage!,
                              height: 120,
                              width: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],

                        const SizedBox(height: 30),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF667EEA),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              if (_capturedImage == null ||
                                  latitude == null ||
                                  longitude == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Photo & location required")),
                                );
                                return;
                              }

                              if (passwordController.text !=
                                  confirmPasswordController.text) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Passwords do not match")),
                                );
                                return;
                              }
                              _registerUser();
                            },

                            child: const Text(
                              "Register",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
