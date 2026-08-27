import 'package:flutter/material.dart';
import '../data/medicine_reference.dart';
import '../db/database_helper.dart';
import '../models/medicine.dart';
import '../theme/app_colors.dart';

class AddMedicineScreen extends StatefulWidget {
  final Medicine? medicine;
  const AddMedicineScreen({super.key, this.medicine});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _name;
  late TextEditingController _generic;
  late TextEditingController _category;
  late TextEditingController _batch;
  late TextEditingController _purchasePrice;
  late TextEditingController _salePrice;
  late TextEditingController _quantity;
  late TextEditingController _unit;
  late TextEditingController _supplier;
  late TextEditingController _minStock;
  late TextEditingController _usage;
  late TextEditingController _dosage;
  late TextEditingController _overdoseInfo;
  late TextEditingController _precautions;
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));
  bool _showMedicalInfo = false;

  @override
  void initState() {
    super.initState();
    final m = widget.medicine;
    _name = TextEditingController(text: m?.name ?? '');
    _generic = TextEditingController(text: m?.genericName ?? '');
    _category = TextEditingController(text: m?.category ?? '');
    _batch = TextEditingController(text: m?.batchNo ?? '');
    _purchasePrice =
        TextEditingController(text: m?.purchasePrice.toString() ?? '');
    _salePrice = TextEditingController(text: m?.salePrice.toString() ?? '');
    _quantity = TextEditingController(text: m?.quantity.toString() ?? '');
    _unit = TextEditingController(text: m?.unit ?? 'strip');
    _supplier = TextEditingController(text: m?.supplier ?? '');
    _minStock = TextEditingController(text: m?.minStockAlert.toString() ?? '10');
    _usage = TextEditingController(text: m?.usage ?? '');
    _dosage = TextEditingController(text: m?.dosage ?? '');
    _overdoseInfo = TextEditingController(text: m?.overdoseInfo ?? '');
    _precautions = TextEditingController(text: m?.precautions ?? '');
    if (m != null) _expiryDate = m.expiryDate;
    _showMedicalInfo = _usage.text.isNotEmpty ||
        _dosage.text.isNotEmpty ||
        _overdoseInfo.text.isNotEmpty ||
        _precautions.text.isNotEmpty;
  }

  /// Tries to pre-fill the medical-info fields from the built-in drug
  /// reference database, matching on the medicine name or generic name
  /// typed so far. Never overwrites text the pharmacist already entered.
  void _autoFillFromReference() {
    final match = lookupDrugInfo(_name.text.trim().isNotEmpty
            ? _name.text
            : _generic.text) ??
        lookupDrugInfo(_generic.text);
    if (match == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No built-in reference match found for that name')),
      );
      return;
    }
    setState(() {
      _showMedicalInfo = true;
      if (_generic.text.trim().isEmpty) _generic.text = match.genericName;
      // The "Category" field here is used for dosage form (Tablet/Syrup/etc.)
      if (_category.text.trim().isEmpty) _category.text = match.dosageForm;
      if (_usage.text.trim().isEmpty) _usage.text = match.usage;
      if (_dosage.text.trim().isEmpty) _dosage.text = match.dosage;
      if (_overdoseInfo.text.trim().isEmpty) _overdoseInfo.text = match.overdoseInfo;
      if (_precautions.text.trim().isEmpty) _precautions.text = match.precautions;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final medicine = Medicine(
      id: widget.medicine?.id,
      name: _name.text.trim(),
      genericName: _generic.text.trim(),
      category: _category.text.trim(),
      batchNo: _batch.text.trim(),
      purchasePrice: double.tryParse(_purchasePrice.text) ?? 0,
      salePrice: double.tryParse(_salePrice.text) ?? 0,
      quantity: int.tryParse(_quantity.text) ?? 0,
      unit: _unit.text.trim(),
      expiryDate: _expiryDate,
      supplier: _supplier.text.trim(),
      minStockAlert: int.tryParse(_minStock.text) ?? 10,
      usage: _usage.text.trim(),
      dosage: _dosage.text.trim(),
      overdoseInfo: _overdoseInfo.text.trim(),
      precautions: _precautions.text.trim(),
    );

    if (widget.medicine == null) {
      await DatabaseHelper.instance.insertMedicine(medicine);
    } else {
      await DatabaseHelper.instance.updateMedicine(medicine);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.medicine == null ? 'Add Medicine' : 'Edit Medicine'),
          backgroundColor: AppColors.medicines,
          foregroundColor: Colors.white),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_name, 'Medicine Name', required: true),
            _field(_generic, 'Generic Name'),
            _field(_category, 'Category (Tablet, Syrup, etc.)'),
            _field(_batch, 'Batch Number'),
            Row(
              children: [
                Expanded(
                    child: _field(_purchasePrice, 'Purchase Price',
                        keyboard: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(
                    child: _field(_salePrice, 'Sale Price',
                        keyboard: TextInputType.number, required: true)),
              ],
            ),
            Row(
              children: [
                Expanded(
                    child: _field(_quantity, 'Quantity',
                        keyboard: TextInputType.number, required: true)),
                const SizedBox(width: 10),
                Expanded(child: _field(_unit, 'Unit (strip/box/bottle)')),
              ],
            ),
            _field(_minStock, 'Low Stock Alert Threshold',
                keyboard: TextInputType.number),
            _field(_supplier, 'Supplier'),
            const SizedBox(height: 8),
            const Divider(),
            InkWell(
              onTap: () => setState(() => _showMedicalInfo = !_showMedicalInfo),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.medical_information_outlined,
                        color: AppColors.medicines),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Medical Info (usage, dosage, precautions)',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    Icon(_showMedicalInfo
                        ? Icons.expand_less
                        : Icons.expand_more),
                  ],
                ),
              ),
            ),
            if (_showMedicalInfo) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _autoFillFromReference,
                  icon: const Icon(Icons.auto_fix_high, size: 18),
                  label: const Text('Auto-fill from reference database'),
                ),
              ),
              _field(_usage, 'Usage', keyboard: TextInputType.multiline),
              _field(_dosage, 'Dosage', keyboard: TextInputType.multiline),
              _field(_overdoseInfo, 'Overdose Risks',
                  keyboard: TextInputType.multiline),
              _field(_precautions, 'Precautions', keyboard: TextInputType.multiline),
            ],
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Expiry Date'),
              subtitle: Text(
                  '${_expiryDate.year}-${_expiryDate.month.toString().padLeft(2, '0')}-${_expiryDate.day.toString().padLeft(2, '0')}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _expiryDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2040),
                );
                if (picked != null) setState(() => _expiryDate = picked);
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: AppColors.medicines,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save Medicine'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
      {bool required = false, TextInputType? keyboard}) {
    final isMultiline = keyboard == TextInputType.multiline;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        minLines: isMultiline ? 2 : 1,
        maxLines: isMultiline ? 4 : 1,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
      ),
    );
  }
}
