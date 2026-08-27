import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/sale.dart';
import '../theme/app_colors.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  List<Sale> _sales = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sales = await DatabaseHelper.instance.getAllSales();
    if (!mounted) return;
    setState(() => _sales = sales);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales History'),
        backgroundColor: AppColors.sell,
        foregroundColor: Colors.white,
      ),
      body: _sales.isEmpty
          ? const Center(child: Text('No sales recorded yet.'))
          : ListView.builder(
              itemCount: _sales.length,
              itemBuilder: (context, index) {
                final s = _sales[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ExpansionTile(
                    title: Text(
                        '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}-${s.date.day.toString().padLeft(2, '0')}  •  Rs. ${s.totalAmount.toStringAsFixed(0)}'),
                    subtitle: Text(
                        '${s.patientName ?? "Walk-in"} • ${s.paymentType}'),
                    children: s.items
                        .map((i) => ListTile(
                              dense: true,
                              title: Text(i.medicineName),
                              trailing: Text(
                                  'x${i.quantity} = Rs. ${i.subtotal.toStringAsFixed(0)}'),
                            ))
                        .toList(),
                  ),
                );
              },
            ),
    );
  }
}
