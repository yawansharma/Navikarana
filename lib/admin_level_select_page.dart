import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'admin_login.dart';

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
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "upasthiti",
                    style: TextStyle(
                      color: AppTheme.kGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 1.2,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // ── Title ────────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Admin Portal",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Select your access level to continue.",
                    style: TextStyle(fontSize: 14, color: Colors.white54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // ── Rising Sheet with Level Cards ────────────────────────
            Expanded(
              child: RisingSheet(
                child: Container(
                  width: double.infinity,
                  decoration: AppTheme.bottomSheet,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                    child: Column(
                      children: [
                        AppTheme.sheetHandle,
                        const SizedBox(height: 8),

                        // Instruction chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.kGreen.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                                color:
                                    AppTheme.kGreen.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.info_outline,
                                  size: 14,
                                  color: AppTheme.kGreen
                                      .withValues(alpha: 0.8)),
                              const SizedBox(width: 6),
                              Text(
                                "Credentials must match the selected level",
                                style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      AppTheme.kGreen.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Level Cards
                        _LevelCard(
                          level: 1,
                          title: "Level 1 Admin",
                          subtitle: "Institution-level control",
                          description:
                              "Full institutional oversight, approve Level 2 leave requests, and cross-department reporting.",
                          icon: Icons.account_balance_outlined,
                          onTap: () => _goToLogin(context, 1),
                        ),
                        const SizedBox(height: 16),
                        _LevelCard(
                          level: 2,
                          title: "Level 2 Admin",
                          subtitle: "Department-level oversight",
                          description:
                              "Oversee multiple classes, approve Level 3 leave requests, and manage department analytics.",
                          icon: Icons.domain_outlined,
                          onTap: () => _goToLogin(context, 2),
                        ),
                        const SizedBox(height: 16),
                        _LevelCard(
                          level: 3,
                          title: "Level 3 Admin",
                          subtitle: "Class-level management",
                          description:
                              "Manage individual classes, run attendance periods, and review your class logs.",
                          icon: Icons.class_outlined,
                          onTap: () => _goToLogin(context, 3),
                        ),

                        const SizedBox(height: 40),

                        // Footer logo
                        Center(
                          child: Opacity(
                            opacity: 0.5,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ColorFiltered(
                                  colorFilter: ColorFilter.mode(
                                    AppTheme.kGreen.withValues(alpha: 0.1),
                                    BlendMode.srcATop,
                                  ),
                                  child: Image.asset(
                                    'assets/upasthiti.png',
                                    width: 60,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "POWERED BY upasthiti",
                                  style: TextStyle(
                                    color: AppTheme.kGreen
                                        .withValues(alpha: 0.8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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

  void _goToLogin(BuildContext context, int level) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminLoginPage(requiredLevel: level),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Level Card Widget
// ─────────────────────────────────────────────────────────────────────────────
class _LevelCard extends StatelessWidget {
  final int level;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _LevelCard({
    required this.level,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  // Each level gets a slightly different accent shade
  Color get _accentColor {
    switch (level) {
      case 1:
        return const Color(0xFF7A6A8A); // Muted violet — top admin
      case 2:
        return const Color(0xFF4E7A8A); // Teal-blue — department
      case 3:
        return const Color(0xFF6A8A73); // Sage green — class level
      default:
        return AppTheme.kGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _accentColor.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _accentColor.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon badge
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: _accentColor, size: 26),
            ),
            const SizedBox(width: 16),

            // Text block
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "L$level",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _accentColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: _accentColor.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}