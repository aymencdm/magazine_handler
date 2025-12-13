class Student {
  final int id;
  final String fullName;
  final String phoneNumber;
  final String idCardNumber;
  final String email;
  final int transactionsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Student({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.idCardNumber,
    required this.email,
    required this.transactionsCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      fullName: json['full_name'],
      phoneNumber: json['phone_number'],
      idCardNumber: json['id_card_number'],
      email: json['email'] ?? '',
      transactionsCount: json['transactions_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'phone_number': phoneNumber,
      'id_card_number': idCardNumber,
      'email': email,
    };
  }
}
