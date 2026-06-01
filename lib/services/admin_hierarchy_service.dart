import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'appwrite_service.dart';

/// L1 creates classes and assigns L3 heads + L2 supervisors.
/// L2 sees L3 admins under them; L3 sees assigned classes only.
class AdminHierarchyService {
  static const String databaseId = '69ecebfb0033cf785741';
  static const String usersCollection = 'users';
  static const String classesCollection = 'classes';

  static Future<List<models.Document>> listAdminsByLevel(int level) async {
    final result = await AppwriteService.databases.listDocuments(
      databaseId: databaseId,
      collectionId: usersCollection,
      queries: [
        Query.equal('role', 'admin'),
        Query.equal('level', level),
        Query.limit(100),
      ],
    );
    return result.documents
        .where((d) => d.data['status'] != 'disabled')
        .toList();
  }

  static Future<models.Document?> findUserByUsername(String username) async {
    final result = await AppwriteService.databases.listDocuments(
      databaseId: databaseId,
      collectionId: usersCollection,
      queries: [Query.equal('username', username), Query.limit(1)],
    );
    if (result.documents.isEmpty) return null;
    return result.documents.first;
  }

  static Future<List<models.Document>> listL3UnderSupervisor(
      String supervisorId) async {
    try {
      final result = await AppwriteService.databases.listDocuments(
        databaseId: databaseId,
        collectionId: usersCollection,
        queries: [
          Query.equal('role', 'admin'),
          Query.equal('level', 3),
          Query.equal('supervisedByL2', supervisorId),
          Query.limit(100),
        ],
      );
      return result.documents
          .where((d) => d.data['status'] != 'disabled')
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<models.Document>> fetchClassesForAdmin({
    required String adminId,
    required int adminLevel,
  }) async {
    if (adminLevel == 1) {
      final result = await AppwriteService.databases.listDocuments(
        databaseId: databaseId,
        collectionId: classesCollection,
        queries: [Query.equal('createdBy', adminId), Query.limit(100)],
      );
      return result.documents;
    }

    if (adminLevel == 3) {
      try {
        final byHead = await AppwriteService.databases.listDocuments(
          databaseId: databaseId,
          collectionId: classesCollection,
          queries: [Query.equal('headAdminId', adminId), Query.limit(100)],
        );
        if (byHead.documents.isNotEmpty) return byHead.documents;
      } catch (_) {}

      final user = await findUserByUsername(adminId);
      final managed = user?.data['managedClasses'] as List<dynamic>? ?? [];
      final ids = managed.map((e) => e.toString()).where((s) => s.isNotEmpty);
      final List<models.Document> docs = [];
      for (final id in ids) {
        try {
          final doc = await AppwriteService.databases.getDocument(
            databaseId: databaseId,
            collectionId: classesCollection,
            documentId: id,
          );
          docs.add(doc);
        } catch (_) {}
      }
      return docs;
    }

    if (adminLevel == 2) {
      final seen = <String>{};
      final List<models.Document> docs = [];

      try {
        final bySupervisor = await AppwriteService.databases.listDocuments(
          databaseId: databaseId,
          collectionId: classesCollection,
          queries: [Query.equal('supervisorId', adminId), Query.limit(100)],
        );
        for (final d in bySupervisor.documents) {
          if (seen.add(d.$id)) docs.add(d);
        }
      } catch (_) {}

      final l3s = await listL3UnderSupervisor(adminId);
      for (final l3 in l3s) {
        final headId = l3.data['username'] as String? ?? '';
        if (headId.isEmpty) continue;
        try {
          final byHead = await AppwriteService.databases.listDocuments(
            databaseId: databaseId,
            collectionId: classesCollection,
            queries: [Query.equal('headAdminId', headId), Query.limit(100)],
          );
          for (final d in byHead.documents) {
            if (seen.add(d.$id)) docs.add(d);
          }
        } catch (_) {}
      }
      return docs;
    }

    return [];
  }

  static Future<void> linkClassStaff({
    required String classDocId,
    required String l1AdminId,
    String? headAdminId,
    String? headAdminName,
    String? supervisorId,
    String? supervisorName,
  }) async {
    if (headAdminId == null &&
        headAdminName == null &&
        supervisorId == null) {
      return;
    }

    if (headAdminId != null && headAdminId.isNotEmpty) {
      final l3 = await findUserByUsername(headAdminId);
      if (l3 != null) {
        final managed = List<String>.from(
          (l3.data['managedClasses'] as List<dynamic>? ?? [])
              .map((e) => e.toString()),
        );
        if (!managed.contains(classDocId)) managed.add(classDocId);
        await AppwriteService.databases.updateDocument(
          databaseId: databaseId,
          collectionId: usersCollection,
          documentId: l3.$id,
          data: {
            'managedClasses': managed,
            'reportsToL1': l1AdminId,
            if (supervisorId != null && supervisorId.isNotEmpty)
              'supervisedByL2': supervisorId,
            if (supervisorName != null && supervisorName.isNotEmpty)
              'supervisedByL2Name': supervisorName,
          },
        );
      }
    }

    if (supervisorId != null && supervisorId.isNotEmpty) {
      final l2 = await findUserByUsername(supervisorId);
      if (l2 != null) {
        await AppwriteService.databases.updateDocument(
          databaseId: databaseId,
          collectionId: usersCollection,
          documentId: l2.$id,
          data: {'reportsToL1': l1AdminId},
        );
      }
    }
  }

  static String displayName(models.Document doc) {
    final data = doc.data;
    return data['name'] as String? ??
        data['username'] as String? ??
        'Admin';
  }

  static String? username(models.Document doc) =>
      doc.data['username'] as String?;
}
