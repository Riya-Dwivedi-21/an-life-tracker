import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CredentialStorageService {
  static const _storage = FlutterSecureStorage();
  static const _keyEmail = 'saved_email';
  static const _keyPassword = 'saved_password';
  static const _keyTimestamp = 'saved_timestamp';
  static const _daysToRemember = 30;

  // Save credentials
  static Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: _keyEmail, value: email);
    await _storage.write(key: _keyPassword, value: password);
    await _storage.write(key: _keyTimestamp, value: DateTime.now().toIso8601String());
  }

  // Get saved credentials if not expired
  static Future<Map<String, String>?> getSavedCredentials() async {
    try {
      final email = await _storage.read(key: _keyEmail);
      final password = await _storage.read(key: _keyPassword);
      final timestampStr = await _storage.read(key: _keyTimestamp);

      if (email == null || password == null || timestampStr == null) {
        return null;
      }

      final savedTime = DateTime.parse(timestampStr);
      final daysPassed = DateTime.now().difference(savedTime).inDays;

      if (daysPassed > _daysToRemember) {
        // Expired - clear credentials
        await clearCredentials();
        return null;
      }

      return {'email': email, 'password': password};
    } catch (e) {
      return null;
    }
  }

  // Clear saved credentials
  static Future<void> clearCredentials() async {
    await _storage.delete(key: _keyEmail);
    await _storage.delete(key: _keyPassword);
    await _storage.delete(key: _keyTimestamp);
  }
}
