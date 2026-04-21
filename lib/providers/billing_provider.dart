import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/firebase_service.dart';
import '../models/bill_model.dart';

class BillingProvider with ChangeNotifier {
  final FirebaseService _service = FirebaseService();
  Map<Product, int> cart = {};

  // ─── Cart Operations ───────────────────────────────────────────

  void addToCart(Product product) {
    final currentQty = cart[product] ?? 0;
    if (currentQty >= product.quantity) return;
    cart.update(product, (value) => value + 1, ifAbsent: () => 1);
    notifyListeners();
  }

  void removeFromCart(Product product) {
    cart.remove(product);
    notifyListeners();
  }

  void decrementFromCart(Product product) {
    if (!cart.containsKey(product)) return;
    if (cart[product]! <= 1) {
      cart.remove(product);
    } else {
      cart[product] = cart[product]! - 1;
    }
    notifyListeners();
  }

  void clearCart() {
    cart.clear();
    notifyListeners();
  }

  // ─── Totals ────────────────────────────────────────────────────

  double get total {
    double sum = 0;
    cart.forEach((product, qty) {
      sum += product.price * qty;
    });
    return sum;
  }

  int get itemCount {
    int count = 0;
    cart.forEach((_, qty) => count += qty);
    return count;
  }

  // ─── Confirm Bill ──────────────────────────────────────────────

  Future<void> confirmBill() async {
    try {
      final bill = Bill(
        id: '',
        total: total,
        date: DateTime.now(),
      );

      final cartSnapshot = Map<Product, int>.from(cart);

      cart.clear();
      notifyListeners();

      for (final entry in cartSnapshot.entries) {
        final product = entry.key;
        final soldQty = entry.value;
        final newQuantity = product.quantity - soldQty;
        _service.updateProductQuantity(product.id, newQuantity);
      }

      _service.addBill(bill);
    } catch (e) {
      rethrow;
    }
  }
}