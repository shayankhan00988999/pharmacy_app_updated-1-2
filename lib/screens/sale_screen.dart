import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/medicine.dart';
import '../models/patient.dart';
import '../models/sale.dart';
import '../widgets/drug_info_card.dart';
import '../theme/app_colors.dart';
import 'sales_history_screen.dart';

class CartLine {
  final Medicine medicine;
  int quantity;
  CartLine({required this.medicine, this.quantity = 1});
  double get subtotal => medicine.salePrice * quantity;
}

class SaleScreen extends StatefulWidget {
  final Patient? initialPatient;
  final Medicine? initialMedicine;

  const SaleScreen({super.key, this.initialPatient, this.initialMedicine});

  @override
  State<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  List<Medicine> _searchResults = [];
  final List<CartLine> _cart = [];
  Patient? _selectedPatient;
  String _paymentType = 'Cash';
  double _discount = 0;

  @override
  void initState() {
    super.initState();
    _selectedPatient = widget.initialPatient;
    if (widget.initialMedicine != null) {
      _cart.add(CartLine(medicine: widget.initialMedicine!));
    }
  }

  Future<void> _showMedicineInfo(Medicine m) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(14),
          child: DrugInfoCard(
            title: m.name,
            subtitle: m.genericName.isNotEmpty ? 'Generic: ${m.genericName}' : null,
            medicine: m,
          ),
        ),
      ),
    );
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final results = await DatabaseHelper.instance.searchMedicines(query);
    setState(() => _searchResults = results.where((m) => m.quantity > 0).toList());
  }

  void _addToCart(Medicine m) {
    setState(() {
      final existing = _cart.where((c) => c.medicine.id == m.id);
      if (existing.isNotEmpty) {
        existing.first.quantity++;
      } else {
        _cart.add(CartLine(medicine: m));
      }
      _searchResults = [];
    });
  }

  double get _total {
    final sum = _cart.fold<double>(0, (prev, c) => prev + c.subtotal);
    return sum - _discount;
  }

  Future<void> _pickPatient() async {
    final patients = await DatabaseHelper.instance.getAllPatients();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        padding: const EdgeInsets.all(12),
        children: [
          ListTile(
            title: const Text('Walk-in customer (no record)'),
            onTap: () {
              setState(() => _selectedPatient = null);
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ...patients.map((p) => ListTile(
                title: Text(p.name),
                subtitle: Text(p.phone),
                onTap: () {
                  setState(() => _selectedPatient = p);
                  Navigator.pop(context);
                },
              )),
        ],
      ),
    );
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty) return;

    final items = _cart
        .map((c) => SaleItem(
              medicineId: c.medicine.id!,
              medicineName: c.medicine.name,
              quantity: c.quantity,
              priceAtSale: c.medicine.salePrice,
            ))
        .toList();

    final sale = Sale(
      patientId: _selectedPatient?.id,
      patientName: _selectedPatient?.name,
      totalAmount: _total,
      discount: _discount,
      paymentType: _paymentType,
      date: DateTime.now(),
      items: items,
    );

    await DatabaseHelper.instance.createSale(sale);

    setState(() {
      _cart.clear();
      _selectedPatient = null;
      _discount = 0;
      _paymentType = 'Cash';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sale completed successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Sale'),
        backgroundColor: AppColors.sell,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SalesHistoryScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search medicine to add...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
              onChanged: _search,
            ),
          ),
          if (_searchResults.isNotEmpty)
            SizedBox(
              height: 180,
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, i) {
                  final m = _searchResults[i];
                  return ListTile(
                    title: Text(m.name),
                    subtitle: Text('Stock: ${m.quantity} • Rs. ${m.salePrice}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.info_outline, color: Colors.grey),
                          tooltip: 'Medicine info',
                          onPressed: () => _showMedicineInfo(m),
                        ),
                        const Icon(Icons.add_circle, color: AppColors.sell),
                      ],
                    ),
                    onTap: () => _addToCart(m),
                  );
                },
              ),
            ),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(_selectedPatient?.name ?? 'Walk-in customer'),
            subtitle: _selectedPatient != null
                ? Text(_selectedPatient!.phone)
                : const Text('Tap to link a patient (optional)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickPatient,
          ),
          const Divider(height: 1),
          Expanded(
            child: _cart.isEmpty
                ? const Center(child: Text('Cart is empty. Search to add medicines.'))
                : ListView.builder(
                    itemCount: _cart.length,
                    itemBuilder: (context, i) {
                      final c = _cart[i];
                      return ListTile(
                        title: Text(c.medicine.name),
                        subtitle: Text('Rs. ${c.medicine.salePrice} each'),
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => setState(() {
                                if (c.quantity > 1) {
                                  c.quantity--;
                                } else {
                                  _cart.removeAt(i);
                                }
                              }),
                            ),
                            Text('${c.quantity}'),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => setState(() => c.quantity++),
                            ),
                          ],
                        ),
                        trailing: Text('Rs. ${c.subtotal.toStringAsFixed(0)}'),
                      );
                    },
                  ),
          ),
          if (_cart.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, -2))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text('Payment: '),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _paymentType,
                        items: ['Cash', 'Card', 'Mobile Wallet']
                            .map((p) =>
                                DropdownMenuItem(value: p, child: Text(p)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _paymentType = v ?? 'Cash'),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          decoration: const InputDecoration(
                              labelText: 'Discount', isDense: true),
                          onChanged: (v) =>
                              setState(() => _discount = double.tryParse(v) ?? 0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Rs. ${_total.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.sell)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _checkout,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppColors.sell,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Complete Sale'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
