import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/medicine.dart';
import '../theme/app_colors.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<Medicine> lowStock = [];
  List<Medicine> expiring = [];
  List<Medicine> expired = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = DatabaseHelper.instance;
    final l = await db.getLowStockMedicines();
    final e = await db.getExpiringSoonMedicines();
    final ex = await db.getExpiredMedicines();
    if (!mounted) return;
    setState(() {
      lowStock = l;
      expiring = e;
      expired = ex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Alerts'),
          backgroundColor: AppColors.alerts,
          foregroundColor: Colors.white,
          bottom: TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Low Stock (${lowStock.length})'),
              Tab(text: 'Expiring (${expiring.length})'),
              Tab(text: 'Expired (${expired.length})'),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          child: TabBarView(
            children: [
              _list(lowStock, Colors.orange, 'No low stock items.'),
              _list(expiring, Colors.amber, 'Nothing expiring soon.'),
              _list(expired, Colors.red, 'No expired medicines.'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _list(List<Medicine> items, Color color, String emptyText) {
    if (items.isEmpty) {
      return Center(child: Text(emptyText));
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final m = items[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: Icon(Icons.circle, color: color, size: 14),
            title: Text(m.name),
            subtitle: Text(
                'Qty: ${m.quantity} ${m.unit} • Expiry: ${m.expiryDate.year}-${m.expiryDate.month.toString().padLeft(2, '0')}-${m.expiryDate.day.toString().padLeft(2, '0')}'),
          ),
        );
      },
    );
  }
}
