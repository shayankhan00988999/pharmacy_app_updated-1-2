import 'package:flutter/material.dart';
import '../data/medicine_reference.dart';
import '../db/database_helper.dart';
import '../models/medicine.dart';
import '../models/patient.dart';
import '../widgets/drug_info_card.dart';
import '../theme/app_colors.dart';
import 'add_medicine_screen.dart';
import 'sale_screen.dart';

/// The "Medicine & Patient Lookup" screen.
///
/// Workflow: a patient asks the pharmacist for a medicine by name (often a
/// brand name like "Brufen"). The pharmacist types it here and instantly
/// sees usage/dosage/overdose/precautions info — pulled from the store's
/// own inventory notes if present, otherwise from the built-in offline
/// drug reference — while at the same time pulling up or creating that
/// patient's record, so everything needed to safely clarify and dispense
/// is on one screen.
class MedicineInfoScreen extends StatefulWidget {
  const MedicineInfoScreen({super.key});

  @override
  State<MedicineInfoScreen> createState() => _MedicineInfoScreenState();
}

class _MedicineInfoScreenState extends State<MedicineInfoScreen> {
  final _searchController = TextEditingController();
  final _newPatientName = TextEditingController();
  final _newPatientAge = TextEditingController();
  final _newPatientPhone = TextEditingController();
  String _newPatientGender = 'Male';

  List<DrugInfo> _suggestions = [];
  DrugInfo? _matchedReference;
  Medicine? _matchedInventory; // exact/closest match in the store's stock
  List<Medicine> _otherInventoryMatches = [];
  String _searchedName = '';

  List<Patient> _patientResults = [];
  Patient? _selectedPatient;
  bool _showAddPatientForm = false;

  Future<void> _onSearchChanged(String query) async {
    setState(() {
      _searchedName = query;
      _suggestions = suggestDrugInfo(query);
    });
    if (query.trim().isEmpty) {
      setState(() {
        _matchedReference = null;
        _matchedInventory = null;
        _otherInventoryMatches = [];
      });
      return;
    }

    final inventoryMatches = await DatabaseHelper.instance.searchMedicines(query);
    final reference = lookupDrugInfo(query);

    if (!mounted) return;
    setState(() {
      _matchedReference = reference;
      _matchedInventory = inventoryMatches.isNotEmpty ? inventoryMatches.first : null;
      _otherInventoryMatches =
          inventoryMatches.length > 1 ? inventoryMatches.sublist(1) : [];
    });
  }

  void _pickSuggestion(DrugInfo d) {
    _searchController.text = d.brandName;
    _onSearchChanged(d.brandName);
  }

  Future<void> _searchPatients(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _patientResults = []);
      return;
    }
    final results = await DatabaseHelper.instance.searchPatients(query);
    if (!mounted) return;
    setState(() => _patientResults = results);
  }

  Future<void> _saveNewPatient() async {
    if (_newPatientName.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient name is required')),
      );
      return;
    }
    final patient = Patient(
      name: _newPatientName.text.trim(),
      age: int.tryParse(_newPatientAge.text) ?? 0,
      gender: _newPatientGender,
      phone: _newPatientPhone.text.trim(),
    );
    final id = await DatabaseHelper.instance.insertPatient(patient);
    if (!mounted) return;
    setState(() {
      _selectedPatient = Patient(
        id: id,
        name: patient.name,
        age: patient.age,
        gender: patient.gender,
        phone: patient.phone,
      );
      _showAddPatientForm = false;
      _newPatientName.clear();
      _newPatientAge.clear();
      _newPatientPhone.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Patient record created for ${patient.name}')),
    );
  }

  void _proceedToSale() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SaleScreen(
          initialPatient: _selectedPatient,
          initialMedicine: _matchedInventory,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _newPatientName.dispose();
    _newPatientAge.dispose();
    _newPatientPhone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasResult = _searchedName.trim().isNotEmpty &&
        (_matchedReference != null || _matchedInventory != null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine & Patient Lookup'),
        backgroundColor: AppColors.lookup,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          const Text(
            'Type the medicine the patient asked for (brand or generic name) to '
            'see usage, dosage, overdose risks and precautions before dispensing.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'e.g. Brufen, Panadol, Augmentin...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: _onSearchChanged,
          ),
          if (_suggestions.isNotEmpty && _matchedReference == null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _suggestions
                    .map((d) => ActionChip(
                          label: Text('${d.brandName} (${d.genericName})'),
                          onPressed: () => _pickSuggestion(d),
                        ))
                    .toList(),
              ),
            ),
          const SizedBox(height: 14),
          if (hasResult) ...[
            DrugInfoCard(
              title: _matchedInventory?.name ?? _matchedReference?.brandName ?? _searchController.text.trim(),
              subtitle: _matchedReference != null
                  ? 'Generic: ${_matchedReference!.genericName} • ${_matchedReference!.category}'
                  : (_matchedInventory?.genericName.isNotEmpty == true
                      ? 'Generic: ${_matchedInventory!.genericName}'
                      : null),
              reference: _matchedReference,
              medicine: _matchedInventory,
            ),
            const SizedBox(height: 10),
            if (_matchedInventory != null)
              Card(
                color: _matchedInventory!.quantity > 0
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                child: ListTile(
                  leading: Icon(
                    _matchedInventory!.quantity > 0
                        ? Icons.check_circle
                        : Icons.remove_circle,
                    color: _matchedInventory!.quantity > 0
                        ? Colors.green
                        : Colors.red,
                  ),
                  title: Text(_matchedInventory!.quantity > 0
                      ? 'In stock: ${_matchedInventory!.quantity} ${_matchedInventory!.unit}'
                      : 'Out of stock'),
                  subtitle: Text('Rs. ${_matchedInventory!.salePrice} • Batch ${_matchedInventory!.batchNo}'),
                ),
              )
            else
              Card(
                color: Colors.amber.shade50,
                child: ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.amber),
                  title: const Text('Not in this store\'s inventory'),
                  subtitle: const Text('Add it to stock to sell it from here.'),
                  trailing: TextButton(
                    child: const Text('Add'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddMedicineScreen(
                            medicine: _matchedReference == null
                                ? null
                                : Medicine(
                                    name: _matchedReference!.brandName,
                                    genericName: _matchedReference!.genericName,
                                    category: _matchedReference!.dosageForm,
                                    batchNo: '',
                                    purchasePrice: 0,
                                    salePrice: 0,
                                    quantity: 0,
                                    unit: 'strip',
                                    expiryDate: DateTime.now()
                                        .add(const Duration(days: 365)),
                                    supplier: '',
                                    usage: _matchedReference!.usage,
                                    dosage: _matchedReference!.dosage,
                                    overdoseInfo: _matchedReference!.overdoseInfo,
                                    precautions: _matchedReference!.precautions,
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            if (_otherInventoryMatches.isNotEmpty) ...[
              const SizedBox(height: 6),
              const Text('Other matches in stock:',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              ..._otherInventoryMatches.take(3).map((m) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(m.name),
                    subtitle: Text('Stock: ${m.quantity} • Rs. ${m.salePrice}'),
                    onTap: () => setState(() => _matchedInventory = m),
                  )),
            ],
          ] else if (_searchedName.trim().isNotEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No match found in inventory or the built-in reference list yet.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.badge_outlined, color: AppColors.lookup),
              const SizedBox(width: 8),
              const Text('Patient Record',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_selectedPatient != null)
                TextButton(
                  onPressed: () => setState(() => _selectedPatient = null),
                  child: const Text('Clear'),
                ),
            ],
          ),
          if (_selectedPatient != null)
            Card(
              color: AppColors.lookup.withOpacity(0.08),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(_selectedPatient!.name),
                subtitle: Text(
                    '${_selectedPatient!.age > 0 ? '${_selectedPatient!.age} yrs • ' : ''}${_selectedPatient!.gender} • ${_selectedPatient!.phone}'),
              ),
            )
          else ...[
            TextField(
              decoration: InputDecoration(
                hintText: 'Search existing patient by name or phone...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _searchPatients,
            ),
            ..._patientResults.map((p) => ListTile(
                  title: Text(p.name),
                  subtitle: Text('${p.age > 0 ? '${p.age} yrs • ' : ''}${p.gender} • ${p.phone}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => setState(() {
                    _selectedPatient = p;
                    _patientResults = [];
                  }),
                )),
            const SizedBox(height: 6),
            if (!_showAddPatientForm)
              OutlinedButton.icon(
                onPressed: () => setState(() => _showAddPatientForm = true),
                icon: const Icon(Icons.person_add_alt),
                label: const Text('New patient (quick add)'),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TextField(
                        controller: _newPatientName,
                        decoration: const InputDecoration(labelText: 'Full Name'),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newPatientAge,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Age'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _newPatientGender,
                              items: ['Male', 'Female', 'Other']
                                  .map((g) =>
                                      DropdownMenuItem(value: g, child: Text(g)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _newPatientGender = v ?? 'Male'),
                              decoration: const InputDecoration(labelText: 'Gender'),
                            ),
                          ),
                        ],
                      ),
                      TextField(
                        controller: _newPatientPhone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Phone'),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveNewPatient,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.lookup,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Save Patient Record'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_matchedInventory != null || _selectedPatient != null)
                  ? _proceedToSale
                  : null,
              icon: const Icon(Icons.point_of_sale),
              label: const Text('Proceed to Sale'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: AppColors.lookup,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
