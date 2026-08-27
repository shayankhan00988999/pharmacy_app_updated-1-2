import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Small helper to hash passwords before they are stored in the local
/// SQLite database. The one-way [hashPassword]/[verifyPassword] pair is
/// what login actually checks against — a SHA-256 hash can never be
/// reversed back into the original password, which is exactly the point
/// of hashing (it's what keeps passwords safe even if the database is
/// ever leaked or the device is lost).
///
/// The "Forgot Password" feature, however, was specifically asked to email
/// the user their *original* password back rather than issue a reset link.
/// That is only possible if the original password is stored somewhere in a
/// recoverable form, so [encryptPassword]/[decryptPassword] below keep a
/// SEPARATE, reversible copy just for that purpose. This is a deliberate
/// security trade-off:
///   - `passwordHash` (irreversible) is what login verification uses.
///   - `passwordEncrypted` (reversible) exists only so Forgot Password can
///     recover and email the exact original password.
/// Reversible storage is inherently weaker than one-way hashing — anyone
/// who obtains the app's source/database could in principle decrypt it.
/// For a real production app, a reset-link/reset-code flow (which never
/// stores a recoverable password at all) would be the safer choice.
class AuthHelper {
  static const String _salt = 'student_pharma_centre_v1';

  // Key used only for the reversible recovery cipher below. Keeping this
  // separate from the hash salt is good practice even though, in this
  // simple offline app, both live in the source code either way.
  static const String _recoveryKey = 'spc_recovery_key_v1_change_me';

  static String hashPassword(String rawPassword) {
    final bytes = utf8.encode('$_salt::$rawPassword');
    return sha256.convert(bytes).toString();
  }

  static bool verifyPassword(String rawPassword, String storedHash) {
    return hashPassword(rawPassword) == storedHash;
  }

  /// Reversible XOR-stream cipher (then base64-encoded) so the exact
  /// original password can be recovered later for the Forgot Password
  /// email. XOR with a repeating key is simple, fast, and has no external
  /// dependency, but it is NOT strong cryptography — it only exists to
  /// avoid storing the password as plain, readable text in the database.
  static String encryptPassword(String rawPassword) {
    final keyBytes = utf8.encode(_recoveryKey);
    final dataBytes = utf8.encode(rawPassword);
    final out = List<int>.generate(
      dataBytes.length,
      (i) => dataBytes[i] ^ keyBytes[i % keyBytes.length],
    );
    return base64.encode(out);
  }

  /// Reverses [encryptPassword] to recover the original password.
  static String decryptPassword(String encrypted) {
    final keyBytes = utf8.encode(_recoveryKey);
    final dataBytes = base64.decode(encrypted);
    final out = List<int>.generate(
      dataBytes.length,
      (i) => dataBytes[i] ^ keyBytes[i % keyBytes.length],
    );
    return utf8.decode(out);
  }
}
