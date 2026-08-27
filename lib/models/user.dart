class AppUser {
  final int? id;
  final String username;
  final String passwordHash;
  final String passwordEncrypted;
  final String email;
  final String fullName;
  final DateTime createdAt;

  AppUser({
    this.id,
    required this.username,
    required this.passwordHash,
    this.passwordEncrypted = '',
    this.email = '',
    required this.fullName,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'passwordHash': passwordHash,
      'passwordEncrypted': passwordEncrypted,
      'email': email,
      'fullName': fullName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'],
      username: map['username'],
      passwordHash: map['passwordHash'],
      passwordEncrypted: map['passwordEncrypted'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
