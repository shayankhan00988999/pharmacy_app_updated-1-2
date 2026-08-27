import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/patient.dart';
import '../theme/app_colors.dart';

class AddPatientScreen extends StatefulWidget {
  final Patient? patient;
  const AddPatientScreen({super.key, this.patient});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _age;
  late TextEditingController _phone;
  late TextEditingController _address;
  late TextEditingController _allergies;
  late TextEditingController _notes;
  String _gender = 'Male';

  @override
  void initState() {
    super.initState();
    final p = widget.patient;
    _name = TextEditingController(text: p?.name ?? '');
    _age = TextEditingController(text: p?.age.toString() ?? '');
    _phone = TextEditingController(text: p?.phone ?? '');
    _address = TextEditingController(text: p?.address ?? '');
    _allergies = TextEditingController(text: p?.allergies ?? '');
    _notes = TextEditingController(text: p?.notes ?? '');
    if (p != null) _gender = p.gender;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final patient = Patient(
      id: widget.patient?.id,
      name: _name.text.trim(),
      age: int.tryParse(_age.text) ?? 0,
      gender: _gender,
      phone: _phone.text.trim(),
      address: _address.text.trim(),
      allergies: _allergies.text.trim(),
      notes: _notes.text.trim(),
    );
    if (widget.patient == null) {
      await DatabaseHelper.instance.insertPatient(patient);
    } else {
      await DatabaseHelper.instance.updatePatient(patient);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.patient == null ? 'Add Patient' : 'Edit Patient'),
          backgroundColor: AppColors.patients,
          foregroundColor: Colors.white),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                  labelText: 'Full Name', border: OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _age,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Age', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: const InputDecoration(
                        labelText: 'Gender', border: OutlineInputBorder()),
                    items: ['Male', 'Female', 'Other']
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (v) => setState(() => _gender = v ?? 'Male'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'Phone Number', border: OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(
                  labelText: 'Address', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _allergies,
              decoration: const InputDecoration(
                  labelText: 'Known Allergies', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Notes (chronic conditions, etc.)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: AppColors.patients,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save Patient'),
            ),
          ],
        ),
      ),
    );
  }
}
