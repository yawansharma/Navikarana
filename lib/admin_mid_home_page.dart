import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'admin_home_page.dart';
import 'admin_l1_supervision_page.dart';
import 'admin_l2_supervision_page.dart';
import 'admin_level_select.dart';
import 'app_theme.dart';

// =============================================================================
// AdminMidHomePage — used by Admin Level 1 and Admin Level 2.
// • Level 1 manages Level 2 admins (role: admin_l2)
// • Level 2 manages Level 3 admins (role: admin_l3)
// Each can also delete lower-level admins they created.
// =============================================================================
class AdminMidHomePage extends StatefulWidget {
  final String adminName;
  final String adminId;
  final int adminLevel; // 1 or 2

  const AdminMidHomePage({
    super.key,
    required this.adminName,
    required this.adminId,
    required this.adminLevel,
  });

  @override
  State<AdminMidHomePage> createState() => _AdminMidHomePageState();
}

class _AdminMidHomePageState extends State<AdminMidHomePage> {
  int _currentIndex = 0;
  int _prevIndex = 0;

  /// The role string of the level this admin manages.
  String get _managedRole {
    if (widget.adminLevel == 1) return 'admin_l2';
    return 'admin_l3'; // level 2 manages level 3
  }

  int get _managedLevel => widget.adminLevel + 1;

  String get _levelLabel => "Level ${widget.adminLevel}";
  String get _managedLevelLabel => "Level $_managedLevel";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _tabTitle(),
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: AppTheme.kGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.kGreen.withValues(alpha: 0.3)),
              ),
              child: Text(
                "ADMIN $_levelLabel: ${widget.adminName.toUpperCase()}",
                style: GoogleFonts.poppins(color: AppTheme.kGreen, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: RisingSheet(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F9FB),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 320),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            final isNewTab = child.key == ValueKey(_currentIndex);
                            final isMovingRight = _currentIndex > _prevIndex;
                            Offset beginOffset;
                            if (isNewTab) {
                              beginOffset = Offset(isMovingRight ? 1.0 : -1.0, 0.0);
                            } else {
                              beginOffset = Offset(isMovingRight ? -1.0 : 1.0, 0.0);
                            }
                            return SlideTransition(
                              position: Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(animation),
                              child: child,
                            );
                          },
                          child: _buildCurrentTab(),
                        ),
                      ),
                    ),
                    // Navigation Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2)),
                        ],
                      ),
                      child: BottomNavigationBar(
                        currentIndex: _currentIndex,
                        onTap: (i) => setState(() {
                          _prevIndex = _currentIndex;
                          _currentIndex = i;
                        }),
                        backgroundColor: Colors.white,
                        selectedItemColor: AppTheme.kGreen,
                        unselectedItemColor: Colors.grey.shade400,
                        showSelectedLabels: true,
                        showUnselectedLabels: false,
                        elevation: 0,
                        type: BottomNavigationBarType.fixed,
                        items: [
                          BottomNavigationBarItem(icon: const Icon(Icons.people_alt_outlined, size: 22), label: widget.adminLevel == 1 ? "Dashboard" : "$_managedLevelLabel Admins"),
                          const BottomNavigationBarItem(icon: Icon(Icons.more_horiz_rounded, size: 22), label: "Settings"),
                        ],
                      ),
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

  String _tabTitle() {
    switch (_currentIndex) {
      case 0:
        return widget.adminLevel == 1 ? "Dashboard" : "$_managedLevelLabel Personnel";
      case 1: return "Settings";
      default: return "";
    }
  }

  Widget _buildCurrentTab() {
    switch (_currentIndex) {
      case 0:
        // Level 1 sees the supervision hub; Level 2 sees the L3 admin list as before
        if (widget.adminLevel == 1) {
          return _L1HubTab(
            key: const ValueKey(0),
            adminId: widget.adminId,
            adminName: widget.adminName,
          );
        }
        return _AdminSubList(key: const ValueKey(0), managedRole: _managedRole, managedLevel: _managedLevel, parentAdminId: widget.adminId);
      case 1: return _buildSettingsTab(key: const ValueKey(1));
      default: return const SizedBox(key: ValueKey(0));
    }
  }

  Widget _buildSettingsTab({required Key key}) {
    return ListView(
      key: key,
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 16),
        Center(
          child: CircleAvatar(
            radius: 42,
            backgroundColor: const Color(0xFFF1F4F2),
            child: Text(
              widget.adminName.isNotEmpty ? widget.adminName[0].toUpperCase() : "A",
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: AppTheme.kGreen),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(child: Text(widget.adminName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        Center(child: Text("Administrator $_levelLabel", style: TextStyle(color: Colors.grey.shade500, fontSize: 13))),
        const SizedBox(height: 32),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          color: Colors.white,
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
            ),
            title: const Text("Logout", style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AdminLevelSelectPage()),
                (route) => false,
              );
            },
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// _L1HubTab — thin wrapper so the hub can be keyed inside AnimatedSwitcher
// =============================================================================
class _L1HubTab extends StatelessWidget {
  final String adminId;
  final String adminName;

  const _L1HubTab({
    super.key,
    required this.adminId,
    required this.adminName,
  });

  @override
  Widget build(BuildContext context) {
    return AdminL1SupervisionHub(
      l1AdminId: adminId,
      l1AdminName: adminName,
    );
  }
}

// =============================================================================
// _AdminSubList — Lists admins of the managed role, allows CRUD + supervision
// =============================================================================
class _AdminSubList extends StatefulWidget {
  final String managedRole;
  final int managedLevel;
  final String parentAdminId;
  const _AdminSubList({super.key, required this.managedRole, required this.managedLevel, required this.parentAdminId});

  @override
  State<_AdminSubList> createState() => _AdminSubListState();
}

class _AdminSubListState extends State<_AdminSubList> {
  final List<String> departments = [
    'CSE', 'ISE', 'ECE', 'ME', 'CE', 'Basic Sciences', 'General Admin'
  ];

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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Onboard Level ${widget.managedLevel} Admin", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("Create a Level ${widget.managedLevel} admin account for a department.", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 24),
              TextField(
                controller: usernameCtrl,
                decoration: InputDecoration(labelText: 'Admin Username (ID)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: 'Full Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passCtrl,
                decoration: InputDecoration(labelText: 'Initial Password', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedDept,
                decoration: InputDecoration(labelText: 'Department', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                items: departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (v) => setSheetState(() => selectedDept = v!),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: saving ? null : () async {
                    if (usernameCtrl.text.trim().isEmpty || passCtrl.text.trim().isEmpty) return;
                    setSheetState(() => saving = true);

                    final exists = await FirebaseFirestore.instance.collection('users').where('username', isEqualTo: usernameCtrl.text.trim()).get();
                    if (exists.docs.isNotEmpty) {
                      setSheetState(() => saving = false);
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Username already exists.')));
                      return;
                    }

                    await FirebaseFirestore.instance.collection('users').add({
                      'username': usernameCtrl.text.trim(),
                      'name': nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : usernameCtrl.text.trim(),
                      'password': passCtrl.text.trim(),
                      'role': widget.managedRole,
                      'status': 'active',
                      'department': selectedDept,
                      'createdBy': widget.parentAdminId,
                      'managedClasses': [],
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    if (!mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Level ${widget.managedLevel} Admin ${usernameCtrl.text.trim()} onboarded successfully.')));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.kGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text("Create L${widget.managedLevel} Admin", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  void _showAdminDetails(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final bool isActive = data['status'] != 'disabled';
    final passCtrl = TextEditingController(text: data['password']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(radius: 24, backgroundColor: const Color(0xFFF1F4F2), child: const Icon(Icons.person, color: AppTheme.kGreen)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['name'] ?? data['username'] ?? 'Admin', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("${data['department'] ?? 'No Dept'} • ${data['username']}", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isActive ? "ACTIVE" : "DISABLED",
                      style: TextStyle(color: isActive ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Supervision Mode (only for L2 → read-only stats view of L3's classes) ──
              if (widget.managedLevel == 3) ...[
                const Text("Supervision", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Watch-only access. You can view classes and attendance statistics but cannot make any changes.",
                          style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => AdminL2SupervisionPage(
                          l3AdminName: data['name'] ?? data['username'],
                          l3AdminId: data['username'],
                        ),
                      ));
                    },
                    icon: const Icon(Icons.remove_red_eye),
                    label: const Text("Enter Supervision Mode", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.kGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Reset Password ──
              TextField(
                controller: passCtrl,
                decoration: InputDecoration(
                  labelText: 'Override Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.save, color: AppTheme.kGreen),
                    onPressed: () async {
                      if (passCtrl.text.trim().isEmpty) return;
                      await doc.reference.update({'password': passCtrl.text.trim()});
                      if (!mounted) return;
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Password overridden.')));
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Suspend / Reactivate ──
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(isActive ? Icons.block : Icons.check_circle_outline, color: isActive ? Colors.orange : Colors.green),
                title: Text(isActive ? "Suspend Account" : "Reactivate Account", style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  isActive ? "Admin will not be able to log in." : "Restore full admin access.",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                onTap: () async {
                  await doc.reference.update({'status': isActive ? 'disabled' : 'active'});
                  if (!mounted) return;
                  Navigator.pop(ctx);
                },
              ),

              const Divider(),

              // ── Delete Admin ──
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text("Delete Administrator", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                subtitle: Text("Permanently remove this admin record.", style: TextStyle(fontSize: 12, color: Colors.red.shade300)),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: ctx,
                    builder: (c) => AlertDialog(
                      title: const Text("Confirm Deletion"),
                      content: const Text("This action cannot be undone. Delete this admin?"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancel")),
                        TextButton(onPressed: () => Navigator.pop(c, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text("Delete")),
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
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.kGreen,
        foregroundColor: Colors.white,
        onPressed: _showAddAdminSheet,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text("Onboard L${widget.managedLevel} Admin", style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: widget.managedRole)
            .where('createdBy', isEqualTo: widget.parentAdminId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.kGreen));

          final admins = snapshot.data!.docs;
          if (admins.isEmpty) {
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_outlined, size: 60, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text("No Level ${widget.managedLevel} Admins Found", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                Text("Tap + to onboard one.", style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
              ],
            ));
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            itemCount: admins.length,
            itemBuilder: (context, index) {
              final doc = admins[index];
              final data = doc.data() as Map<String, dynamic>;
              final isActive = data['status'] != 'disabled';
              final Timestamp? lastLogin = data['lastLogin'] as Timestamp?;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
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
                          backgroundColor: isActive ? AppTheme.kGreen.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                          child: Icon(Icons.admin_panel_settings, color: isActive ? AppTheme.kGreen : Colors.red),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['name'] ?? data['username'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                                    child: Text(data['department'] ?? 'No Dept', style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text("• ${data['username']}", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                lastLogin != null ? "Last login: ${DateFormat('MMM dd, hh:mm a').format(lastLogin.toDate())}" : "Never logged in",
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.kGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text("L${widget.managedLevel}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.kGreen)),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right, color: Colors.grey.shade300),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}