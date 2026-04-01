import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'class_detail_page.dart';
import 'main.dart';

class HomePage extends StatelessWidget {
  final String name;
  final String username;

  const HomePage({
    super.key,
    required this.name,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010), // Charcoal Background
      appBar: AppBar(
        title: const Text("Dashboard"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          tooltip: "Logout",
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false, // Remove all previous routes
            );
          },
        ),
      ),
      body: Column(
        children: [
          // Header Area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Welcome back,",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // White Container
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Pull Handle Visual
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('classes')
                            .where('studentIds', arrayContains: username)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF6A8A73),
                              ),
                            );
                          }

                          final classDocs = snapshot.data!.docs;

                          if (classDocs.isEmpty) {
                            return Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Your Classes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    ElevatedButton.icon(
                                      onPressed: () => _showJoinClassDialog(context),
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const Text("Join"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF6A8A73),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 30),
                                const Text("You haven't joined any classes yet.", style: TextStyle(color: Colors.grey)),
                              ],
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ActivePeriodsBanner(classDocs: classDocs, username: username),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Your Classes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  ElevatedButton.icon(
                                    onPressed: () => _showJoinClassDialog(context),
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text("Join"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6A8A73),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: classDocs.length,
                                  itemBuilder: (context, index) {
                                    final doc = classDocs[index];
                                    final data = doc.data() as Map<String, dynamic>;
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      elevation: 0,
                                      color: const Color(0xFFF9FAFB),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                        leading: const CircleAvatar(
                                          backgroundColor: Color(0xFFF1F4F2),
                                          child: Icon(Icons.class_, color: Color(0xFF6A8A73)),
                                        ),
                                        title: Text(data['className'] ?? "Unknown Class", style: const TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Text("Code: ${data['classCode'] ?? 'Unknown'}"),
                                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ClassDetailPage(
                                                classId: doc.id,
                                                className: data['className'] ?? 'Class',
                                                boundary: data['boundary'] as Map<String, dynamic>?,
                                                username: username,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
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

  void _showJoinClassDialog(BuildContext context) {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Join a Class",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: codeCtrl,
          decoration: const InputDecoration(
            labelText: "Class Code",
            hintText: "Enter the code provided by admin",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A8A73),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final code = codeCtrl.text.trim();
              if (code.isEmpty) return;

              final classQuery = await FirebaseFirestore.instance
                  .collection('classes')
                  .where('classCode', isEqualTo: code)
                  .get();
              if (classQuery.docs.isEmpty) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Invalid class code.")),
                  );
                }
                return;
              }

              final classDoc = classQuery.docs.first;
              await classDoc.reference.update({
                'studentIds': FieldValue.arrayUnion([username]),
              });

              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Joined class successfully!")),
                );
              }
            },
            child: const Text("Join"),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _ActivePeriodsBanner — shows active/upcoming sessions for all classes
// =============================================================================
class _ActivePeriodsBanner extends StatefulWidget {
  final List<QueryDocumentSnapshot> classDocs;
  final String username;

  const _ActivePeriodsBanner({
    required this.classDocs,
    required this.username,
  });

  @override
  State<_ActivePeriodsBanner> createState() => _ActivePeriodsBannerState();
}

class _ActivePeriodsBannerState extends State<_ActivePeriodsBanner> {
  final Map<String, List<Map<String, dynamic>>> _periodsMap = {};
  final List<StreamSubscription> _subs = [];

  @override
  void initState() {
    super.initState();
    _setupSubscriptions();
  }

  @override
  void didUpdateWidget(covariant _ActivePeriodsBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.classDocs.length != widget.classDocs.length) {
      _setupSubscriptions();
    }
  }

  void _setupSubscriptions() {
    for (var sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
    _periodsMap.clear();

    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    for (var classDoc in widget.classDocs) {
      final classId = classDoc.id;
      final classData = classDoc.data() as Map<String, dynamic>;
      final className = classData['className'] ?? 'Unknown Class';
      final boundary = classData['boundary'];

      final sub = FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('periods')
          .where('date', isEqualTo: todayStr)
          .snapshots()
          .listen((snap) {
        if (!mounted) return;
        List<Map<String, dynamic>> periods = [];
        for (var doc in snap.docs) {
          final data = doc.data() as Map<String, dynamic>;
          periods.add({
            'id': doc.id,
            'classId': classId,
            'className': className,
            'boundary': boundary,
            ...data,
          });
        }
        setState(() {
          _periodsMap[classId] = periods;
        });
      });
      _subs.add(sub);
    }
  }

  @override
  void dispose() {
    for (var sub in _subs) {
      sub.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> allPeriods = [];
    _periodsMap.values.forEach((list) => allPeriods.addAll(list));

    if (allPeriods.isEmpty) {
      return const SizedBox.shrink(); // No periods today
    }

    final now = DateTime.now();

    // Sort periods by start time
    allPeriods.sort((a, b) {
      final aTs = a['startTime'] as Timestamp?;
      final bTs = b['startTime'] as Timestamp?;
      if (aTs == null) return 1;
      if (bTs == null) return -1;
      return aTs.compareTo(bTs);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Today's Classes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: Text("${allPeriods.length} Sessions", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: allPeriods.length,
            clipBehavior: Clip.none,
            itemBuilder: (context, index) {
              final period = allPeriods[index];
              final startTs = period['startTime'] as Timestamp?;
              final endTs = period['endTime'] as Timestamp?;
              
              if (startTs == null || endTs == null) return const SizedBox.shrink();

              final realStart = startTs.toDate();
              final realEnd = endTs.toDate();

              final reportStart = realStart.subtract(const Duration(minutes: 10));
              final reportEnd = realEnd.add(const Duration(minutes: 10));

              bool isUpcoming = now.isBefore(reportStart);
              bool isPast = now.isAfter(reportEnd);
              bool isActive = !isUpcoming && !isPast;

              Color accentColor = isActive ? Colors.green : (isUpcoming ? Colors.orange : Colors.grey);
              String statusText = isActive ? "Active Now" : (isUpcoming ? "Upcoming" : "Ended");

              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(isActive ? Icons.sensors : Icons.access_time_filled, color: accentColor, size: 16),
                        const SizedBox(width: 6),
                        Text(statusText, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(period['className'] ?? "Unknown Class", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text("${DateFormat('hh:mm a').format(realStart)} - ${DateFormat('hh:mm a').format(realEnd)}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    const Spacer(),
                    if (isActive)
                      SizedBox(
                        width: double.infinity,
                        height: 28,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ClassDetailPage(
                                  classId: period['classId'],
                                  className: period['className'],
                                  boundary: period['boundary'],
                                  username: widget.username,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          child: const Text("Open to Report", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      )
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
