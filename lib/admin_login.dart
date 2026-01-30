import 'dart:math'; // For Random Captcha
import 'package:flutter/material.dart';
import 'admin_home_page.dart'; 
import 'main.dart'; // Import main to navigate back to User Login

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> with SingleTickerProviderStateMixin {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final captchaController = TextEditingController();

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

  // UI Helper (Matches User Login Style)
  InputDecoration _modernInput(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: const Color(0xFF6A8A73)),
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
            // 1. HEADER & USER BUTTON
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(), // Spacer
                  // USER BUTTON (Navigates back to Main)
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.person, color: Colors.white70, size: 20),
                    label: const Text(
                      "USER",
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            // 2. TITLE SECTION
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Admin Portal",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Secure access for administrators.",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // 3. WHITE SHEET (Form)
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
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

                          // Inputs
                          TextFormField(
                            controller: usernameController,
                            decoration: _modernInput("Admin ID", Icons.admin_panel_settings_outlined),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: _modernInput("Password", Icons.lock_outline),
                          ),
                          const SizedBox(height: 24),

                          // 🛡️ CAPTCHA SECTION
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Captcha Display Code
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(8),
                                        image: const DecorationImage(
                                          image: NetworkImage("https://www.transparenttextures.com/patterns/black-scales.png"), // Optional noise pattern
                                          opacity: 0.1,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      child: Text(
                                        _generatedCaptcha.split('').join(' '), // Add spacing
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22,
                                          letterSpacing: 4,
                                          color: Colors.black87,
                                          fontFamily: 'Courier', // Monospace looks more like code
                                        ),
                                      ),
                                    ),
                                    // Refresh Button
                                    IconButton(
                                      onPressed: _generateCaptcha,
                                      icon: const Icon(Icons.refresh, color: Color(0xFF6A8A73)),
                                      tooltip: "Refresh Captcha",
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: captchaController,
                                  decoration: _modernInput("Enter Captcha", Icons.security),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // LOGIN BUTTON
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6A8A73),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
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