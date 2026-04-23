import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/firebase_service.dart';
import '../models/bill_model.dart';

class BillingProvider with ChangeNotifier {
  final _svc = FirebaseService();
  Map<Product, double> cart = {};

  void addToCart(Product p) {
    final step = p.unit.cartStep;
    final current = cart[p] ?? 0.0;
    final next = _r(current + step);
    if (next > p.quantity) return;
    cart.update(p, (_) => next, ifAbsent: () => step);
    notifyListeners();
  }

  void decrementFromCart(Product p) {
    if (!cart.containsKey(p)) return;
    final next = _r((cart[p] ?? 0.0) - p.unit.cartStep);
    if (next <= 0) { cart.remove(p); } else { cart[p] = next; }
    notifyListeners();
  }

  void setCustomQty(Product p, double qty) {
    if (qty <= 0) { cart.remove(p); } else { cart[p] = _r(qty.clamp(0, p.quantity)); }
    notifyListeners();
  }

  void removeFromCart(Product p) { cart.remove(p); notifyListeners(); }
  void clearCart() { cart.clear(); notifyListeners(); }

  double get total => cart.entries.fold(0.0, (s, e) => s + e.key.price * e.value);
  int get itemCount => cart.length;

  Future<void> confirmBill() async {
    final bill = Bill(id: '', total: total, date: DateTime.now());
    final snapshot = Map<Product, double>.from(cart);
    cart.clear(); notifyListeners();
    for (final e in snapshot.entries) {
      _svc.updateProductQuantity(e.key.id, _r(e.key.quantity - e.value));
    }
    _svc.addBill(bill);
  }

  double _r(double v) => (v * 1000).round() / 1000;
}