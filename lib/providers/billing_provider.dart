import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/firebase_service.dart';
import '../models/bill_model.dart';

class BillingProvider with ChangeNotifier {
  final FirebaseService _service = FirebaseService();
  Map<Product, int> cart = {};

  void addToCart(Product product) {
    final currentQty = cart[product] ?? 0;

    if (currentQty >= product.quantity) {
      return;
    }

    cart.update(product, (value) => value + 1, ifAbsent: () => 1);
    notifyListeners();
  }

  double get total {
    double sum = 0;
    cart.forEach((product, qty) {
      sum += product.price * qty;
    });
    return sum;
  }

  Future<void> confirmBill() async {
    try {
      final bill = Bill(
        id: '',
        total: total,
        date: DateTime.now(),
      );

      print("Cart items: ${cart.length}");

      // Save cart snapshot before clearing
      final cartSnapshot = Map<Product, int>.from(cart);

      // Clear cart immediately — don't wait for Firebase
      cart.clear();
      notifyListeners();

      // Fire Firebase calls in background without awaiting
      for (final entry in cartSnapshot.entries) {
        final product = entry.key;
        final soldQty = entry.value;
        final newQuantity = product.quantity - soldQty;
        // print("Updating product: ${product.id} | name: ${product.name} | new qty: $newQuantity");
        _service.updateProductQuantity(product.id, newQuantity); // no await
      }

      print("Saving bill...");
      _service.addBill(bill); // no await
      print("Bill saved!");

    } catch (e) {
      print("ERROR in confirmBill: $e");
      rethrow;
    }
  }

  void clearCart() {
    cart.clear();
    notifyListeners();
  }
}