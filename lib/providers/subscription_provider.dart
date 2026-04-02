import 'package:flutter/material.dart';
import '../models/subscription_model.dart';
import '../services/subscription_service.dart';

class SubscriptionProvider with ChangeNotifier {
  final SubscriptionService _service = SubscriptionService();
  Subscription _subscription = Subscription.free();

  Subscription get subscription => _subscription;
  bool get isPro => _subscription.isPro;

  void init() {
    _service.getSubscription().listen((sub) {
      _subscription = sub;
      notifyListeners();
    });
  }
}