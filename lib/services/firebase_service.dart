import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/bill_model.dart';
import '../models/customer_model.dart';

class FirebaseService {
  final _db = FirebaseFirestore.instance;

  // ─── STORE SETTINGS ────────────────────────────────────────────

  Future<void> updateStoreName(String name) async {
    _db.collection('settings').doc('store').set({'name': name});
  }

  Stream<String> getStoreName() {
    return _db.collection('settings').doc('store').snapshots().map((doc) {
      return doc.exists ? (doc['name'] ?? 'Kirana Store') : 'Kirana Store';
    });
  }

  // ─── PRODUCTS ──────────────────────────────────────────────────

  Future<void> addProduct(Product product) async {
    _db.collection('products').add(product.toMap());
  }

  Stream<List<Product>> getProducts() {
    return _db.collection('products').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> deleteProduct(String id) async {
    _db.collection('products').doc(id).delete();
  }

  /// Quantity is now double to support kg, g, litre, ml, etc.
  Future<void> updateProductQuantity(String id, double newQuantity) async {
    _db.collection('products').doc(id).update({'quantity': newQuantity});
  }

  // ─── BILLS ─────────────────────────────────────────────────────

  Future<void> addBill(Bill bill) async {
    _db.collection('bills').add(bill.toMap());
  }

  Stream<List<Bill>> getBills() {
    return _db.collection('bills').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Bill(
        id: doc.id,
        total: (doc['total'] as num).toDouble(),
        date: DateTime.parse(doc['date']),
      ))
          .toList();
    });
  }

  // ─── CUSTOMERS ─────────────────────────────────────────────────

  Future<void> addCustomer(Customer customer) async {
    _db.collection('customers').add(customer.toMap());
  }

  Stream<List<Customer>> getCustomers() {
    return _db.collection('customers').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Customer.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Stream<List<Customer>> getCustomerById(String id) {
    return _db
        .collection('customers')
        .where(FieldPath.documentId, isEqualTo: id)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Customer.fromMap(doc.id, doc.data()))
        .toList());
  }

  Future<void> recordPayment(String customerId, double amount) async {
    _db.collection('customers').doc(customerId).update({
      'totalPaid': FieldValue.increment(amount),
    });
  }

  Future<void> addMoreCredit(String customerId, double amount) async {
    _db.collection('customers').doc(customerId).update({
      'totalCredit': FieldValue.increment(amount),
    });
  }

  Future<void> deleteCustomer(String id) async {
    _db.collection('customers').doc(id).delete();
  }
}