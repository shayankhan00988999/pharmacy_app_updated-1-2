import 'package:flutter/material.dart';
import '../models/user.dart';
import '../theme/app_colors.dart';
import 'dashboard_screen.dart';
import 'medicine_list_screen.dart';
import 'patient_list_screen.dart';
import 'sale_screen.dart';
import 'alerts_screen.dart';

class MainNavigation extends StatefulWidget {
  final AppUser currentUser;

  /// Called when the user logs out (either manually from Settings, or
  /// automatically once the auto-logout timer elapses). Handled by
  /// [AuthGate], which swaps back to the login screen.
  final VoidCallback onLogout;

  const MainNavigation({
    super.key,
    required this.currentUser,
    required this.onLogout,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  static const _tabColors = [
    AppColors.dashboard,
    AppColors.medicines,
    AppColors.sell,
    AppColors.patients,
    AppColors.alerts,
  ];

  late final List<Widget> _screens = [
    DashboardScreen(currentUser: widget.currentUser, onLogout: widget.onLogout),
    const MedicineListScreen(),
    const SaleScreen(),
    const PatientListScreen(),
    const AlertsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _tabColors[_currentIndex],
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.medication), label: 'Medicines'),
          BottomNavigationBarItem(
              icon: Icon(Icons.point_of_sale), label: 'Sell'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people), label: 'Patients'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications_active), label: 'Alerts'),
        ],
      ),
    );
  }
}
