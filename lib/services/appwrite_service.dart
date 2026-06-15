import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:crypto/crypto.dart';

class AppwriteService {
  static const String endpoint = 'https://sgp.cloud.appwrite.io/v1';
  static const String projectId = '69ecea2600127cefd5b2';

  // ── Centralized IDs ───────────────────────────────────────────────────────
  static const String databaseId = '6a2c10dc000d5e50f314';
  static const String profileBucketId = '6a2c12a500260c940843';
  static const String attendancePhotosBucket = 'attendance_photos';
  static const String communityFilesBucket = 'community_files';

  // ── ML Backend ────────────────────────────────────────────────────────────
  static const String mlBackendBase =
      'https://pasteshub404-navikarana-backend.hf.space';

  static final Client client = Client()
      .setEndpoint(endpoint)
      .setProject(projectId);

  static final Databases databases = Databases(client);
  static final Storage storage = Storage(client);
  static final Realtime realtime = Realtime(client);

  // ── Password Hashing ──────────────────────────────────────────────────────
  /// Hash a plaintext password using SHA-256.
  /// Returns a hex-encoded hash string.
  static String hashPassword(String plaintext) {
    final bytes = utf8.encode(plaintext);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Check if a string looks like it's already a SHA-256 hash
  /// (64 hex characters). Used for dual-mode migration.
  static bool isHashed(String value) {
    return RegExp(r'^[a-f0-9]{64}$').hasMatch(value);
  }

  /// Verify a password against a stored value.
  /// Supports dual-mode: works with both plaintext (legacy) and hashed passwords.
  /// Returns true if the password matches.
  static bool verifyPassword(String inputPlaintext, String storedValue) {
    if (isHashed(storedValue)) {
      // Stored value is already hashed — compare hashes
      return hashPassword(inputPlaintext) == storedValue;
    } else {
      // Stored value is plaintext (legacy) — direct comparison
      return inputPlaintext == storedValue;
    }
  }
}
