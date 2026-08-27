import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

/// Sends the "Forgot Password" recovery email automatically, straight from
/// the app, using SMTP (no backend server needed).
///
/// ⚠️ IMPORTANT — you must configure a real sender account before this
/// works:
///   1. Use a Gmail address (or any SMTP provider) that you control.
///   2. If using Gmail: enable 2-Step Verification on that account, then
///      create an "App Password" at https://myaccount.google.com/apppasswords
///      — do NOT use your normal Gmail login password here, Gmail blocks
///      that for security.
///   3. Put that email + App Password below.
///
/// Because these credentials travel inside the compiled app, anyone who
/// decompiles the APK could extract them. That's an inherent limitation of
/// sending email directly from a mobile app with no backend — fine for a
/// student/demo project, but for a real production app the recommended
/// approach is to send email from a small backend server instead, so
/// credentials never ship inside the app.
class EmailService {
  // TODO: replace with your own sender email + Gmail App Password.
  static const String _senderEmail = 'YOUR_EMAIL@gmail.com';
  static const String _senderAppPassword = 'YOUR_16_CHAR_APP_PASSWORD';
  static const String _senderName = 'Student Pharma Centre';

  /// Sends [password] to [recipientEmail]. Returns null on success, or an
  /// error message to show the user on failure.
  static Future<String?> sendPasswordRecoveryEmail({
    required String recipientEmail,
    required String username,
    required String password,
  }) async {
    if (_senderEmail == 'YOUR_EMAIL@gmail.com') {
      return 'Email sending isn\'t configured yet. Open lib/services/email_service.dart '
          'and fill in a real sender email + Gmail App Password.';
    }

    final smtpServer = gmail(_senderEmail, _senderAppPassword);

    final message = Message()
      ..from = Address(_senderEmail, _senderName)
      ..recipients.add(recipientEmail)
      ..subject = 'Your Student Pharma Centre password'
      ..text = 'Hi $username,\n\n'
          'As requested, here is your account password:\n\n'
          '$password\n\n'
          'For your security, please do not share this email with anyone.\n\n'
          '— Student Pharma Centre';

    try {
      await send(message, smtpServer);
      return null;
    } on MailerException catch (e) {
      return 'Could not send email: ${e.message}';
    } catch (e) {
      return 'Could not send email. Please check your internet connection and try again.';
    }
  }
}
