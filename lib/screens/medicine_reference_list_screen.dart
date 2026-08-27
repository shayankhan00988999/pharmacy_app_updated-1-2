import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart' as xls;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../data/medicine_reference.dart';
import '../db/database_helper.dart';
import '../models/medicine.dart';
import '../theme/app_colors.dart';
import 'add_medicine_screen.dart';

/// Lets the user browse the full built-in drug reference list (not just
/// search one at a time like the Medicine & Patient Lookup screen), add
/// any entry straight into their store's stock, and export the list (or
/// just the currently filtered/searched subset) to an Excel sheet for
/// easier handling outside the app.
class MedicineReferenceListScreen extends StatefulWidget {
  const MedicineReferenceListScreen({super.key});

  @override
  State<MedicineReferenceListScreen> createState() =>
      _MedicineReferenceListScreenState();
}

class _MedicineReferenceListScreenState
    extends State<MedicineReferenceListScreen> {
  String _query = '';
  bool _isExporting = false;

  List<DrugInfo> get _filtered {
    if (_query.trim().isEmpty) return kDrugReferenceDatabase;
    final q = _query.trim().toLowerCase();
    return kDrugReferenceDatabase
        .where((d) =>
            d.brandName.toLowerCase().contains(q) ||
            d.genericName.toLowerCase().contains(q) ||
            d.category.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _addToStock(DrugInfo d) async {
    // Insert immediately so the medicine is genuinely in stock right away
    // (as requested), then open it in Edit mode so the pharmacist can set
    // the real quantity, price, batch number, and expiry date.
    final newId = await DatabaseHelper.instance.insertMedicine(
      Medicine(
        name: d.brandName,
        genericName: d.genericName,
        category: d.category,
        batchNo: '',
        purchasePrice: 0,
        salePrice: 0,
        quantity: 0,
        unit: 'strip',
        expiryDate: DateTime.now().add(const Duration(days: 365)),
        supplier: '',
        usage: d.usage,
        dosage: d.dosage,
        overdoseInfo: d.overdoseInfo,
        precautions: d.precautions,
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${d.brandName} added to stock. Set its quantity & price.'),
        backgroundColor: AppColors.reference,
      ),
    );

    final inserted = await DatabaseHelper.instance.getMedicineById(newId);
    if (inserted == null || !mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMedicineScreen(medicine: inserted),
      ),
    );
  }

  Future<void> _exportToSheet() async {
    setState(() => _isExporting = true);
    try {
      final workbook = xls.Excel.createExcel();
      final sheetName = workbook.getDefaultSheet()!;
      final sheet = workbook[sheetName];

      const headers = [
        'Brand Name',
        'Generic Name',
        'Category',
        'Dosage Form',
        'Strength',
        'Usage',
        'Dosage',
        'Overdose Info',
        'Precautions',
      ];
      sheet.appendRow(headers.map((h) => xls.TextCellValue(h)).toList());

      for (final d in _filtered) {
        sheet.appendRow([
          xls.TextCellValue(d.brandName),
          xls.TextCellValue(d.genericName),
          xls.TextCellValue(d.category),
          xls.TextCellValue(d.dosageForm),
          xls.TextCellValue(d.strength),
          xls.TextCellValue(d.usage),
          xls.TextCellValue(d.dosage),
          xls.TextCellValue(d.overdoseInfo),
          xls.TextCellValue(d.precautions),
        ]);
      }

      final bytes = workbook.encode();
      if (bytes == null) throw Exception('Could not build the sheet');

      final fileBytes = Uint8List.fromList(bytes);

      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save medicine reference sheet',
        fileName: 'medicine_reference.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        bytes: fileBytes,
      );

      // On platforms where saveFile already writes the bytes (e.g. using
      // the `bytes` parameter above), savePath being non-null means the
      // system dialog completed. On platforms that only return a path,
      // write the file ourselves.
      if (savePath != null && !(await File(savePath).exists())) {
        await File(savePath).writeAsBytes(fileBytes);
      }

      if (!mounted) return;
      if (savePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sheet saved (${_filtered.length} medicines).'),
            backgroundColor: AppColors.reference,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not export the sheet. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Reference List'),
        backgroundColor: AppColors.reference,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.ios_share),
            tooltip: 'Export to Excel sheet',
            onPressed: _isExporting ? null : _exportToSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search brand, generic name or category...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('${list.length} medicines',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('No medicines found.'))
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final d = list[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text(d.brandName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              '${d.genericName} • ${d.category} • ${d.strength}'),
                          isThreeLine: false,
                          trailing: TextButton.icon(
                            onPressed: () => _addToStock(d),
                            icon: const Icon(Icons.add_circle_outline,
                                color: AppColors.reference),
                            label: const Text('Add to Stock',
                                style: TextStyle(color: AppColors.reference)),
                          ),
                          onTap: () => _showDetail(d),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showDetail(DrugInfo d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Text(d.brandName,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('${d.genericName} • ${d.category}',
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 14),
            _detailRow('Dosage Form', d.dosageForm),
            _detailRow('Strength', d.strength),
            _detailRow('Usage', d.usage),
            _detailRow('Dosage', d.dosage),
            _detailRow('Overdose Info', d.overdoseInfo),
            _detailRow('Precautions', d.precautions),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _addToStock(d);
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Add to Stock'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.reference,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.reference)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

