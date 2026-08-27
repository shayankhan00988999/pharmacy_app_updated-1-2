import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/patient.dart';
import '../theme/app_colors.dart';
import 'add_patient_screen.dart';
import 'patient_history_screen.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  List<Patient> _patients = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = _query.isEmpty
        ? await DatabaseHelper.instance.getAllPatients()
        : await DatabaseHelper.instance.searchPatients(_query);
    if (!mounted) return;
    setState(() => _patients = list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patients'),
        backgroundColor: AppColors.patients,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
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
            child: _patients.isEmpty
                ? const Center(child: Text('No patients found.'))
                : ListView.builder(
                    itemCount: _patients.length,
                    itemBuilder: (context, index) {
                      final p = _patients[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.patients.withOpacity(0.15),
                            child: Text(p.name.isNotEmpty
                                ? p.name[0].toUpperCase()
                                : '?'),
                          ),
                          title: Text(p.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              '${p.age} yrs • ${p.gender} • ${p.phone}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      PatientHistoryScreen(patient: p)),
                            );
                            _load();
                          },
                          onLongPress: () => _confirmDelete(p),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.patients,
        foregroundColor: Colors.white,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPatientScreen()),
          );
          _load();
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }

  void _confirmDelete(Patient p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Patient'),
        content: Text('Delete "${p.name}" record?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.deletePatient(p.id!);
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
