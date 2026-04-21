import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/firebase_service.dart';
import '../models/bill_model.dart';

class BillingProvider with ChangeNotifier {
  final FirebaseService _service = FirebaseService();

  // Cart maps Product → quantity added (in the product's own unit)
  // e.g. Product(rice, kg) → 1.5  means 1.5 kg added
  Map<Product, double> cart = {};

  // ─── Cart Operations ───────────────────────────────────────────

  /// Add one step of this product's unit (e.g. +0.5kg, +100g, +1pcs)
  void addToCart(Product product) {
    final step = product.unit.cartStep;
    final currentQty = cart[product] ?? 0.0;
    final newQty = _round(currentQty + step);
    if (newQty > product.quantity) return;
    cart.update(product, (_) => newQty, ifAbsent: () => step);
    notifyListeners();
  }

  /// Remove one step. Removes item if qty goes to 0 or below.
  void decrementFromCart(Product product) {
    if (!cart.containsKey(product)) return;
    final step = product.unit.cartStep;
    final newQty = _round((cart[product] ?? 0.0) - step);
    if (newQty <= 0) {
      cart.remove(product);
    } else {
      cart[product] = newQty;
    }
    notifyListeners();
  }

  /// Set a custom quantity directly (used by custom qty input dialog)
  void setCustomQty(Product product, double qty) {
    if (qty <= 0) {
      cart.remove(product);
    } else {
      final clamped = qty > product.quantity ? product.quantity : qty;
      cart[product] = _round(clamped);
    }
    notifyListeners();
  }

  void removeFromCart(Product product) {
    cart.remove(product);
    notifyListeners();
  }

  void clearCart() {
    cart.clear();
    notifyListeners();
  }

  // ─── Totals ────────────────────────────────────────────────────

  double get total {
    double sum = 0;
    cart.forEach((product, qty) => sum += product.price * qty);
    return sum;
  }

  /// Number of distinct product lines in cart (for badge)
  int get itemCount => cart.length;

  // ─── Confirm Bill ──────────────────────────────────────────────

  Future<void> confirmBill() async {
    try {
      final bill = Bill(id: '', total: total, date: DateTime.now());
      final cartSnapshot = Map<Product, double>.from(cart);

      cart.clear();
      notifyListeners();

      for (final entry in cartSnapshot.entries) {
        final newQty = _round(entry.key.quantity - entry.value);
        _service.updateProductQuantity(entry.key.id, newQty);
      }

      _service.addBill(bill);
    } catch (e) {
      rethrow;
    }
  }

  // ─── Helper ────────────────────────────────────────────────────

  double _round(double value) => (value * 1000).round() / 1000;
}