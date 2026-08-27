import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/user.dart';
import '../services/session_manager.dart';
import 'login_screen.dart';
import 'main_navigation.dart';

/// The single top-level screen the app starts on. It owns the currently
/// logged-in user (if any) and swaps between [LoginScreen] and
/// [MainNavigation] — including automatically logging the user out once
/// the app has been closed/backgrounded for [SessionManager.autoLogoutAfter].
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  AppUser? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restoreSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Runs on cold start: figures out whether a previous session is still
  /// within the auto-logout window and, if so, silently signs the user
  /// back in instead of showing the login screen again.
  Future<void> _restoreSession() async {
    final expired = await SessionManager.hasAutoLogoutElapsed();
    final savedUserId = await SessionManager.getSavedUserId();

    if (savedUserId != null && !expired) {
      final user = await DatabaseHelper.instance.getUserById(savedUserId);
      await SessionManager.clearPausedMarker();
      if (!mounted) return;
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } else {
      if (savedUserId != null && expired) {
        await SessionManager.clearSession();
      }
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_currentUser == null) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // App is going to the background / closing — start the clock.
      SessionManager.markPausedNow();
    } else if (state == AppLifecycleState.resumed) {
      _checkAutoLogoutOnResume();
    }
  }

  Future<void> _checkAutoLogoutOnResume() async {
    final expired = await SessionManager.hasAutoLogoutElapsed();
    if (expired) {
      await SessionManager.clearSession();
      if (!mounted) return;
      setState(() => _currentUser = null);
    } else {
      await SessionManager.clearPausedMarker();
    }
  }

  void _handleLoginSuccess(AppUser user) async {
    await SessionManager.saveSession(user.id!);
    if (!mounted) return;
    setState(() => _currentUser = user);
  }

  void _handleLogout() async {
    await SessionManager.clearSession();
    if (!mounted) return;
    setState(() => _currentUser = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      return LoginScreen(onLoginSuccess: _handleLoginSuccess);
    }

    return MainNavigation(
      currentUser: _currentUser!,
      onLogout: _handleLogout,
    );
  }
}
