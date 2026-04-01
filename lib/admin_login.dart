import 'dart:math'; // For Random Captcha
import 'package:flutter/material.dart';
import 'admin_home_page.dart'; 
import 'main.dart'; // Import main to navigate back to User Login
import 'app_theme.dart';

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

  // 🎲 GENERATE RANDOM CAPTCHA
  void _generateCaptcha() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Excluded confusing chars like I, 1, 0, O
    setState(() {
      _generatedCaptcha = List.generate(5, (index) => chars[Random().nextInt(chars.length)]).join();
    });
  }

  // 🔐 LOGIN LOGIC
  Future<void> _login() async {
    const demoAdminId = "admin";
    const demoPassword = "admin123";

    // 1. Check Captcha
    if (captchaController.text.toUpperCase().trim() != _generatedCaptcha) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Incorrect Captcha. Try again.")),
      );
      _generateCaptcha(); // Refresh on fail
      captchaController.clear();
      return;
    }

    // 2. Check Credentials
    if (usernameController.text.trim() == demoAdminId && 
        passwordController.text.trim() == demoPassword) {
      Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => const AdminHomePage(adminName: "Demo Admin"),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid Admin ID or Password")),
      );
      _generateCaptcha(); // Refresh on fail
    }
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
                    "Navikarana",
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

                          // 🛡️ CAPTCHA SECTION (Polished UI)
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