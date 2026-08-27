import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/medicine.dart';
import '../theme/app_colors.dart';
import 'add_medicine_screen.dart';
import 'bulk_upload_screen.dart';
import 'medicine_reference_list_screen.dart';

class MedicineListScreen extends StatefulWidget {
  const MedicineListScreen({super.key});

  @override
  State<MedicineListScreen> createState() => _MedicineListScreenState();
}

class _MedicineListScreenState extends State<MedicineListScreen> {
  List<Medicine> _medicines = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = _query.isEmpty
        ? await DatabaseHelper.instance.getAllMedicines()
        : await DatabaseHelper.instance.searchMedicines(_query);
    if (!mounted) return;
    setState(() => _medicines = list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicines'),
        backgroundColor: AppColors.medicines,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: 'Browse & manage medicine reference list',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const MedicineReferenceListScreen()),
              );
              _load();
            },
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Bulk upload from Excel/CSV',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BulkUploadScreen()),
              );
              _load();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search medicine...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
              onChanged: (v) {
                _query = v;
                _load();
              },
            ),
          ),
          Expanded(
            child: _medicines.isEmpty
                ? const Center(child: Text('No medicines found.'))
                : ListView.builder(
                    itemCount: _medicines.length,
                    itemBuilder: (context, index) {
                      final m = _medicines[index];
                      Color badgeColor = Colors.green;
                      String badgeText = 'OK';
                      if (m.isExpired) {
                        badgeColor = Colors.red;
                        badgeText = 'EXPIRED';
                      } else if (m.isLowStock) {
                        badgeColor = Colors.orange;
                        badgeText = 'LOW STOCK';
                      } else if (m.isExpiringSoon) {
                        badgeColor = Colors.amber;
                        badgeText = 'EXPIRING';
                      }
                      return Card(
                        margin:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text(m.name,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              '${m.category} • Qty: ${m.quantity} ${m.unit} • Rs. ${m.salePrice}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: badgeColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(badgeText,
                                    style: TextStyle(
                                        color: badgeColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      AddMedicineScreen(medicine: m)),
                            );
                            _load();
                          },
                          onLongPress: () => _confirmDelete(m),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.medicines,
        foregroundColor: Colors.white,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddMedicineScreen()),
          );
          _load();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(Medicine m) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Medicine'),
        content: Text('Delete "${m.name}" from inventory?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.deleteMedicine(m.id!);
              if (mounted) Navigator.pop(context);
              _load();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
