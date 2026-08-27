class SaleItem {
  final int? id;
  final int? saleId;
  final int medicineId;
  final String medicineName;
  final int quantity;
  final double priceAtSale;

  SaleItem({
    this.id,
    this.saleId,
    required this.medicineId,
    required this.medicineName,
    required this.quantity,
    required this.priceAtSale,
  });

  double get subtotal => quantity * priceAtSale;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'saleId': saleId,
      'medicineId': medicineId,
      'medicineName': medicineName,
      'quantity': quantity,
      'priceAtSale': priceAtSale,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'],
      saleId: map['saleId'],
      medicineId: map['medicineId'],
      medicineName: map['medicineName'],
      quantity: map['quantity'],
      priceAtSale: map['priceAtSale'],
    );
  }
}

class Sale {
  final int? id;
  final int? patientId;
  final String? patientName;
  final double totalAmount;
  final double discount;
  final String paymentType;
  final DateTime date;
  final List<SaleItem> items;

  Sale({
    this.id,
    this.patientId,
    this.patientName,
    required this.totalAmount,
    this.discount = 0,
    required this.paymentType,
    required this.date,
    required this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'totalAmount': totalAmount,
      'discount': discount,
      'paymentType': paymentType,
      'date': date.toIso8601String(),
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      patientId: map['patientId'],
      patientName: map['patientName'],
      totalAmount: map['totalAmount'],
      discount: map['discount'] ?? 0,
      paymentType: map['paymentType'],
      date: DateTime.parse(map['date']),
      items: [],
    );
  }
}
