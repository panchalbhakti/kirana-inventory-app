import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subscription_model.dart';

class SubscriptionService {
  final _db = FirebaseFirestore.instance;

  // Use device ID or a fixed doc for single-store app
  final String _storeId = 'main_store';

  Stream<Subscription> getSubscription() {
    return _db
        .collection('subscriptions')
        .doc(_storeId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return Subscription.free();
      return Subscription.fromMap(doc.data()!);
    });
  }

  Future<Subscription> getSubscriptionOnce() async {
    final doc =
    await _db.collection('subscriptions').doc(_storeId).get();
    if (!doc.exists) return Subscription.free();
    return Subscription.fromMap(doc.data()!);
  }
}