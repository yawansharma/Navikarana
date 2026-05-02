import 'dart:math'; // For Random Captcha
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;

import 'admin_home_page.dart'; 
import 'main.dart'; // Import main to navigate back to User Login
import 'app_theme.dart';
import 'services/appwrite_service.dart'; // Make sure this path is correct for your project

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> with SingleTickerProviderStateMixin {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final captchaController = TextEditingController();
  bool _isObscure = true;

  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Captcha State
  String _generatedCaptcha = "";

  @override
  void initState() {
    super.initState();
    _generateCaptcha(); // Generate code on startup

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
    usernameController.dispose();
    passwordController.dispose();
    captchaController.dispose();
    super.dispose();
  }

  // ðŸŽ² GENERATE RANDOM CAPTCHA
  void _generateCaptcha() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Excluded confusing chars like I, 1, 0, O
    setState(() {
      _generatedCaptcha = List.generate(5, (index) => chars[Random().nextInt(chars.length)]).join();
    });
  }

  // ðŸ” LOGIN LOGIC
  Future<void> _login() async {
    // 1. Check Captcha
    if (captchaController.text.toUpperCase().trim() != _generatedCaptcha) {
      _showError("Incorrect Captcha. Try again.");
      _generateCaptcha(); // Refresh on fail
      captchaController.clear();
      return;
    }

    final adminId = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (adminId.isEmpty || password.isEmpty) {
      _showError("Please enter Admin ID and Password.");
      return;
    }

    final statusText = ValueNotifier("Authenticating...");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: ValueListenableBuilder<String>(
            valueListenable: statusText,
            builder: (context, value, child) {
              return Row(
                children: [
                  const CircularProgressIndicator(color: Color(0xFF6A8A73)),
                  const SizedBox(width: 20),
                  Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
                ],
              );
            },
          ),
        ),
      ),
    );

    try {
      // Use Appwrite query instead of Firestore
      final query = await AppwriteService.databases.listDocuments(
        databaseId: '69ecebfb0033cf785741',
        collectionId: 'users',
        queries: [
          Query.equal('username', adminId),
          Query.equal('password', password),
        ],
      );

      if (query.documents.isEmpty) {
        _dismissAndShowError("Invalid Admin ID or Password");
        _generateCaptcha();
        return;
      }

      final doc = query.documents.first;
      final data = doc.data;

      // RBAC Security Check
      final role = data['role'] as String?;
      if (role != 'admin' && role != 'dean') {
        _dismissAndShowError("Unauthorized access. This portal is for Administrators only.");
        _generateCaptcha();
        return;
      }

      // Check account status
      if (data['status'] == 'disabled') {
        _dismissAndShowError("Your admin account has been disabled. Please contact the Dean.");
        _generateCaptcha();
        return;
      }

      statusText.value = "Finalizing...";

      // Update last login using ISO-8601 instead of FieldValue.serverTimestamp()
      await AppwriteService.databases.updateDocument(
        databaseId: '69ecebfb0033cf785741',
        collectionId: 'users',
        documentId: doc.$id,
        data: {
          'lastLogin': DateTime.now().toIso8601String(),
        },
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      final adminName = data['name'] ?? adminId;
      final adminLevel = data['level'] is int ? data['level'] as int : 1;
      Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => AdminHomePage(
              adminName: adminName,
              adminId: adminId,
              adminLevel: adminLevel,
          ),
      ));
    } catch (e) {
      _dismissAndShowError("An unexpected error occurred: $e");
    }
  }

  void _dismissAndShowError(String message) {
    if (mounted && Navigator.canPop(context)) Navigator.of(context).pop();
    _showError(message);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kDark,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER & USER BUTTON (Updated to match main.dart)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "upasthiti",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 1.2),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.person_outline, color: Colors.white70, size: 18),
                    label: const Text(
                      "USER",
                      style: TextStyle(
                          color: Colors.white70, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            // 2. TITLE SECTION (Polished Typography)
             Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    "Administrator Access",
                    style: AppTheme.headingWhite,
                  ),
                  const SizedBox(height: 8),
                   Text(
                    "Please authenticate to manage the system.",
                    style: AppTheme.subheadingGrey,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 3. WHITE SHEET (Form)
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Container(
                    width: double.infinity,
                    decoration: AppTheme.bottomSheet,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          AppTheme.sheetHandle,

                          // Inputs
                          TextFormField(
                            controller: usernameController,
                            textInputAction: TextInputAction.next,
                            decoration: AppTheme.inputDecoration("Admin ID", Icons.admin_panel_settings_outlined),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: passwordController,
                            obscureText: _isObscure,
                            textInputAction: TextInputAction.next,
                            decoration: AppTheme.inputDecoration(
                              "Password", 
                              Icons.lock_outline,
                              suffix: IconButton(
                                icon: Icon(
                                  _isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _isObscure = !_isObscure),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ðŸ›¡ï¸ CAPTCHA SECTION (Polished UI)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade200, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Security Check", 
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Captcha Display Code
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.grey.shade300),
                                          image: const DecorationImage(
                                            image: NetworkImage("https://www.transparenttextures.com/patterns/black-scales.png"), 
                                            opacity: 0.05,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            _generatedCaptcha.split('').join(' '), // Add spacing
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 22,
                                              letterSpacing: 6,
                                              color: Color(0xFF2D3142),
                                              fontFamily: 'Courier', 
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Refresh Button
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6A8A73).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12)
                                      ),
                                      child: IconButton(
                                        onPressed: _generateCaptcha,
                                        icon: const Icon(Icons.refresh_rounded, color: AppTheme.kGreen),
                                        tooltip: "Refresh Captcha",
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: captchaController,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _login(),
                                  decoration: AppTheme.inputDecoration("Enter Captcha", Icons.security),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // LOGIN BUTTON
                          SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.kGreen,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                "Secure Login",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          // ---------------------------------------------------
                          // PROFESSIONAL LOGO FOOTER (Updated to withValues)
                          // ---------------------------------------------------
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
                                        'assets/upasthiti.png',
                                        width: 90, 
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "POWERED BY upasthiti",
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
                          const SizedBox(height: 40), // Clear bottom of screen
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