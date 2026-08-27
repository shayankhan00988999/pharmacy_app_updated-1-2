import 'package:flutter/material.dart';
import '../data/medicine_reference.dart';
import '../models/medicine.dart';

/// Displays usage / dosage / overdose / precautions info for a medicine.
/// Accepts either a built-in [DrugInfo] reference entry, a stored
/// [Medicine] with its own custom fields filled in, or both — custom
/// fields on a stored Medicine always take priority over the built-in
/// reference when present.
class DrugInfoCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final DrugInfo? reference;
  final Medicine? medicine;

  const DrugInfoCard({
    super.key,
    required this.title,
    this.subtitle,
    this.reference,
    this.medicine,
  });

  String _pick(String Function(DrugInfo) fromRef, String fromMedicine) {
    if (fromMedicine.trim().isNotEmpty) return fromMedicine;
    if (reference != null) return fromRef(reference!);
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final dosageForm = reference?.dosageForm ?? '';
    final strength = reference?.strength ?? '';
    final usage = _pick((d) => d.usage, medicine?.usage ?? '');
    final dosage = _pick((d) => d.dosage, medicine?.dosage ?? '');
    final overdose = _pick((d) => d.overdoseInfo, medicine?.overdoseInfo ?? '');
    final precautions = _pick((d) => d.precautions, medicine?.precautions ?? '');

    final hasAnything = usage.isNotEmpty ||
        dosage.isNotEmpty ||
        overdose.isNotEmpty ||
        precautions.isNotEmpty;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: Icon(Icons.medication_liquid, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      if (subtitle != null && subtitle!.isNotEmpty)
                        Text(subtitle!,
                            style:
                                const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            if (dosageForm.isNotEmpty || strength.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (dosageForm.isNotEmpty)
                    Chip(
                      label: Text(dosageForm, style: const TextStyle(fontSize: 12)),
                      avatar: const Icon(Icons.category_outlined, size: 16),
                      backgroundColor: Colors.teal.withOpacity(0.08),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  if (strength.isNotEmpty)
                    Chip(
                      label: Text(strength, style: const TextStyle(fontSize: 12)),
                      avatar: const Icon(Icons.straighten, size: 16),
                      backgroundColor: Colors.teal.withOpacity(0.08),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            if (!hasAnything)
              const Text(
                'No reference info available for this medicine yet. '
                'You can add usage/dosage/overdose/precautions notes when editing it.',
                style: TextStyle(color: Colors.grey),
              )
            else ...[
              _infoSection(Icons.info_outline, Colors.blue, 'Usage', usage),
              _infoSection(Icons.schedule, Colors.teal, 'Dosage', dosage),
              _infoSection(Icons.dangerous_outlined, Colors.red, 'Overdose Risks',
                  overdose),
              _infoSection(
                  Icons.shield_outlined, Colors.orange, 'Precautions', precautions),
            ],
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'General reference only — always confirm with the doctor\'s '
                      'prescription and product leaflet before dispensing.',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoSection(IconData icon, Color color, String label, String text) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: color, fontSize: 13)),
                const SizedBox(height: 2),
                Text(text, style: const TextStyle(fontSize: 13.5, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
