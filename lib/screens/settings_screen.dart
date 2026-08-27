import 'package:flutter/material.dart';
import '../models/user.dart';
import '../theme/app_colors.dart';

/// Shows the signed-in staff member's profile and a logout button.
///
/// Logout can happen two ways:
///  1. Manually — tap "Log out" here, confirm, and [onLogout] fires
///     immediately.
///  2. Automatically — if the app is closed/backgrounded for longer than
///     SessionManager.autoLogoutAfter, AuthGate calls [onLogout] on its
///     own the next time the app is opened/resumed. Both paths go through
///     the same [onLogout] callback so there is exactly one place
///     (AuthGate) that owns "who is logged in".
class SettingsScreen extends StatelessWidget {
  final AppUser currentUser;
  final VoidCallback onLogout;

  const SettingsScreen(
      {super.key, required this.currentUser, required this.onLogout});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to use the app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Pop back out of Settings/Dashboard first, then hand control back
      // to AuthGate, which swaps to the login screen.
      Navigator.of(context).popUntil((route) => route.isFirst);
      onLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial =
        currentUser.fullName.isNotEmpty ? currentUser.fullName[0] : currentUser.username[0];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.settings,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.settings,
                    child: Text(
                      initial.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    currentUser.fullName.isNotEmpty
                        ? currentUser.fullName
                        : currentUser.username,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('@${currentUser.username}',
                      style: const TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Username'),
                  subtitle: Text(currentUser.username),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Full Name'),
                  subtitle: Text(currentUser.fullName.isNotEmpty
                      ? currentUser.fullName
                      : 'Not set'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email'),
                  subtitle: Text(
                      currentUser.email.isNotEmpty ? currentUser.email : 'Not set'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.event_outlined),
                  title: const Text('Account Created'),
                  subtitle: Text(
                      '${currentUser.createdAt.year}-${currentUser.createdAt.month.toString().padLeft(2, '0')}-${currentUser.createdAt.day.toString().padLeft(2, '0')}'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Log out', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
