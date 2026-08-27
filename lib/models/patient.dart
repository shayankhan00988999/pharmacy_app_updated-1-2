class Patient {
  final int? id;
  final String name;
  final int age;
  final String gender;
  final String phone;
  final String address;
  final String allergies;
  final String notes;

  Patient({
    this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.phone,
    this.address = '',
    this.allergies = '',
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'phone': phone,
      'address': address,
      'allergies': allergies,
      'notes': notes,
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'],
      name: map['name'],
      age: map['age'],
      gender: map['gender'],
      phone: map['phone'],
      address: map['address'] ?? '',
      allergies: map['allergies'] ?? '',
      notes: map['notes'] ?? '',
    );
  }
}
