class Medicine {
  final int? id;
  final String name;
  final String genericName;
  final String category;
  final String batchNo;
  final double purchasePrice;
  final double salePrice;
  final int quantity;
  final String unit;
  final DateTime expiryDate;
  final String supplier;
  final int minStockAlert;

  // Optional medical reference info. When left blank, the app falls back
  // to its built-in drug reference database (see data/medicine_reference.dart)
  // matched by name/generic name, so these only need to be filled in for
  // medicines that aren't in the built-in list.
  final String usage;
  final String dosage;
  final String overdoseInfo;
  final String precautions;

  Medicine({
    this.id,
    required this.name,
    required this.genericName,
    required this.category,
    required this.batchNo,
    required this.purchasePrice,
    required this.salePrice,
    required this.quantity,
    required this.unit,
    required this.expiryDate,
    required this.supplier,
    this.minStockAlert = 10,
    this.usage = '',
    this.dosage = '',
    this.overdoseInfo = '',
    this.precautions = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'genericName': genericName,
      'category': category,
      'batchNo': batchNo,
      'purchasePrice': purchasePrice,
      'salePrice': salePrice,
      'quantity': quantity,
      'unit': unit,
      'expiryDate': expiryDate.toIso8601String(),
      'supplier': supplier,
      'minStockAlert': minStockAlert,
      'usage': usage,
      'dosage': dosage,
      'overdoseInfo': overdoseInfo,
      'precautions': precautions,
    };
  }

  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      id: map['id'],
      name: map['name'],
      genericName: map['genericName'],
      category: map['category'],
      batchNo: map['batchNo'],
      purchasePrice: map['purchasePrice'],
      salePrice: map['salePrice'],
      quantity: map['quantity'],
      unit: map['unit'],
      expiryDate: DateTime.parse(map['expiryDate']),
      supplier: map['supplier'],
      minStockAlert: map['minStockAlert'] ?? 10,
      usage: map['usage'] ?? '',
      dosage: map['dosage'] ?? '',
      overdoseInfo: map['overdoseInfo'] ?? '',
      precautions: map['precautions'] ?? '',
    );
  }

  Medicine copyWith({
    int? id,
    String? name,
    String? genericName,
    String? category,
    String? batchNo,
    double? purchasePrice,
    double? salePrice,
    int? quantity,
    String? unit,
    DateTime? expiryDate,
    String? supplier,
    int? minStockAlert,
    String? usage,
    String? dosage,
    String? overdoseInfo,
    String? precautions,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      genericName: genericName ?? this.genericName,
      category: category ?? this.category,
      batchNo: batchNo ?? this.batchNo,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salePrice: salePrice ?? this.salePrice,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      expiryDate: expiryDate ?? this.expiryDate,
      supplier: supplier ?? this.supplier,
      minStockAlert: minStockAlert ?? this.minStockAlert,
      usage: usage ?? this.usage,
      dosage: dosage ?? this.dosage,
      overdoseInfo: overdoseInfo ?? this.overdoseInfo,
      precautions: precautions ?? this.precautions,
    );
  }

  bool get isLowStock => quantity <= minStockAlert;

  bool get isExpired => expiryDate.isBefore(DateTime.now());

  bool get isExpiringSoon {
    final days = expiryDate.difference(DateTime.now()).inDays;
    return days >= 0 && days <= 60;
  }
}
