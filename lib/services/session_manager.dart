import 'package:shared_preferences/shared_preferences.dart';

/// Handles the "auto logout after the app has been closed/backgrounded for
/// a while" feature.
///
/// How it works:
/// - While a user is logged in, their user id is saved to disk.
/// - Every time the app goes to the background (closed, switched away
///   from, screen locked, etc.) we record the timestamp.
/// - Every time the app comes back to the foreground (or is freshly
///   launched, e.g. after being fully killed by the OS), we compare "now"
///   to that saved timestamp:
///     - less than [autoLogoutAfter] has passed  -> stay logged in
///     - [autoLogoutAfter] or more has passed     -> session is cleared,
///       user is sent back to the login screen
///
/// The manual "Log out" button in Settings still works immediately and
/// independently of this timer — it just calls [clearSession] directly.
class SessionManager {
  SessionManager._();

  /// How long the app can be backgrounded/closed before the account is
  /// automatically logged out. Change this to `Duration(seconds: 30)` or
  /// `Duration(minutes: 1)` etc. as needed.
  static const Duration autoLogoutAfter = Duration(seconds: 30);

  static const _keyUserId = 'session_user_id';
  static const _keyPausedAt = 'session_paused_at_millis';

  static Future<void> saveSession(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, userId);
    await prefs.remove(_keyPausedAt);
  }

  static Future<int?> getSavedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyPausedAt);
  }

  /// Call when the app goes to the background while a user is logged in.
  static Future<void> markPausedNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPausedAt, DateTime.now().millisecondsSinceEpoch);
  }

  /// Call when the app returns to the foreground (or on a fresh launch).
  /// Returns true if enough time has passed that the session should be
  /// logged out.
  static Future<bool> hasAutoLogoutElapsed() async {
    final prefs = await SharedPreferences.getInstance();
    final pausedAtMillis = prefs.getInt(_keyPausedAt);
    if (pausedAtMillis == null) return false;
    final pausedAt = DateTime.fromMillisecondsSinceEpoch(pausedAtMillis);
    return DateTime.now().difference(pausedAt) >= autoLogoutAfter;
  }

  /// Clears the "paused at" marker without touching the logged-in user —
  /// call this once the app is back in the foreground and we've decided
  /// the session is still valid.
  static Future<void> clearPausedMarker() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPausedAt);
  }
}
