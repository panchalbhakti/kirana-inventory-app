class Bill {
  String id;
  double total;
  DateTime date;

  Bill({
    required this.id,
    required this.total,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'total': total,
      'date': date.toIso8601String(),
    };
  }

  factory Bill.fromMap(String id, Map<String, dynamic> map) {
    return Bill(
      id: id,
      total: (map['total'] as num).toDouble(),
      date: DateTime.parse(map['date']),
    );
  }
}