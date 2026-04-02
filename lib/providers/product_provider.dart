import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/firebase_service.dart';

class ProductProvider with ChangeNotifier {
  final FirebaseService _service = FirebaseService();

  List<Product> products = [];
  bool isInitialized = false;

  static const int freeLimit = 20;

  bool canAddProduct(bool isPro) {
    if (isPro) return true;
    return products.length < freeLimit;
  }

  int get remainingFreeSlots => freeLimit - products.length;

  void init() {
    if (isInitialized) return;
    _service.getProducts().listen((data) {
      products = data;
      notifyListeners();
    });
    isInitialized = true;
  }

  Future<void> addProduct(Product p) async {
    products.add(p);
    notifyListeners();
    _service.addProduct(p);
  }

  Future<void> deleteProduct(String id) async {
    products.removeWhere((p) => p.id == id);
    notifyListeners();
    _service.deleteProduct(id);
  }
}