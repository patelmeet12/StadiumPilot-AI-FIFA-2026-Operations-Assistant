import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  final SharedPreferences _prefs;

  // Static key for local layout encryption
  static const int _cryptoMask = 0xA5;

  SecureStorageService(this._prefs);

  String _obfuscate(String input) {
    final bytes = utf8.encode(input);
    final processed = bytes.map((b) => b ^ _cryptoMask).toList();
    return base64.encode(processed);
  }

  String _deobfuscate(String input) {
    try {
      final bytes = base64.decode(input);
      final processed = bytes.map((b) => b ^ _cryptoMask).toList();
      return utf8.decode(processed);
    } catch (_) {
      return '';
    }
  }

  Future<void> write(String key, String value) async {
    final encrypted = _obfuscate(value);
    await _prefs.setString('sec_$key', encrypted);
  }

  String? read(String key) {
    final cipher = _prefs.getString('sec_$key');
    if (cipher == null) return null;
    final decrypted = _deobfuscate(cipher);
    return decrypted.isEmpty ? null : decrypted;
  }

  Future<void> delete(String key) async {
    await _prefs.remove('sec_$key');
  }
}
