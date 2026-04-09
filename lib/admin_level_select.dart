import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_login.dart';
import 'main.dart';
import 'app_theme.dart';

/// Page shown when user taps "ADMIN" — lets them pick their admin level
/// before proceeding to the login form.
class AdminLevelSelectPage extends StatelessWidget {
  const AdminLevelSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kDark,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────────
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
                      letterSpacing: 1.2,
                    ),
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
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Title ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Select Admin Level", style: AppTheme.headingWhite),
                  const SizedBox(height: 8),
                  Text(
                    "Choose your administration tier to proceed.",
                    style: AppTheme.subheadingGrey,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // ── Level Cards ────────────────────────────────────────────────
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
                        const SizedBox(height: 8),

                        _LevelCard(
                          level: 1,
                          title: "Admin Level 1",
                          subtitle: "Manages Level 2 administrators",
                          icon: Icons.shield_outlined,
                          color: const Color(0xFF1B5E20),
                          onTap: () => _navigateToLogin(context, 1),
                        ),
                        const SizedBox(height: 16),

                        _LevelCard(
                          level: 2,
                          title: "Admin Level 2",
                          subtitle: "Manages Level 3 administrators",
                          icon: Icons.security_outlined,
                          color: const Color(0xFF2E7D32),
                          onTap: () => _navigateToLogin(context, 2),
                        ),
                        const SizedBox(height: 16),

                        _LevelCard(
                          level: 3,
                          title: "Admin Level 3",
                          subtitle: "Manages classes, students & attendance",
                          icon: Icons.admin_panel_settings_outlined,
                          color: AppTheme.kGreen,
                          onTap: () => _navigateToLogin(context, 3),
                        ),

                        // ── Footer ──────────────────────────────────────────
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

  void _navigateToLogin(BuildContext context, int level) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminLoginPage(adminLevel: level),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final int level;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _LevelCard({
    required this.level,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "L$level",
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
