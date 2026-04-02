class Subscription {
  final String plan; // 'free' or 'pro'
  final DateTime? expiryDate;
  final bool isActive;

  Subscription({
    required this.plan,
    this.expiryDate,
    required this.isActive,
  });

  bool get isPro => plan == 'pro' && isActive &&
      (expiryDate == null || expiryDate!.isAfter(DateTime.now()));

  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      plan: map['plan'] ?? 'free',
      expiryDate: map['expiryDate'] != null
          ? DateTime.parse(map['expiryDate'])
          : null,
      isActive: map['isActive'] ?? false,
    );
  }

  static Subscription free() {
    return Subscription(plan: 'free', isActive: true);
  }
}