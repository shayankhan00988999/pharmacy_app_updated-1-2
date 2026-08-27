import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xls;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/medicine.dart';
import '../theme/app_colors.dart';

/// Lets the user pick an Excel (.xlsx) or CSV file containing a medicine
/// list and imports every valid row straight into the inventory, instead
/// of typing each medicine in one-by-one.
///
/// Expected column headers (case-insensitive, any order):
/// name, genericName, category, batchNo, purchasePrice, salePrice,
/// quantity, unit, expiryDate, supplier, minStockAlert
///
/// Only "name" is required — everything else falls back to a sensible
/// default if it's missing or blank.
class BulkUploadScreen extends StatefulWidget {
  const BulkUploadScreen({super.key});

  @override
  State<BulkUploadScreen> createState() => _BulkUploadScreenState();
}

class _BulkUploadScreenState extends State<BulkUploadScreen> {
  String? _fileName;
  List<Medicine> _parsedMedicines = [];
  List<String> _rowErrors = [];
  bool _isParsing = false;
  bool _isImporting = false;
  String? _loadError;

  static const _knownHeaders = [
    'name',
    'genericname',
    'category',
    'batchno',
    'purchaseprice',
    'saleprice',
    'quantity',
    'unit',
    'expirydate',
    'supplier',
    'minstockalert',
  ];

  Future<void> _pickFile() async {
    setState(() {
      _loadError = null;
      _parsedMedicines = [];
      _rowErrors = [];
    });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'csv'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final picked = result.files.first;
    final bytes = picked.bytes;
    if (bytes == null) {
      setState(() => _loadError = 'Could not read the selected file.');
      return;
    }

    setState(() {
      _isParsing = true;
      _fileName = picked.name;
    });

    try {
      final lowerName = picked.name.toLowerCase();
      List<List<String>> rows;
      if (lowerName.endsWith('.csv')) {
        rows = _parseCsv(bytes);
      } else {
        rows = _parseExcel(bytes);
      }
      _processRows(rows);
    } catch (e) {
      setState(() {
        _loadError =
            'Could not read this file. Make sure it is a valid .xlsx or .csv file.';
      });
    } finally {
      setState(() => _isParsing = false);
    }
  }

  List<List<String>> _parseCsv(Uint8List bytes) {
    final content = utf8.decode(bytes, allowMalformed: true);
    final rows = const CsvToListConverter(shouldParseNumbers: false)
        .convert(content);
    return rows.map((row) => row.map((c) => c.toString().trim()).toList()).toList();
  }

  List<List<String>> _parseExcel(Uint8List bytes) {
    final workbook = xls.Excel.decodeBytes(bytes);
    if (workbook.tables.isEmpty) return [];
    final sheet = workbook.tables[workbook.tables.keys.first]!;
    final rows = <List<String>>[];
    for (final row in sheet.rows) {
      rows.add(row.map((cell) => _cellToString(cell)).toList());
    }
    return rows;
  }

  String _cellToString(xls.Data? cell) {
    final value = cell?.value;
    if (value == null) return '';
    if (value is xls.TextCellValue) return value.value.toString().trim();
    if (value is xls.IntCellValue) return value.value.toString();
    if (value is xls.DoubleCellValue) return value.value.toString();
    if (value is xls.BoolCellValue) return value.value.toString();
    if (value is xls.DateCellValue) {
      final mm = value.month.toString().padLeft(2, '0');
      final dd = value.day.toString().padLeft(2, '0');
      return '${value.year}-$mm-$dd';
    }
    if (value is xls.DateTimeCellValue) {
      final dt = value.asDateTimeLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }
    return value.toString().trim();
  }

  void _processRows(List<List<String>> rows) {
    if (rows.isEmpty) {
      setState(() => _loadError = 'The file appears to be empty.');
      return;
    }

    final headerRow = rows.first.map((h) => h.trim().toLowerCase()).toList();
    final columnIndex = <String, int>{};
    for (final key in _knownHeaders) {
      final idx = headerRow.indexOf(key);
      if (idx != -1) columnIndex[key] = idx;
    }

    if (!columnIndex.containsKey('name')) {
      setState(() {
        _loadError =
            'No "name" column found in the header row. Please add a column called "name" for the medicine name.';
      });
      return;
    }

    final medicines = <Medicine>[];
    final errors = <String>[];

    String cellAt(List<String> row, String key) {
      final idx = columnIndex[key];
      if (idx == null || idx >= row.length) return '';
      return row[idx].trim();
    }

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.every((c) => c.trim().isEmpty)) continue; // skip blank rows

      final name = cellAt(row, 'name');
      if (name.isEmpty) {
        errors.add('Row ${i + 1}: skipped — no medicine name');
        continue;
      }

      final quantity = int.tryParse(cellAt(row, 'quantity')) ?? 0;
      final purchasePrice = double.tryParse(cellAt(row, 'purchaseprice')) ?? 0;
      final salePrice = double.tryParse(cellAt(row, 'saleprice')) ?? 0;
      final minStockAlert = int.tryParse(cellAt(row, 'minstockalert')) ?? 10;
      final expiryDate =
          _parseDate(cellAt(row, 'expirydate')) ??
              DateTime.now().add(const Duration(days: 365));

      medicines.add(Medicine(
        name: name,
        genericName: cellAt(row, 'genericname'),
        category: cellAt(row, 'category').isEmpty
            ? 'General'
            : cellAt(row, 'category'),
        batchNo: cellAt(row, 'batchno'),
        purchasePrice: purchasePrice,
        salePrice: salePrice,
        quantity: quantity,
        unit: cellAt(row, 'unit').isEmpty ? 'pcs' : cellAt(row, 'unit'),
        expiryDate: expiryDate,
        supplier: cellAt(row, 'supplier'),
        minStockAlert: minStockAlert,
      ));
    }

    setState(() {
      _parsedMedicines = medicines;
      _rowErrors = errors;
    });
  }

  DateTime? _parseDate(String raw) {
    if (raw.isEmpty) return null;
    // Try ISO first (yyyy-MM-dd), then a couple of common formats.
    final isoAttempt = DateTime.tryParse(raw);
    if (isoAttempt != null) return isoAttempt;

    for (final sep in ['/', '-']) {
      final parts = raw.split(sep);
      if (parts.length == 3) {
        final a = int.tryParse(parts[0]);
        final b = int.tryParse(parts[1]);
        final c = int.tryParse(parts[2]);
        if (a != null && b != null && c != null) {
          // Assume dd/MM/yyyy when the first part is a plausible day.
          try {
            if (a > 31) {
              return DateTime(a, b, c); // yyyy-MM-dd style
            } else if (a <= 31 && b <= 12) {
              return DateTime(c, b, a); // dd-MM-yyyy style
            }
          } catch (_) {
            return null;
          }
        }
      }
    }
    return null;
  }

  Future<void> _confirmImport() async {
    if (_parsedMedicines.isEmpty) return;
    setState(() => _isImporting = true);

    try {
      final count =
          await DatabaseHelper.instance.insertMedicinesBulk(_parsedMedicines);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count medicines imported successfully.'),
          backgroundColor: AppColors.medicines,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Import failed. Please check the file and try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Upload Medicines'),
        backgroundColor: AppColors.medicines,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('File format',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text(
                      'Upload an Excel (.xlsx) or CSV file. The first row '
                      'must be column headers. Only "name" is required — '
                      'the rest are optional.',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Recognised columns:',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'name, genericName, category, batchNo, purchasePrice, '
                      'salePrice, quantity, unit, expiryDate (YYYY-MM-DD), '
                      'supplier, minStockAlert',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isParsing ? null : _pickFile,
              icon: const Icon(Icons.upload_file),
              label: Text(
                  _isParsing ? 'Reading file...' : 'Choose Excel / CSV File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.medicines,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            if (_fileName != null) ...[
              const SizedBox(height: 8),
              Text('Selected file: $_fileName',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
            if (_loadError != null) ...[
              const SizedBox(height: 12),
              Text(_loadError!,
                  style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],
            if (_parsedMedicines.isNotEmpty || _rowErrors.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                '${_parsedMedicines.length} medicines ready to import'
                '${_rowErrors.isNotEmpty ? ', ${_rowErrors.length} rows skipped' : ''}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (_parsedMedicines.isNotEmpty)
                Card(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _parsedMedicines.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final m = _parsedMedicines[index];
                        return ListTile(
                          dense: true,
                          title: Text(m.name),
                          subtitle: Text(
                              '${m.category} • Qty ${m.quantity} ${m.unit} • Rs. ${m.salePrice}'),
                        );
                      },
                    ),
                  ),
                ),
              if (_rowErrors.isNotEmpty) ...[
                const SizedBox(height: 10),
                ExpansionTile(
                  title: Text('${_rowErrors.length} rows skipped',
                      style: const TextStyle(color: Colors.orange)),
                  children: _rowErrors
                      .map((e) => ListTile(
                            dense: true,
                            title: Text(e, style: const TextStyle(fontSize: 12)),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: (_isImporting || _parsedMedicines.isEmpty)
                    ? null
                    : _confirmImport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.medicines,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isImporting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('Import ${_parsedMedicines.length} Medicines'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
