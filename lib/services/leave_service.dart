import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'appwrite_service.dart';

class LeaveService {
  static const String databaseId = '69ecebfb0033cf785741';
  static const String collectionId = 'leave_requests';

  static Future<models.Document> submitRequest({
    required String userId,
    required String userName,
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    required int approverLevel,
  }) async {
    return await AppwriteService.databases.createDocument(
      databaseId: databaseId,
      collectionId: collectionId,
      documentId: ID.unique(),
      data: {
        'userId': userId,
        'userName': userName,
        'leaveType': leaveType,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'reason': reason,
        'status': 'pending',
        'approverLevel': approverLevel,
        'createdAt': DateTime.now().toIso8601String(),
      },
    );
  }

  static Future<models.DocumentList> getPendingRequests(int level) async {
    return await AppwriteService.databases.listDocuments(
      databaseId: databaseId,
      collectionId: collectionId,
      queries: [
        Query.equal('approverLevel', level),
        Query.equal('status', 'pending'),
        Query.orderDesc('createdAt'),
      ],
    );
  }

  static Future<models.DocumentList> getMyRequests(String userId) async {
    return await AppwriteService.databases.listDocuments(
      databaseId: databaseId,
      collectionId: collectionId,
      queries: [
        Query.equal('userId', userId),
        Query.orderDesc('createdAt'),
      ],
    );
  }

  static Future<void> updateStatus(String documentId, String status, String actionBy, {String? comment}) async {
    await AppwriteService.databases.updateDocument(
      databaseId: databaseId,
      collectionId: collectionId,
      documentId: documentId,
      data: {
        'status': status,
        'actionBy': actionBy,
        'actionTime': DateTime.now().toIso8601String(),
        if (comment != null) 'actionComment': comment,
      },
    );
  }
}
