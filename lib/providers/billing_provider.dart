import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/firebase_service.dart';
import '../models/bill_model.dart';

class BillingProvider with ChangeNotifier {
  final _svc = FirebaseService();
  Map<Product, double> cart = {};
  bool _saving = false;
  String? saveError;

  bool get isSaving => _saving;

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

  Future<bool> confirmBill() async {
    _saving = true;
    saveError = null;
    notifyListeners();

    final snapshot = Map<Product, double>.from(cart);
    final bill = Bill(id: '', total: total, date: DateTime.now());

    try {
      // Save bill to Firestore
      await _svc.addBill(bill);

      // Clear cart immediately after bill is saved
      cart.clear();
      _saving = false;
      notifyListeners();

      // Update stock in background — don't block success screen
      for (final e in snapshot.entries) {
        _svc.updateProductQuantity(e.key.id, _r(e.key.quantity - e.value));
      }

      return true;
    } catch (e) {
      saveError = 'Failed to save bill. Please check your connection and try again.';
      _saving = false;
      notifyListeners();
      return false;
    }
  }

  double _r(double v) => (v * 1000).round() / 1000;
}