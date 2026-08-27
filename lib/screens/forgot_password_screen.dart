import 'package:flutter/material.dart';
import '../db/auth_helper.dart';
import '../db/database_helper.dart';
import '../services/email_service.dart';
import '../theme/app_colors.dart';

/// Lets a user recover their password. They identify their account by
/// username or registered email; if it matches, their original password
/// is decrypted and emailed straight to the email address already on file
/// for that account (never to an address typed in on this screen — that
/// would let anyone recover someone else's password just by knowing their
/// username).
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _identifierController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;

  Future<void> _handleRecover() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    final identifier = _identifierController.text.trim();
    if (identifier.isEmpty) {
      setState(() => _errorMessage = 'Enter your username or email');
      return;
    }

    setState(() => _isSubmitting = true);

    final user =
        await DatabaseHelper.instance.getUserByUsernameOrEmail(identifier);

    if (user == null) {
      setState(() {
        _errorMessage = 'No account found with that username or email';
        _isSubmitting = false;
      });
      return;
    }

    if (user.email.trim().isEmpty) {
      setState(() {
        _errorMessage =
            'This account has no email on file, so a password cannot be sent. '
            'Please contact an administrator.';
        _isSubmitting = false;
      });
      return;
    }

    final originalPassword =
        AuthHelper.decryptPassword(user.passwordEncrypted);

    final error = await EmailService.sendPasswordRecoveryEmail(
      recipientEmail: user.email,
      username: user.username,
      password: originalPassword,
    );

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      if (error != null) {
        _errorMessage = error;
      } else {
        _successMessage =
            'Your password has been emailed to ${_maskEmail(user.email)}.';
      }
    });
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2 || parts[0].isEmpty) return email;
    final name = parts[0];
    final visible = name.length <= 2 ? name : name.substring(0, 2);
    return '$visible***@${parts[1]}';
  }

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F7),
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: AppColors.auth,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.auth,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_reset,
                      color: Colors.white, size: 38),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Recover Password',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.auth,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Enter your username or registered email. We\'ll verify '
                  'your identity and email your password to the address on '
                  'file for your account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _identifierController,
                  decoration: InputDecoration(
                    labelText: 'Username or Email',
                    prefixIcon: const Icon(Icons.person_search_outlined),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _handleRecover(),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (_successMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _successMessage!,
                    style: const TextStyle(color: Colors.green, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 22),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleRecover,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.auth,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Send Password to My Email',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back to Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
