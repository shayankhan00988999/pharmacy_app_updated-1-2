import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/patient.dart';
import '../models/sale.dart';
import '../theme/app_colors.dart';
import 'add_patient_screen.dart';

class PatientHistoryScreen extends StatefulWidget {
  final Patient patient;
  const PatientHistoryScreen({super.key, required this.patient});

  @override
  State<PatientHistoryScreen> createState() => _PatientHistoryScreenState();
}

class _PatientHistoryScreenState extends State<PatientHistoryScreen> {
  List<Sale> _sales = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sales =
        await DatabaseHelper.instance.getSalesForPatient(widget.patient.id!);
    if (!mounted) return;
    setState(() => _sales = sales);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.patient;
    return Scaffold(
      appBar: AppBar(
        title: Text(p.name),
        backgroundColor: AppColors.patients,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AddPatientScreen(patient: p)),
              );
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${p.age} yrs • ${p.gender}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Phone: ${p.phone}'),
                  if (p.address.isNotEmpty) Text('Address: ${p.address}'),
                  if (p.allergies.isNotEmpty)
                    Text('Allergies: ${p.allergies}',
                        style: const TextStyle(color: Colors.red)),
                  if (p.notes.isNotEmpty) Text('Notes: ${p.notes}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Purchase History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_sales.isEmpty) const Text('No purchases yet.'),
          ..._sales.map((s) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  title: Text(
                      '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}-${s.date.day.toString().padLeft(2, '0')} • Rs. ${s.totalAmount.toStringAsFixed(0)}'),
                  subtitle: Text(s.paymentType),
                  children: s.items
                      .map((i) => ListTile(
                            dense: true,
                            title: Text(i.medicineName),
                            trailing: Text('x${i.quantity}'),
                          ))
                      .toList(),
                ),
              )),
        ],
      ),
    );
  }
}
