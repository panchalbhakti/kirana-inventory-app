class Customer {
  String id;
  String name;
  String phone;
  double totalCredit;
  double totalPaid;
  DateTime createdAt;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.totalCredit,
    required this.totalPaid,
    required this.createdAt,
  });

  double get outstanding => totalCredit - totalPaid;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'totalCredit': totalCredit,
      'totalPaid': totalPaid,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(String id, Map<String, dynamic> map) {
    return Customer(
      id: id,
      name: map['name'],
      phone: map['phone'],
      totalCredit: (map['totalCredit'] as num).toDouble(),
      totalPaid: (map['totalPaid'] as num).toDouble(),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}