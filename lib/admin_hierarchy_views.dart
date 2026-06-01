import 'package:flutter/material.dart';
import 'package:appwrite/models.dart' as models;
import 'package:google_fonts/google_fonts.dart';
import 'services/admin_hierarchy_service.dart';

/// L1 dashboard: organization summary (classes, L2 supervisors, L3 heads).
class L1OrganizationPanel extends StatelessWidget {
  final List<models.Document> classes;
  final String l1AdminId;

  const L1OrganizationPanel({
    super.key,
    required this.classes,
    required this.l1AdminId,
  });

  @override
  Widget build(BuildContext context) {
    if (classes.isEmpty) return const SizedBox.shrink();

    final bySupervisor = <String, List<models.Document>>{};
    final unassigned = <models.Document>[];

    for (final c in classes) {
      final sup = c.data['supervisorId'] as String? ?? '';
      if (sup.isEmpty) {
        unassigned.add(c);
      } else {
        bySupervisor.putIfAbsent(sup, () => []).add(c);
      }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6A8A73).withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6A8A73).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_tree_outlined,
                    color: Color(0xFF6A8A73), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your organization',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3436),
                  ),
                ),
              ),
              _statChip('${classes.length} classes'),
            ],
          ),
          const SizedBox(height: 16),
          if (bySupervisor.isNotEmpty) ...[
            Text('By Level 2 supervisor',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            ...bySupervisor.entries.map((e) => _supervisorGroup(e.key, e.value)),
          ],
          if (unassigned.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Unassigned supervision',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            ...unassigned.map(_classRow),
          ],
        ],
      ),
    );
  }

  Widget _supervisorGroup(String supervisorId, List<models.Document> group) {
    final supName = group.first.data['supervisorName'] as String? ?? supervisorId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.supervisor_account_outlined,
                  size: 16, color: Color(0xFF4E7A8A)),
              const SizedBox(width: 6),
              Text(supName,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(width: 6),
              Text('($supervisorId)',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
          const SizedBox(height: 6),
          ...group.map(_classRow),
        ],
      ),
    );
  }

  Widget _classRow(models.Document c) {
    final d = c.data;
    final head = d['headAdminName'] as String? ?? d['headAdminId'] as String?;
    return Container(
      margin: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.class_, size: 18, color: Color(0xFF6A8A73)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d['className'] as String? ?? 'Class',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                if (head != null && head.toString().isNotEmpty)
                  Text('Head: $head',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Text(
            '${(d['studentIds'] as List?)?.length ?? 0} members',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF6A8A73).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6A8A73))),
    );
  }
}

/// L2 dashboard: L3 team under this supervisor + reporting L1.
class L2TeamTab extends StatefulWidget {
  final String adminId;
  final String adminName;

  const L2TeamTab({
    super.key,
    required this.adminId,
    required this.adminName,
  });

  @override
  State<L2TeamTab> createState() => _L2TeamTabState();
}

class _L2TeamTabState extends State<L2TeamTab> {
  bool _loading = true;
  List<models.Document> _l3Admins = [];
  models.Document? _myProfile;
  String? _reportsToL1Name;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final l3s = await AdminHierarchyService.listL3UnderSupervisor(widget.adminId);
    final me = await AdminHierarchyService.findUserByUsername(widget.adminId);
    String? l1Name;
    if (me != null) {
      final l1Id = me.data['reportsToL1'] as String?;
      if (l1Id != null && l1Id.isNotEmpty) {
        final l1 = await AdminHierarchyService.findUserByUsername(l1Id);
        l1Name = l1 != null
            ? AdminHierarchyService.displayName(l1)
            : l1Id;
      }
    }
    if (mounted) {
      setState(() {
        _l3Admins = l3s;
        _myProfile = me;
        _reportsToL1Name = l1Name;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF4E7A8A)));
    }

    return RefreshIndicator(
      color: const Color(0xFF4E7A8A),
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
        children: [
          _reportingCard(),
          const SizedBox(height: 20),
          Text('Level 3 admins under you',
              style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3436))),
          const SizedBox(height: 12),
          if (_l3Admins.isEmpty)
            _emptyTeam()
          else
            ..._l3Admins.map(_l3Card),
        ],
      ),
    );
  }

  Widget _reportingCard() {
    final l1Id = _myProfile?.data['reportsToL1'] as String?;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4E7A8A).withValues(alpha: 0.9),
            const Color(0xFF4E7A8A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('You report to',
              style: GoogleFonts.poppins(
                  color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            _reportsToL1Name ?? (l1Id?.isNotEmpty == true ? l1Id! : 'Not assigned yet'),
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          if (l1Id != null && l1Id.isNotEmpty)
            Text('Level 1 • $l1Id',
                style: GoogleFonts.poppins(
                    color: Colors.white60, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _emptyTeam() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.groups_outlined,
              size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No Level 3 admins assigned under you yet.\n'
            'A Level 1 admin assigns you when creating a class.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _l3Card(models.Document doc) {
    final data = doc.data;
    final name = AdminHierarchyService.displayName(doc);
    final username = data['username'] as String? ?? '';
    final dept = data['department'] as String? ?? '—';
    final managed = (data['managedClasses'] as List?)?.length ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF7A6A8A).withValues(alpha: 0.15),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: Color(0xFF7A6A8A),
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('$username • $dept',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Text('$managed class(es) assigned',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
            ),
            const Icon(Icons.person_outline,
                color: Color(0xFF7A6A8A), size: 28),
          ],
        ),
      ),
    );
  }
}

/// Assignment chips on class cards (head L3, supervisor L2).
class ClassAssignmentChips extends StatelessWidget {
  final Map<String, dynamic> classData;

  const ClassAssignmentChips({super.key, required this.classData});

  @override
  Widget build(BuildContext context) {
    final head = classData['headAdminName'] as String? ??
        classData['headAdminId'] as String?;
    final sup = classData['supervisorName'] as String? ??
        classData['supervisorId'] as String?;

    if ((head == null || head.toString().isEmpty) &&
        (sup == null || sup.toString().isEmpty)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          if (head != null && head.toString().isNotEmpty)
            _chip(Icons.person_pin_outlined, 'Head: $head', const Color(0xFF7A6A8A)),
          if (sup != null && sup.toString().isNotEmpty)
            _chip(Icons.supervisor_account, 'L2: $sup', const Color(0xFF4E7A8A)),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }
}
