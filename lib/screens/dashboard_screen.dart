import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/user.dart';
import '../theme/app_colors.dart';
import 'medicine_info_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  final AppUser currentUser;
  final VoidCallback onLogout;

  const DashboardScreen(
      {super.key, required this.currentUser, required this.onLogout});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int totalMedicines = 0;
  int lowStockCount = 0;
  int expiringCount = 0;
  int expiredCount = 0;
  int totalPatients = 0;
  double todaysSales = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final db = DatabaseHelper.instance;
    final medicines = await db.getAllMedicines();
    final lowStock = await db.getLowStockMedicines();
    final expiring = await db.getExpiringSoonMedicines();
    final expired = await db.getExpiredMedicines();
    final patients = await db.getAllPatients();
    final sales = await db.getTodaysSalesTotal();

    if (!mounted) return;
    setState(() {
      totalMedicines = medicines.length;
      lowStockCount = lowStock.length;
      expiringCount = expiring.length;
      expiredCount = expired.length;
      totalPatients = patients.length;
      todaysSales = sales;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Pharma Centre'),
        backgroundColor: AppColors.dashboard,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.health_and_safety_outlined),
            tooltip: 'Medicine & Patient Lookup',
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MedicineInfoScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => SettingsScreen(
                        currentUser: widget.currentUser,
                        onLogout: widget.onLogout)),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MedicineInfoScreen()));
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.dashboardGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.health_and_safety, color: Colors.white, size: 32),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Medicine & Patient Lookup',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(height: 3),
                          Text(
                              'Look up any medicine\'s usage, dosage & risks — and pull up the patient record at the same time.',
                              style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: AppColors.dashboard,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Today's Sales",
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 6),
                    Text(
                      'Rs. ${todaysSales.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _statCard('Total Medicines', totalMedicines.toString(),
                    Icons.medication, Colors.blue),
                _statCard('Total Patients', totalPatients.toString(),
                    Icons.people, Colors.purple),
                _statCard('Low Stock', lowStockCount.toString(),
                    Icons.warning_amber, Colors.orange),
                _statCard('Expiring Soon', expiringCount.toString(),
                    Icons.schedule, Colors.amber),
                _statCard('Expired', expiredCount.toString(),
                    Icons.dangerous, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const Spacer(),
            Text(value,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
