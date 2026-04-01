
import 'dart:async'; // Required for Splash Screen Timer
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'home_page.dart';
import 'register_page.dart';
import 'admin_login.dart';
import 'app_theme.dart';

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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const SplashScreen(),
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
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.kGreen.withValues(alpha: 0.15),
                    blurRadius: 60,
                    spreadRadius: 10,
                  ),
                ],
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

class _LoginPageState extends State<LoginPage> {
  final uniqueCodeController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isObscure = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    uniqueCodeController.dispose();
    passwordController.dispose();
    super.dispose();
  }



  Future<void> _login() async {
    if (uniqueCodeController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
      _showSnackBar("Please enter your unique code and password.");
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

      statusText.value = "Finalizing...";

      await FirebaseFirestore.instance
          .collection('users')
          .doc(doc.id)
          .update({
        'lastLogin': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.of(context).pop();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(
            name: data['name'] ?? "User",
            username: data['username'] ?? "Unknown",
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kDark,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome Back",
                    style: AppTheme.headingWhite,
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Verify your unique code and identity.",
                    style: AppTheme.subheadingGrey,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: RisingSheet(
                child: Container(
                  width: double.infinity,
                  decoration: AppTheme.bottomSheet,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          AppTheme.sheetHandle,
                          TextFormField(
                            controller: uniqueCodeController,
                            textInputAction: TextInputAction.next,
                            decoration: AppTheme.inputDecoration(
                                "Unique Code", Icons.badge_outlined),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: passwordController,
                            obscureText: _isObscure,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _login(),
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
                          const SizedBox(height: 40),
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
                                "Sign In",
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
                                    color: AppTheme.kGreen,
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
                          const SizedBox(height: 40),
                        ],
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
