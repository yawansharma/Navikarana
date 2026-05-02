import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dean_login.dart';
import 'admin_home_page.dart';
import 'app_theme.dart';
import 'services/appwrite_service.dart';
import 'leave_management_page.dart';

// ---------------------------------------------------------------------------
// THEME CONSTANTS FOR DEAN
// ---------------------------------------------------------------------------
const Color kDeanDark = Color(0xFF10121C);
const Color kDeanPanel = Color(0xFF1A1C29);
const Color kDeanGold = Color(0xFFD4AF37);
const Color kDeanBg = Color(0xFFF8F9FB);

class DeanHomePage extends StatefulWidget {
  const DeanHomePage({super.key});

  @override
  State<DeanHomePage> createState() => _DeanHomePageState();
}

class _DeanHomePageState extends State<DeanHomePage> {
  int _currentIndex = 0;
  int _prevIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDeanDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _tabTitle(),
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: kDeanGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border:
                    Border.all(color: kDeanGold.withValues(alpha: 0.3)),
              ),
              child: Text(
                "EXECUTIVE CONTROL",
                style: GoogleFonts.poppins(
                    color: kDeanGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 0.5),
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
                  color: kDeanBg,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(35)),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(35)),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 320),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            final isNewTab =
                                child.key == ValueKey(_currentIndex);
                            final isMovingRight =
                                _currentIndex > _prevIndex;
                            final beginOffset = isNewTab
                                ? Offset(isMovingRight ? 1.0 : -1.0, 0.0)
                                : Offset(
                                    isMovingRight ? -1.0 : 1.0, 0.0);
                            return SlideTransition(
                              position: Tween<Offset>(
                                      begin: beginOffset,
                                      end: Offset.zero)
                                  .animate(animation),
                              child: child,
                            );
                          },
                          child: _buildCurrentTab(),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, -5))
                        ],
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 16, right: 16, top: 8, bottom: 16),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceAround,
                            children: [
                              _navItem(0, Icons.people_alt, "Personnel"),
                              _navItem(1, Icons.settings, "More"),
                            ],
                          ),
                        ),
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
        return "Admin Personnel";
      case 1:
        return "System Settings";
      default:
        return "Dashboard";
    }
  }

  Widget _buildCurrentTab() {
    switch (_currentIndex) {
      case 0:
        return _buildPersonnelTab(key: const ValueKey(0));
      case 1:
        return _buildMoreTab(key: const ValueKey(1));
      default:
        return const SizedBox(key: ValueKey(0));
    }
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (_currentIndex != index) {
          setState(() {
            _prevIndex = _currentIndex;
            _currentIndex = index;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? kDeanDark : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? kDeanGold : Colors.grey.shade400,
                size: 22),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      color: kDeanGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildPersonnelTab({required Key key}) {
    return _AdminListTab(key: key);
  }

  Widget _buildMoreTab({required Key key}) {
    return ListView(
      key: key,
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 16),
        Center(
          child: CircleAvatar(
            radius: 42,
            backgroundColor: kDeanPanel,
            child: const Icon(Icons.shield, color: kDeanGold, size: 40),
          ),
        ),
        const SizedBox(height: 12),
        const Center(
            child: Text("Dean / Super Admin",
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold))),
        Center(
            child: Text("Executive Level",
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 13))),
        const SizedBox(height: 32),
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          color: Colors.white,
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child:
                  const Icon(Icons.cloud_sync, color: Colors.blue, size: 20),
            ),
            title: const Text("Migrate Legacy Data",
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text("Link unowned classes to Super Admin",
                style: TextStyle(fontSize: 12)),
            trailing:
                const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () => _runDataMigration(context),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          color: Colors.white,
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.logout_rounded,
                  color: Colors.red, size: 20),
            ),
            title: const Text("Logout Securely",
                style: TextStyle(fontWeight: FontWeight.w600)),
            trailing:
                const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const DeanLoginPage()),
                (route) => false,
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _runDataMigration(BuildContext ctx) async {
    final statusNotifier = ValueNotifier("Scanning database...");
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (c) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: ValueListenableBuilder<String>(
            valueListenable: statusNotifier,
            builder: (_, value, __) => Row(
              children: [
                const CircularProgressIndicator(color: kDeanGold),
                const SizedBox(width: 20),
                Expanded(child: Text(value)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      int updatedClasses = 0;
      int updatedLogs = 0;

      statusNotifier.value = "Migrating classes...";
      final classDocs = await AppwriteService.databases.listDocuments(
        databaseId: '69ecebfb0033cf785741',
        collectionId: 'classes',
        queries: [Query.limit(5000)],
      );
      for (final doc in classDocs.documents) {
        final data = doc.data;
        if (data['createdBy'] == null ||
            data['createdBy'].toString().isEmpty) {
          await AppwriteService.databases.updateDocument(
            databaseId: '69ecebfb0033cf785741',
            collectionId: 'classes',
            documentId: doc.$id,
            data: {'createdBy': 'dean_master', 'adminName': 'Master Dean'},
          );
          updatedClasses++;
        }
      }

      statusNotifier.value = "Migrating attendance logs...";
      final logDocs = await AppwriteService.databases.listDocuments(
        databaseId: '69ecebfb0033cf785741',
        collectionId: 'attendance_logs',
        queries: [Query.limit(5000)],
      );
      for (final doc in logDocs.documents) {
        final data = doc.data;
        if (data['adminId'] == null ||
            data['adminId'].toString().isEmpty) {
          await AppwriteService.databases.updateDocument(
            databaseId: '69ecebfb0033cf785741',
            collectionId: 'attendance_logs',
            documentId: doc.$id,
            data: {'adminId': 'dean_master'},
          );
          updatedLogs++;
        }
      }

      if (mounted) Navigator.pop(ctx);
      if (mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text(
                'Migration Complete: $updatedClasses classes, $updatedLogs logs assigned to Master.')));
      }
    } catch (e) {
      if (mounted) Navigator.pop(ctx);
      if (mounted) {
        ScaffoldMessenger.of(ctx)
            .showSnackBar(SnackBar(content: Text('Migration Error: $e')));
      }
    }
  }
}

// ---------------------------------------------------------------------------
// ADMIN LIST COMPONENT
// ---------------------------------------------------------------------------
class _AdminListTab extends StatefulWidget {
  const _AdminListTab({super.key});

  @override
  State<_AdminListTab> createState() => _AdminListTabState();
}

class _AdminListTabState extends State<_AdminListTab> {
  List<models.Document> _admins = [];
  bool _loading = true;
  RealtimeSubscription? _sub;

  final List<String> departments = [
    'CSE', 'ISE', 'ECE', 'ME', 'CE', 'Basic Sciences', 'General Admin'
  ];

  @override
  void initState() {
    super.initState();
    _fetchAdmins();
    _sub = AppwriteService.realtime
        .subscribe(['databases.main_db.collections.users.documents']);
    _sub!.stream.listen((_) {
      if (mounted) _fetchAdmins();
    });
  }

  @override
  void dispose() {
    _sub?.close();
    super.dispose();
  }

  Future<void> _fetchAdmins() async {
    try {
      final result = await AppwriteService.databases.listDocuments(
        databaseId: '69ecebfb0033cf785741',
        collectionId: 'users',
        queries: [Query.equal('role', 'admin')],
      );
      if (mounted) {
        setState(() {
          _admins = result.documents;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAddAdminSheet() {
    final usernameCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String selectedDept = departments.first;
    int selectedLevel = 1;
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text("Onboard New Admin",
                  style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("Create a standard admin account for a department.",
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 24),
              TextField(
                controller: usernameCtrl,
                decoration: InputDecoration(
                    labelText: 'Admin Username (ID)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passCtrl,
                decoration: InputDecoration(
                    labelText: 'Initial Password',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedLevel,
                decoration: InputDecoration(
                    labelText: 'Admin Level',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
                items: const [
                  DropdownMenuItem(value: 1, child: Text("Level 1")),
                  DropdownMenuItem(value: 2, child: Text("Level 2")),
                  DropdownMenuItem(value: 3, child: Text("Level 3")),
                ],
                onChanged: (v) =>
                    setSheetState(() => selectedLevel = v!),
              ),
              const SizedBox(height: 30),
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

                          try {
                            // Check if username already exists
                            final exists = await AppwriteService.databases
                                .listDocuments(
                              databaseId: '69ecebfb0033cf785741',
                              collectionId: 'users',
                              queries: [
                                Query.equal('username',
                                    usernameCtrl.text.trim())
                              ],
                            );
                            if (exists.documents.isNotEmpty) {
                              setSheetState(() => saving = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Username already exists.')));
                              }
                              return;
                            }

                            await AppwriteService.databases.createDocument(
                              databaseId: '69ecebfb0033cf785741',
                              collectionId: 'users',
                              documentId: ID.unique(),
                              data: {
                                'username': usernameCtrl.text.trim(),
                                'name': nameCtrl.text.trim().isNotEmpty
                                    ? nameCtrl.text.trim()
                                    : usernameCtrl.text.trim(),
                                'password': passCtrl.text.trim(),
                                'role': 'admin',
                                'status': 'active',
                                'department': selectedDept,
                                'level': selectedLevel,
                                'managedClasses': [],
                                'createdAt':
                                    DateTime.now().toIso8601String(),
                              },
                            );

                            if (!mounted) return;
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Admin ${usernameCtrl.text.trim()} onboarded successfully.')));
                          } catch (e) {
                            setSheetState(() => saving = false);
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                      content: Text('Error: $e')));
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kDeanDark,
                      foregroundColor: kDeanGold,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: kDeanGold, strokeWidth: 2))
                      : const Text("Create Admin Profile",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
          ),
        ),
      ),
    );
  }

  void _showAdminDetails(models.Document doc) {
    final data = doc.data;
    final bool isActive = data['status'] != 'disabled';
    final passCtrl =
        TextEditingController(text: data['password'] as String? ?? '');

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
              Row(
                children: [
                  const CircleAvatar(
                      radius: 24,
                      backgroundColor: kDeanDark,
                      child: Icon(Icons.person, color: kDeanGold)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            data['name'] as String? ??
                                data['username'] as String? ??
                                'Admin',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        Text(
                            "${data['department'] ?? 'No Dept'} â€¢ ${data['username']}",
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
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(isActive ? "ACTIVE" : "DISABLED",
                        style: TextStyle(
                            color:
                                isActive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 10)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text("Admin Controls",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminHomePage(
                            adminName: data['name'] as String? ??
                                data['username'] as String? ??
                                '',
                            adminId: data['username'] as String? ?? '',
                            isDean: true,
                            adminLevel: 1, // Dean always gets Level 1
                          ),
                        ));
                  },
                  icon: const Icon(Icons.remove_red_eye),
                  label: const Text("Enter Supervision Mode",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kDeanGold,
                    foregroundColor: kDeanDark,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passCtrl,
                decoration: InputDecoration(
                  labelText: 'Override Password',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.save, color: kDeanDark),
                    onPressed: () async {
                      if (passCtrl.text.trim().isEmpty) return;
                      await AppwriteService.databases.updateDocument(
                        databaseId: '69ecebfb0033cf785741',
                        collectionId: 'users',
                        documentId: doc.$id,
                        data: {'password': passCtrl.text.trim()},
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                              content: Text('Password overridden.')));
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                        fontSize: 12,
                        color: Colors.grey.shade500)),
                onTap: () async {
                  await AppwriteService.databases.updateDocument(
                    databaseId: '69ecebfb0033cf785741',
                    collectionId: 'users',
                    documentId: doc.$id,
                    data: {
                      'status': isActive ? 'disabled' : 'active'
                    },
                  );
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  _fetchAdmins();
                },
              ),
              const Divider(),
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
                        fontSize: 12,
                        color: Colors.red.shade300)),
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
                            onPressed: () =>
                                Navigator.pop(c, true),
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.red),
                            child: const Text("Delete")),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await AppwriteService.databases.deleteDocument(
                      databaseId: '69ecebfb0033cf785741',
                      collectionId: 'users',
                      documentId: doc.$id,
                    );
                    if (!mounted) return;
                    Navigator.pop(ctx);
                    _fetchAdmins();
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
        backgroundColor: kDeanDark,
        foregroundColor: kDeanGold,
        onPressed: _showAddAdminSheet,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text("Onboard Admin",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: kDeanDark))
          : _admins.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_outlined,
                          size: 60, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text("No Administrators Found",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  itemCount: _admins.length,
                  itemBuilder: (context, index) {
                    final doc = _admins[index];
                    final data = doc.data;
                    final isActive = data['status'] != 'disabled';
                    final String? lastLoginStr =
                        data['lastLogin'] as String?;

                    return Card(
                      margin:
                          const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                              color: Colors.grey.shade200)),
                      elevation: 0,
                      color: Colors.white,
                      child: InkWell(
                        onTap: () => _showAdminDetails(doc),
                        borderRadius:
                            BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: isActive
                                    ? kDeanGold
                                        .withValues(alpha: 0.1)
                                    : Colors.red
                                        .withValues(alpha: 0.1),
                                child: Icon(
                                    Icons
                                        .admin_panel_settings,
                                    color: isActive
                                        ? kDeanGold
                                        : Colors.red),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        data['name'] as String? ??
                                            data['username']
                                                as String? ??
                                            '',
                                        style: const TextStyle(
                                            fontWeight:
                                                FontWeight.bold,
                                            fontSize: 16)),
                                    const SizedBox(height: 2),
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
                                              data['department']
                                                      as String? ??
                                                  'No Dept',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors
                                                      .grey.shade700,
                                                  fontWeight:
                                                      FontWeight
                                                          .bold)),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                            "â€¢  ${data['username']}",
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors
                                                    .grey.shade500)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      lastLoginStr != null
                                          ? "Last login: ${DateFormat('MMM dd, hh:mm a').format(DateTime.parse(lastLoginStr))}"
                                          : "Never logged in",
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade400),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right,
                                  color: Colors.grey.shade300),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
