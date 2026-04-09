import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'app_theme.dart';

// =============================================================================
// AdminL1SupervisionHub — landing screen for Level 1 admin.
// Two cards: manage Level 2 admins  OR  supervise Level 3 admins + their classes.
// =============================================================================
class AdminL1SupervisionHub extends StatelessWidget {
  final String l1AdminId;
  final String l1AdminName;

  const AdminL1SupervisionHub({
    super.key,
    required this.l1AdminId,
    required this.l1AdminName,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
      children: [
        // Greeting
        Text(
          "Welcome back,",
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500),
        ),
        Text(
          l1AdminName,
          style: GoogleFonts.poppins(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.kGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.kGreen.withValues(alpha: 0.25)),
          ),
          child: Text(
            "ADMINISTRATOR LEVEL 1  •  FULL OVERSIGHT",
            style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppTheme.kGreen,
                letterSpacing: 0.5),
          ),
        ),

        const SizedBox(height: 32),

        // Live counters row
        _LiveCountRow(),

        const SizedBox(height: 28),

        Text(
          "Supervision",
          style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 14),

        // ── Level 2 card ──────────────────────────────────────────────────────
        _HubCard(
          icon: Icons.security_outlined,
          iconColor: const Color(0xFF2E7D32),
          title: "Level 2 Admins",
          subtitle:
              "View, suspend or remove all Level 2 administrators.",
          actionLabel: "Manage",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminL1AdminListPage(
                role: 'admin_l2',
                level: 2,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── Level 3 card ──────────────────────────────────────────────────────
        _HubCard(
          icon: Icons.admin_panel_settings_outlined,
          iconColor: AppTheme.kGreen,
          title: "Level 3 Admins",
          subtitle:
              "Supervise classes, manage students, and update class details.",
          actionLabel: "Supervise",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminL1AdminListPage(
                role: 'admin_l3',
                level: 3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _LiveCountRow — shows real-time counts of L2/L3 admins and total classes
// ---------------------------------------------------------------------------
class _LiveCountRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LiveCountCard(
          label: "L2 Admins",
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'admin_l2')
              .snapshots(),
          color: const Color(0xFF2E7D32),
          icon: Icons.security_outlined,
        ),
        const SizedBox(width: 12),
        _LiveCountCard(
          label: "L3 Admins",
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'admin_l3')
              .snapshots(),
          color: AppTheme.kGreen,
          icon: Icons.admin_panel_settings_outlined,
        ),
        const SizedBox(width: 12),
        _LiveCountCard(
          label: "Classes",
          stream: FirebaseFirestore.instance
              .collection('classes')
              .snapshots(),
          color: Colors.blue,
          icon: Icons.class_outlined,
        ),
      ],
    );
  }
}

class _LiveCountCard extends StatelessWidget {
  final String label;
  final Stream<QuerySnapshot> stream;
  final Color color;
  final IconData icon;

  const _LiveCountCard({
    required this.label,
    required this.stream,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snap) {
          final count = snap.hasData ? snap.data!.docs.length : 0;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3))
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(9)),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(height: 7),
                Text("$count",
                    style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: Colors.grey.shade500)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  const _HubCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
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
            border: Border.all(color: iconColor.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(actionLabel,
                    style: TextStyle(
                        color: iconColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// AdminL1AdminListPage — generic admin list for L1 oversight.
// • role == 'admin_l2'  → shows all L2 admins, delete / suspend only
// • role == 'admin_l3'  → shows all L3 admins, delete / suspend + class supervision
// =============================================================================
class AdminL1AdminListPage extends StatefulWidget {
  final String role;
  final int level;

  const AdminL1AdminListPage({
    super.key,
    required this.role,
    required this.level,
  });

  @override
  State<AdminL1AdminListPage> createState() => _AdminL1AdminListPageState();
}

class _AdminL1AdminListPageState extends State<AdminL1AdminListPage> {
  final List<String> departments = [
    'CSE', 'ISE', 'ECE', 'ME', 'CE', 'Basic Sciences', 'General Admin'
  ];

  // ── onboard new admin ────────────────────────────────────────────────────
  void _showAddAdminSheet() {
    final usernameCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String selectedDept = departments.first;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Onboard Level ${widget.level} Admin",
                  style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                "Create a Level ${widget.level} admin account.",
                style:
                    TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: usernameCtrl,
                decoration: InputDecoration(
                    labelText: 'Admin Username (ID)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                decoration: InputDecoration(
                    labelText: 'Initial Password',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedDept,
                decoration: InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
                items: departments
                    .map((d) =>
                        DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) =>
                    setSheetState(() => selectedDept = v!),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (usernameCtrl.text.trim().isEmpty ||
                              passCtrl.text.trim().isEmpty) return;
                          setSheetState(() => saving = true);
                          final exists = await FirebaseFirestore.instance
                              .collection('users')
                              .where('username',
                                  isEqualTo: usernameCtrl.text.trim())
                              .get();
                          if (exists.docs.isNotEmpty) {
                            setSheetState(() => saving = false);
                            ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Username already exists.')));
                            return;
                          }
                          await FirebaseFirestore.instance
                              .collection('users')
                              .add({
                            'username': usernameCtrl.text.trim(),
                            'name': nameCtrl.text.trim().isNotEmpty
                                ? nameCtrl.text.trim()
                                : usernameCtrl.text.trim(),
                            'password': passCtrl.text.trim(),
                            'role': widget.role,
                            'status': 'active',
                            'department': selectedDept,
                            'createdBy': 'admin_l1',
                            'managedClasses': [],
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                          if (!mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'L${widget.level} Admin onboarded successfully.')),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.kGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text("Create L${widget.level} Admin",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  // ── admin detail bottom sheet ────────────────────────────────────────────
  void _showAdminDetails(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final bool isActive = data['status'] != 'disabled';
    final passCtrl = TextEditingController(text: data['password']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const CircleAvatar(
                        radius: 24,
                        backgroundColor: Color(0xFFF1F4F2),
                        child: Icon(Icons.person, color: AppTheme.kGreen)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              data['name'] ?? data['username'] ?? 'Admin',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          Text(
                              "${data['department'] ?? 'No Dept'}  •  ${data['username']}",
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isActive ? "ACTIVE" : "DISABLED",
                        style: TextStyle(
                            color: isActive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Supervise classes button (L3 only) ───────────────────
                if (widget.level == 3) ...[
                  const Text("Class Supervision",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminL1ClassSupervisionPage(
                              l3AdminId: data['username'],
                              l3AdminName:
                                  data['name'] ?? data['username'],
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.class_outlined),
                      label: const Text("Supervise Classes",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.kGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Override password ────────────────────────────────────
                const Text("Account Controls",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 10),
                TextField(
                  controller: passCtrl,
                  decoration: InputDecoration(
                    labelText: 'Override Password',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.save, color: AppTheme.kGreen),
                      onPressed: () async {
                        if (passCtrl.text.trim().isEmpty) return;
                        await doc.reference.update(
                            {'password': passCtrl.text.trim()});
                        if (!mounted) return;
                        ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                                content: Text('Password overridden.')));
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Suspend / reactivate ──────────────────────────────────
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                      isActive
                          ? Icons.block
                          : Icons.check_circle_outline,
                      color: isActive ? Colors.orange : Colors.green),
                  title: Text(
                      isActive
                          ? "Suspend Account"
                          : "Reactivate Account",
                      style:
                          const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    isActive
                        ? "Admin will not be able to log in."
                        : "Restore full admin access.",
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500),
                  ),
                  onTap: () async {
                    await doc.reference.update(
                        {'status': isActive ? 'disabled' : 'active'});
                    if (!mounted) return;
                    Navigator.pop(ctx);
                  },
                ),

                const Divider(),

                // ── Delete ────────────────────────────────────────────────
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_forever,
                      color: Colors.red),
                  title: const Text("Delete Administrator",
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.red)),
                  subtitle: Text(
                      "Permanently remove this admin record.",
                      style: TextStyle(
                          fontSize: 12, color: Colors.red.shade300)),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: ctx,
                      builder: (c) => AlertDialog(
                        title: const Text("Confirm Deletion"),
                        content: const Text(
                            "This action cannot be undone. Delete this admin?"),
                        actions: [
                          TextButton(
                              onPressed: () =>
                                  Navigator.pop(c, false),
                              child: const Text("Cancel")),
                          TextButton(
                              onPressed: () => Navigator.pop(c, true),
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.red),
                              child: const Text("Delete")),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await doc.reference.delete();
                      if (!mounted) return;
                      Navigator.pop(ctx);
                    }
                  },
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String pageTitle =
        "Level ${widget.level} Admins";

    return Scaffold(
      backgroundColor: AppTheme.kDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pageTitle,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            Text(
              widget.level == 2
                  ? "All Level 2 administrators"
                  : "All Level 3 administrators",
              style: const TextStyle(fontSize: 11, color: Colors.white60),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.kGreen,
        foregroundColor: Colors.white,
        onPressed: _showAddAdminSheet,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text("Onboard L${widget.level} Admin",
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: RisingSheet(
              child: Container(
                decoration: AppTheme.bottomSheet,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: widget.role)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.kGreen));
                    }

                    final admins = snapshot.data!.docs;

                    if (admins.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shield_outlined,
                                size: 60, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text("No Level ${widget.level} Admins",
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey)),
                            const SizedBox(height: 8),
                            Text("Tap + to onboard one.",
                                style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 13)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                      itemCount: admins.length,
                      itemBuilder: (context, index) {
                        final doc = admins[index];
                        final data =
                            doc.data() as Map<String, dynamic>;
                        final isActive =
                            data['status'] != 'disabled';
                        final Timestamp? lastLogin =
                            data['lastLogin'] as Timestamp?;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                                color: Colors.grey.shade200),
                          ),
                          elevation: 0,
                          color: Colors.white,
                          child: InkWell(
                            onTap: () => _showAdminDetails(doc),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: isActive
                                        ? AppTheme.kGreen
                                            .withValues(alpha: 0.1)
                                        : Colors.red
                                            .withValues(alpha: 0.1),
                                    child: Icon(
                                        Icons.admin_panel_settings,
                                        color: isActive
                                            ? AppTheme.kGreen
                                            : Colors.red),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            data['name'] ??
                                                data['username'],
                                            style: const TextStyle(
                                                fontWeight:
                                                    FontWeight.bold,
                                                fontSize: 15)),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                  horizontal: 6,
                                                  vertical: 2),
                                              decoration: BoxDecoration(
                                                  color: Colors
                                                      .grey.shade100,
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(4)),
                                              child: Text(
                                                  data['department'] ??
                                                      'No Dept',
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.grey
                                                          .shade700,
                                                      fontWeight:
                                                          FontWeight
                                                              .bold)),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                                "• ${data['username']}",
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey
                                                        .shade500)),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          lastLogin != null
                                              ? "Last login: ${DateFormat('MMM dd, hh:mm a').format(lastLogin.toDate())}"
                                              : "Never logged in",
                                          style: TextStyle(
                                              fontSize: 11,
                                              color:
                                                  Colors.grey.shade400),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // L3-only "classes" chip
                                  if (widget.level == 3)
                                    _AdminClassCount(
                                        adminId: data['username']),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.kGreen
                                          .withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Text("L${widget.level}",
                                        style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.kGreen)),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.chevron_right,
                                      color: Colors.grey.shade300),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Live class count chip shown on L3 admin cards
class _AdminClassCount extends StatelessWidget {
  final String adminId;
  const _AdminClassCount({required this.adminId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .where('createdBy', isEqualTo: adminId)
          .snapshots(),
      builder: (context, snap) {
        final count = snap.hasData ? snap.data!.docs.length : 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.class_outlined,
                  size: 10, color: Colors.blue),
              const SizedBox(width: 3),
              Text("$count",
                  style: const TextStyle(
                      fontSize: 10,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }
}

// =============================================================================
// AdminL1ClassSupervisionPage — full class management for a specific L3 admin,
// operated by Level 1. Full CRUD on classes + student management.
// =============================================================================
class AdminL1ClassSupervisionPage extends StatefulWidget {
  final String l3AdminId;
  final String l3AdminName;

  const AdminL1ClassSupervisionPage({
    super.key,
    required this.l3AdminId,
    required this.l3AdminName,
  });

  @override
  State<AdminL1ClassSupervisionPage> createState() =>
      _AdminL1ClassSupervisionPageState();
}

class _AdminL1ClassSupervisionPageState
    extends State<AdminL1ClassSupervisionPage> {
  // ── Create class ────────────────────────────────────────────────────────────
  void _openCreateClassDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    Map<String, dynamic>? pendingBoundary;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text(
            "New Class for ${widget.l3AdminName}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                    labelText: "Class Name (e.g. CS101)"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(
                    labelText: "Join Code (e.g. CS101-2024)"),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () async {
                  final result = await _openBoundaryPicker(
                    ctx,
                    nameCtrl.text.trim().isEmpty
                        ? "New Class"
                        : nameCtrl.text.trim(),
                    pendingBoundary,
                  );
                  if (result != null) setSt(() => pendingBoundary = result);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: pendingBoundary != null
                        ? AppTheme.kGreen.withValues(alpha: 0.08)
                        : Colors.red.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: pendingBoundary != null
                          ? AppTheme.kGreen
                          : Colors.red.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        pendingBoundary != null
                            ? Icons.location_on
                            : Icons.location_off_outlined,
                        color: pendingBoundary != null
                            ? AppTheme.kGreen
                            : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          pendingBoundary != null
                              ? "Boundary set — ${(pendingBoundary!['radiusMeters'] as num).toStringAsFixed(0)} m"
                              : "Set Boundary (required)",
                          style: TextStyle(
                            fontSize: 13,
                            color: pendingBoundary != null
                                ? AppTheme.kGreen
                                : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          size: 12,
                          color: pendingBoundary != null
                              ? AppTheme.kGreen
                              : Colors.red),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.kGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              onPressed: nameCtrl.text.isNotEmpty &&
                      codeCtrl.text.isNotEmpty &&
                      pendingBoundary != null
                  ? () async {
                      await FirebaseFirestore.instance
                          .collection('classes')
                          .doc(codeCtrl.text.trim())
                          .set({
                        'className': nameCtrl.text.trim(),
                        'classCode': codeCtrl.text.trim(),
                        'adminName': widget.l3AdminName,
                        'createdBy': widget.l3AdminId,
                        'studentIds': [],
                        'boundary': pendingBoundary,
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  "Class \"${nameCtrl.text.trim()}\" created.")),
                        );
                      }
                    }
                  : null,
              child: const Text("Create"),
            ),
          ],
        ),
      ),
    );
  }

  // ── Boundary picker dialog ─────────────────────────────────────────────────
  Future<Map<String, dynamic>?> _openBoundaryPicker(
    BuildContext parentCtx,
    String className,
    Map<String, dynamic>? existing,
  ) async {
    LatLng pos;
    if (existing != null) {
      pos = LatLng((existing['lat'] as num).toDouble(),
          (existing['lng'] as num).toDouble());
    } else {
      try {
        final loc = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        pos = LatLng(loc.latitude, loc.longitude);
      } catch (_) {
        pos = const LatLng(20.59, 78.96);
      }
    }
    double radius =
        existing != null ? (existing['radiusMeters'] as num).toDouble() : 100.0;
    LatLng current = pos;
    final MapController mapController = MapController();

    return showDialog<Map<String, dynamic>>(
      context: parentCtx,
      builder: (dialogCtx) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SizedBox(
          height: 560,
          width: 600,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: const BoxDecoration(
                  color: AppTheme.kGreen,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.my_location,
                        color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Set Class Boundary",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          Text(className,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(dialogCtx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StatefulBuilder(builder: (_, setSt) {
                  return Stack(
                    children: [
                      FlutterMap(
                        mapController: mapController,
                        options: MapOptions(
                          initialCenter: pos,
                          initialZoom: 16,
                          onTap: (_, p) => setSt(() => current = p),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.virtualvision.admin',
                          ),
                          CircleLayer(circles: [
                            CircleMarker(
                              point: current,
                              radius: radius,
                              useRadiusInMeter: true,
                              color: AppTheme.kGreen.withValues(alpha: 0.18),
                              borderColor: AppTheme.kGreen,
                              borderStrokeWidth: 2,
                            ),
                          ]),
                          MarkerLayer(markers: [
                            Marker(
                              point: current,
                              width: 40,
                              height: 40,
                              child: const Icon(Icons.location_on,
                                  color: Colors.red, size: 40),
                            ),
                          ]),
                        ],
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20)),
                          ),
                          padding:
                              const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                const Icon(Icons.my_location,
                                    size: 13, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text(
                                  "${current.latitude.toStringAsFixed(5)}, ${current.longitude.toStringAsFixed(5)}",
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                              ]),
                              const SizedBox(height: 6),
                              Row(children: [
                                const Icon(Icons.radio_button_checked,
                                    size: 13, color: AppTheme.kGreen),
                                const SizedBox(width: 6),
                                Text(
                                  "Radius: ${radius.toStringAsFixed(0)} m",
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                                Expanded(
                                  child: Slider(
                                    value: radius,
                                    min: 30,
                                    max: 500,
                                    divisions: 47,
                                    activeColor: AppTheme.kGreen,
                                    onChanged: (v) =>
                                        setSt(() => radius = v),
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.kGreen,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                  onPressed: () =>
                                      Navigator.pop(dialogCtx, {
                                    'lat': current.latitude,
                                    'lng': current.longitude,
                                    'radiusMeters': radius,
                                  }),
                                  child: const Text("Confirm Boundary",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Classes",
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.kGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: AppTheme.kGreen.withValues(alpha: 0.3)),
              ),
              child: Text(
                "L3: ${widget.l3AdminName.toUpperCase()}",
                style: GoogleFonts.poppins(
                    color: AppTheme.kGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                    letterSpacing: 0.5),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.kGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("New Class",
            style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _openCreateClassDialog,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: RisingSheet(
              child: Container(
                decoration: AppTheme.bottomSheet,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('classes')
                      .where('createdBy', isEqualTo: widget.l3AdminId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.kGreen));
                    }

                    final classes = snapshot.data!.docs;

                    if (classes.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.class_outlined,
                                size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            const Text("No Classes Yet",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey)),
                            const SizedBox(height: 8),
                            Text("Tap + to create one.",
                                style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 13)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(20, 24, 20, 100),
                      itemCount: classes.length,
                      itemBuilder: (context, index) {
                        final doc = classes[index];
                        final data =
                            doc.data() as Map<String, dynamic>;
                        final int enrolled =
                            (data['studentIds'] as List? ?? []).length;
                        final bool hasBoundary =
                            data['boundary'] != null;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                                color: Colors.grey.shade200),
                          ),
                          elevation: 0,
                          color: Colors.white,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (_, __, ___) =>
                                    _L1ClassDetailPage(
                                  classId: doc.id,
                                  classData: data,
                                  l3AdminId: widget.l3AdminId,
                                  l3AdminName: widget.l3AdminName,
                                ),
                                transitionsBuilder: (_, anim, __, child) =>
                                    FadeTransition(
                                  opacity: CurvedAnimation(
                                      parent: anim,
                                      curve: Curves.easeIn),
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                            begin:
                                                const Offset(0, 0.06),
                                            end: Offset.zero)
                                        .animate(CurvedAnimation(
                                            parent: anim,
                                            curve:
                                                Curves.fastOutSlowIn)),
                                    child: child,
                                  ),
                                ),
                                transitionDuration:
                                    const Duration(milliseconds: 350),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 18),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: AppTheme.kGreen
                                          .withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.class_,
                                        color: AppTheme.kGreen,
                                        size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['className'] ??
                                              'Unknown Class',
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "Code: ${data['classCode'] ?? doc.id}",
                                          style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color:
                                                  Colors.grey.shade500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      _miniChip(
                                          "$enrolled students",
                                          Icons.people_alt_outlined,
                                          Colors.blue),
                                      const SizedBox(height: 4),
                                      _miniChip(
                                        hasBoundary
                                            ? "Boundary Set"
                                            : "No Boundary",
                                        Icons.my_location,
                                        hasBoundary
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.chevron_right,
                                      color: Colors.grey.shade400,
                                      size: 18),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// =============================================================================
// _L1ClassDetailPage — full class detail with write access for L1 admin.
// Can: rename class, edit boundary, delete class, manage students.
// =============================================================================
class _L1ClassDetailPage extends StatefulWidget {
  final String classId;
  final Map<String, dynamic> classData;
  final String l3AdminId;
  final String l3AdminName;

  const _L1ClassDetailPage({
    required this.classId,
    required this.classData,
    required this.l3AdminId,
    required this.l3AdminName,
  });

  @override
  State<_L1ClassDetailPage> createState() => _L1ClassDetailPageState();
}

class _L1ClassDetailPageState extends State<_L1ClassDetailPage> {
  late Map<String, dynamic> _classData;

  @override
  void initState() {
    super.initState();
    _classData = Map<String, dynamic>.from(widget.classData);
  }

  String get _className => _classData['className'] as String? ?? 'Class';
  String get _classCode => _classData['classCode'] as String? ?? widget.classId;
  List<String> get _studentIds =>
      (_classData['studentIds'] as List<dynamic>? ?? []).cast<String>();

  // ── Rename class ───────────────────────────────────────────────────────────
  void _showRenameDialog() {
    final ctrl = TextEditingController(text: _className);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Rename Class",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: "Class Name"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.kGreen,
                foregroundColor: Colors.white),
            onPressed: () async {
              final newName = ctrl.text.trim();
              if (newName.isEmpty) return;
              await FirebaseFirestore.instance
                  .collection('classes')
                  .doc(widget.classId)
                  .update({'className': newName});
              setState(() => _classData['className'] = newName);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Class renamed.")));
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // ── Delete class ───────────────────────────────────────────────────────────
  Future<void> _deleteClass() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Class?",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          "Deleting \"$_className\" will permanently remove the class, all its periods, and all linked attendance records.",
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white),
            child: const Text("Delete Class"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final periodsSnap = await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('periods')
        .get();
    for (final doc in periodsSnap.docs) await doc.reference.delete();

    final logsSnap = await FirebaseFirestore.instance
        .collection('attendance_logs')
        .where('classId', isEqualTo: widget.classId)
        .get();
    for (final doc in logsSnap.docs) await doc.reference.delete();

    await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .delete();

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("\"$_className\" deleted.")));
    }
  }

  // ── Boundary picker ────────────────────────────────────────────────────────
  Future<void> _openBoundaryPicker() async {
    final boundary = _classData['boundary'];
    LatLng pos;
    if (boundary != null) {
      pos = LatLng((boundary['lat'] as num).toDouble(),
          (boundary['lng'] as num).toDouble());
    } else {
      try {
        final loc = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        pos = LatLng(loc.latitude, loc.longitude);
      } catch (_) {
        pos = const LatLng(20.59, 78.96);
      }
    }
    if (!mounted) return;
    double radius =
        boundary != null ? (boundary['radiusMeters'] as num).toDouble() : 100.0;
    LatLng current = pos;
    final MapController mapController = MapController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SizedBox(
          height: 560,
          width: 600,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: const BoxDecoration(
                  color: AppTheme.kGreen,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.my_location,
                        color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Edit Class Boundary",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          Text(_className,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StatefulBuilder(builder: (ctx, setSt) {
                  return Stack(
                    children: [
                      FlutterMap(
                        mapController: mapController,
                        options: MapOptions(
                          initialCenter: pos,
                          initialZoom: 16,
                          onTap: (_, p) => setSt(() => current = p),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.virtualvision.admin',
                          ),
                          CircleLayer(circles: [
                            CircleMarker(
                              point: current,
                              radius: radius,
                              useRadiusInMeter: true,
                              color: AppTheme.kGreen
                                  .withValues(alpha: 0.18),
                              borderColor: AppTheme.kGreen,
                              borderStrokeWidth: 2,
                            ),
                          ]),
                          MarkerLayer(markers: [
                            Marker(
                              point: current,
                              width: 40,
                              height: 40,
                              child: const Icon(Icons.location_on,
                                  color: Colors.red, size: 40),
                            ),
                          ]),
                        ],
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20)),
                          ),
                          padding:
                              const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(children: [
                                const Icon(Icons.my_location,
                                    size: 13, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text(
                                  "${current.latitude.toStringAsFixed(5)}, ${current.longitude.toStringAsFixed(5)}",
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                              ]),
                              const SizedBox(height: 6),
                              Row(children: [
                                const Icon(Icons.radio_button_checked,
                                    size: 13, color: AppTheme.kGreen),
                                const SizedBox(width: 6),
                                Text(
                                  "Radius: ${radius.toStringAsFixed(0)} m",
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                                Expanded(
                                  child: Slider(
                                    value: radius,
                                    min: 30,
                                    max: 500,
                                    divisions: 47,
                                    activeColor: AppTheme.kGreen,
                                    onChanged: (v) =>
                                        setSt(() => radius = v),
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.kGreen,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                  onPressed: () async {
                                    final newBoundary = {
                                      'lat': current.latitude,
                                      'lng': current.longitude,
                                      'radiusMeters': radius,
                                    };
                                    await FirebaseFirestore.instance
                                        .collection('classes')
                                        .doc(widget.classId)
                                        .update({'boundary': newBoundary});
                                    setState(() =>
                                        _classData['boundary'] =
                                            newBoundary);
                                    if (mounted) Navigator.pop(context);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text(
                                                  "Boundary saved.")));
                                    }
                                  },
                                  child: const Text("Save Boundary",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasBoundary = _classData['boundary'] != null;

    return Scaffold(
      backgroundColor: AppTheme.kDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_className,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17)),
            Text("Code: $_classCode",
                style: const TextStyle(
                    fontSize: 11, color: Colors.white60)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            tooltip: "Rename Class",
            onPressed: _showRenameDialog,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: "Delete Class",
            onPressed: _deleteClass,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: AppTheme.bottomSheet,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(35)),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
                  children: [
                    // ── Quick stats ────────────────────────────────────────
                    _QuickStats(
                      classId: widget.classId,
                      studentCount: _studentIds.length,
                      hasBoundary: hasBoundary,
                    ),

                    const SizedBox(height: 20),

                    // ── Boundary section ───────────────────────────────────
                    _SectionCard(
                      icon: Icons.my_location,
                      title: "Class Boundary",
                      trailing: hasBoundary
                          ? _chip("Set", Colors.green)
                          : _chip("Not Set", Colors.orange),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasBoundary) ...[
                            Text(
                              "Lat: ${(_classData['boundary']['lat'] as num).toStringAsFixed(5)},  "
                              "Lng: ${(_classData['boundary']['lng'] as num).toStringAsFixed(5)}",
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                  fontFamily: 'Courier'),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Radius: ${(_classData['boundary']['radiusMeters'] as num).toStringAsFixed(0)} m",
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12),
                            ),
                            const SizedBox(height: 12),
                          ],
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: Icon(hasBoundary
                                  ? Icons.edit_location_alt
                                  : Icons.add_location_alt),
                              label: Text(hasBoundary
                                  ? "Edit Boundary"
                                  : "Set Boundary"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.kGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(10)),
                              ),
                              onPressed: _openBoundaryPicker,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Enrolled students (with delete/suspend) ────────────
                    _EnrolledStudentsManagement(
                      classId: widget.classId,
                      studentIds: _studentIds,
                      onStudentRemoved: (removedId) {
                        setState(() => _classData['studentIds'] =
                            _studentIds
                                .where((id) => id != removedId)
                                .toList());
                      },
                    ),

                    const SizedBox(height: 16),

                    // ── Attendance stats per period (read view) ────────────
                    _L1PeriodsStatsSection(
                      classId: widget.classId,
                      totalStudents: _studentIds.length,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.bold)),
    );
  }
}

// ── Quick stats bar ────────────────────────────────────────────────────────────
class _QuickStats extends StatelessWidget {
  final String classId;
  final int studentCount;
  final bool hasBoundary;
  const _QuickStats(
      {required this.classId,
      required this.studentCount,
      required this.hasBoundary});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance_logs')
          .where('classId', isEqualTo: classId)
          .snapshots(),
      builder: (context, snap) {
        final logCount = snap.hasData
            ? snap.data!.docs
                .where((d) =>
                    (d.data() as Map)['isHiddenFromAdmin'] != true)
                .length
            : 0;
        return Row(
          children: [
            _StatTile("$studentCount", "Students", Colors.blue,
                Icons.people_alt_outlined),
            const SizedBox(width: 12),
            _StatTile("$logCount", "Total Logs", AppTheme.kGreen,
                Icons.receipt_long_outlined),
            const SizedBox(width: 12),
            _StatTile(hasBoundary ? "Set" : "None", "Boundary",
                hasBoundary ? Colors.green : Colors.orange,
                Icons.my_location),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;
  const _StatTile(this.value, this.label, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(height: 7),
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 10, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}

// ── Section card wrapper ───────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;
  const _SectionCard(
      {required this.icon,
      required this.title,
      required this.child,
      this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 3))
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.kGreen, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              if (trailing != null) ...[
                const Spacer(),
                trailing!
              ],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// =============================================================================
// _EnrolledStudentsManagement — student list with suspend / delete / unenroll
// =============================================================================
class _EnrolledStudentsManagement extends StatelessWidget {
  final String classId;
  final List<String> studentIds;
  final void Function(String removedId) onStudentRemoved;

  const _EnrolledStudentsManagement({
    required this.classId,
    required this.studentIds,
    required this.onStudentRemoved,
  });

  void _showStudentOptions(
      BuildContext context, String studentId, String studentName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: studentId)
            .limit(1)
            .snapshots(),
        builder: (context, snap) {
          final doc =
              snap.hasData && snap.data!.docs.isNotEmpty
                  ? snap.data!.docs.first
                  : null;
          final data = doc?.data() as Map<String, dynamic>?;
          final bool isActive = data?['status'] != 'disabled';

          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const CircleAvatar(
                        radius: 22,
                        backgroundColor: Color(0xFFF1F4F2),
                        child: Icon(Icons.person,
                            color: AppTheme.kGreen, size: 22)),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(studentName,
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        Text("ID: $studentId",
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade500)),
                      ],
                    ),
                    const Spacer(),
                    if (data != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isActive ? "ACTIVE" : "SUSPENDED",
                          style: TextStyle(
                              color: isActive
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 10),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),

                // Suspend / reactivate (only if user doc exists)
                if (doc != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                        isActive
                            ? Icons.block
                            : Icons.check_circle_outline,
                        color:
                            isActive ? Colors.orange : Colors.green),
                    title: Text(
                        isActive
                            ? "Suspend Student"
                            : "Reactivate Student",
                        style: const TextStyle(
                            fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      isActive
                          ? "Student won't be able to log in."
                          : "Restore student login access.",
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                    onTap: () async {
                      await doc.reference.update({
                        'status': isActive ? 'disabled' : 'active'
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),

                // Remove from class
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_remove_outlined,
                      color: Colors.orange),
                  title: const Text("Remove from Class",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text(
                    "Unenrols the student. Account is kept.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: ctx,
                      builder: (c) => AlertDialog(
                        title: const Text("Remove Student?"),
                        content: Text(
                            "Remove $studentName from this class?"),
                        actions: [
                          TextButton(
                              onPressed: () =>
                                  Navigator.pop(c, false),
                              child: const Text("Cancel")),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(c, true),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white),
                            child: const Text("Remove"),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await FirebaseFirestore.instance
                          .collection('classes')
                          .doc(classId)
                          .update({
                        'studentIds':
                            FieldValue.arrayRemove([studentId])
                      });
                      onStudentRemoved(studentId);
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                  },
                ),

                const Divider(),

                // Delete account
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text("Delete Student Account",
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.red)),
                  subtitle: Text(
                      "Permanently removes the user record.",
                      style: TextStyle(
                          fontSize: 12, color: Colors.red.shade300)),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: ctx,
                      builder: (c) => AlertDialog(
                        title: const Text("Delete Student?"),
                        content: Text(
                            "Permanently delete $studentName's account? This cannot be undone."),
                        actions: [
                          TextButton(
                              onPressed: () =>
                                  Navigator.pop(c, false),
                              child: const Text("Cancel")),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(c, true),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white),
                            child: const Text("Delete"),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && doc != null) {
                      // Remove from class first
                      await FirebaseFirestore.instance
                          .collection('classes')
                          .doc(classId)
                          .update({
                        'studentIds':
                            FieldValue.arrayRemove([studentId])
                      });
                      // Delete user doc
                      await doc.reference.delete();
                      onStudentRemoved(studentId);
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 3))
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppTheme.kGreen,
          collapsedIconColor: Colors.grey,
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          title: Row(
            children: [
              const Icon(Icons.people_alt_outlined,
                  color: AppTheme.kGreen, size: 20),
              const SizedBox(width: 8),
              Text("Enrolled Students",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text("${studentIds.length}",
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          children: [
            if (studentIds.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Text("No students enrolled yet.",
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where(FieldPath.documentId,
                          whereIn: studentIds)
                      .snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.kGreen));
                    }
                    return Container(
                      constraints: const BoxConstraints(maxHeight: 340),
                      child: ListView(
                        shrinkWrap: true,
                        children: snap.data!.docs.map((s) {
                          final sd =
                              s.data() as Map<String, dynamic>;
                          final bool isActive =
                              sd['status'] != 'disabled';
                          final String name =
                              sd['name'] ?? 'Unknown';
                          final String uid =
                              sd['username'] ?? s.id;

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: isActive
                                  ? const Color(0xFFF1F4F2)
                                  : Colors.red.shade50,
                              child: Icon(Icons.person,
                                  color: isActive
                                      ? AppTheme.kGreen
                                      : Colors.red,
                                  size: 16),
                            ),
                            title: Text(name,
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            subtitle: Row(
                              children: [
                                Text("ID: $uid",
                                    style: const TextStyle(
                                        fontSize: 11)),
                                const SizedBox(width: 8),
                                if (!isActive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius:
                                          BorderRadius.circular(4),
                                    ),
                                    child: const Text("SUSPENDED",
                                        style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.red,
                                            fontWeight:
                                                FontWeight.bold)),
                                  ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                  Icons.more_vert_rounded,
                                  color: Colors.grey,
                                  size: 20),
                              onPressed: () => _showStudentOptions(
                                  context, uid, name),
                            ),
                            onTap: () =>
                                _showStudentOptions(context, uid, name),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _L1PeriodsStatsSection — read-only attendance summary per period for L1
// =============================================================================
class _L1PeriodsStatsSection extends StatelessWidget {
  final String classId;
  final int totalStudents;
  const _L1PeriodsStatsSection(
      {required this.classId, required this.totalStudents});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.bar_chart_rounded,
      title: "Attendance per Period",
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .doc(classId)
            .collection('periods')
            .orderBy('startTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.kGreen));
          }
          if (snapshot.data!.docs.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                  child: Text("No periods added yet.",
                      style: TextStyle(color: Colors.grey))),
            );
          }

          // Group by date
          final Map<String, List<DocumentSnapshot>> grouped = {};
          for (final doc in snapshot.data!.docs) {
            final dateStr =
                (doc.data() as Map<String, dynamic>)['date'] as String? ??
                    'Unknown';
            grouped.putIfAbsent(dateStr, () => []).add(doc);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: grouped.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Text(
                      _prettyDate(entry.key),
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade500,
                          fontSize: 12),
                    ),
                  ),
                  ...entry.value.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _PeriodStatRow(
                      periodId: doc.id,
                      periodData: data,
                      totalStudents: totalStudents,
                    );
                  }),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }

  String _prettyDate(String raw) {
    try {
      return DateFormat('EEEE, MMM dd yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }
}

class _PeriodStatRow extends StatelessWidget {
  final String periodId;
  final Map<String, dynamic> periodData;
  final int totalStudents;
  const _PeriodStatRow(
      {required this.periodId,
      required this.periodData,
      required this.totalStudents});

  @override
  Widget build(BuildContext context) {
    final startTS = periodData['startTime'] as Timestamp?;
    final endTS = periodData['endTime'] as Timestamp?;
    final String timeStr = (startTS != null && endTS != null)
        ? "${DateFormat('hh:mm a').format(startTS.toDate())} – ${DateFormat('hh:mm a').format(endTS.toDate())}"
        : "Unknown Time";

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance_logs')
          .where('periodId', isEqualTo: periodId)
          .snapshots(),
      builder: (context, snap) {
        int present = 0, late = 0, absent = 0, pending = 0;
        if (snap.hasData) {
          for (final doc in snap.data!.docs) {
            final d = doc.data() as Map<String, dynamic>;
            switch ((d['adminVerifiedStatus'] as String? ?? 'Pending')
                .trim()) {
              case 'Present':
                present++;
                break;
              case 'Late':
                late++;
                break;
              case 'Absent':
                absent++;
                break;
              default:
                pending++;
            }
          }
        }
        final reported = present + late + absent + pending;
        final notReported =
            totalStudents > reported ? totalStudents - reported : 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.kSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time_filled,
                      color: AppTheme.kGreen, size: 14),
                  const SizedBox(width: 6),
                  Text(timeStr,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.kGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "$reported / $totalStudents",
                      style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppTheme.kGreen,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _Pill("Present", present, Colors.green),
                  const SizedBox(width: 6),
                  _Pill("Late", late, Colors.orange),
                  const SizedBox(width: 6),
                  _Pill("Absent", absent, Colors.red),
                  const SizedBox(width: 6),
                  _Pill("Not In", notReported, Colors.grey),
                ],
              ),
              if (totalStudents > 0) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: SizedBox(
                    height: 5,
                    child: Row(
                      children: [
                        if (present > 0)
                          Flexible(
                              flex: present,
                              child:
                                  Container(color: Colors.green)),
                        if (late > 0)
                          Flexible(
                              flex: late,
                              child:
                                  Container(color: Colors.orange)),
                        if (absent > 0)
                          Flexible(
                              flex: absent,
                              child: Container(color: Colors.red)),
                        if (notReported > 0)
                          Flexible(
                              flex: notReported,
                              child: Container(
                                  color: Colors.grey.shade300)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _Pill(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        children: [
          Text("$count",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: color)),
          Text(label,
              style: TextStyle(
                  fontSize: 9,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}