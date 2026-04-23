import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/customer_model.dart';
import '../../services/firebase_service.dart';
import 'add_customer_screen.dart';
import 'customer_detail_screen.dart';

class UdhaarScreen extends StatelessWidget {
  final bool embedded;
  const UdhaarScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final svc = FirebaseService();
    return SafeArea(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (!embedded) const KBack(),
              if (!embedded) const SizedBox(height: 8),
              const Text('Udhaar', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: K.t1, letterSpacing: -0.5)),
              const Text('Customer credit tracker', style: TextStyle(fontSize: 13, color: K.t2)),
            ]),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddCustomerScreen())),
              child: Container(width: 42, height: 42,
                  decoration: BoxDecoration(color: K.green, borderRadius: BorderRadius.circular(K.r2)),
                  child: const Icon(Icons.person_add_rounded, color: Colors.black, size: 20)),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        Expanded(child: StreamBuilder<List<Customer>>(
          stream: svc.getCustomers(),
          builder: (context, snap) {
            final customers = snap.data ?? [];
            if (customers.isEmpty) return _empty(context);

            final totalOutstanding = customers.fold<double>(0, (s, c) => s + c.outstanding);
            final totalCustomers = customers.length;
            final cleared = customers.where((c) => c.outstanding <= 0).length;

            return CustomScrollView(slivers: [
              // ── Summary ──────────────────────────────────
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  KStat(label: 'Total Outstanding', value: '₹${totalOutstanding.toStringAsFixed(0)}', color: K.amber, icon: Icons.account_balance_wallet_rounded),
                  const SizedBox(width: 12),
                  KStat(label: 'Customers', value: '$totalCustomers', color: K.blue, icon: Icons.people_rounded),
                ]),
              )),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  KStat(label: 'Cleared', value: '$cleared', color: K.green, icon: Icons.check_circle_rounded),
                  const SizedBox(width: 12),
                  KStat(label: 'Pending', value: '${totalCustomers - cleared}', color: K.red, icon: Icons.pending_rounded),
                ]),
              )),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              const SliverToBoxAdapter(child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 12), child: KLabel('Customers'))),
              SliverList(delegate: SliverChildBuilderDelegate(
                    (_, i) {
                  final c = customers[i];
                  final cleared = c.outstanding <= 0;
                  return GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerDetailScreen(customer: c))),
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      padding: const EdgeInsets.all(K.md),
                      decoration: BoxDecoration(
                        color: K.surface,
                        borderRadius: BorderRadius.circular(K.r3),
                        border: Border.all(color: cleared ? K.green.withOpacity(0.15) : K.amber.withOpacity(0.18)),
                      ),
                      child: Row(children: [
                        Container(width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: cleared ? K.green.withOpacity(0.1) : K.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(child: Text(c.name[0].toUpperCase(),
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                                    color: cleared ? K.green : K.amber)))),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(c.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: K.t1)),
                          const SizedBox(height: 3),
                          Text(c.phone, style: const TextStyle(fontSize: 12, color: K.t2)),
                        ])),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text('₹${c.outstanding.toStringAsFixed(0)}',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                                  color: cleared ? K.green : K.amber)),
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: cleared ? K.green.withOpacity(0.08) : K.amber.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(cleared ? 'Cleared' : 'Pending',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                    color: cleared ? K.green : K.amber)),
                          ),
                        ]),
                      ]),
                    ),
                  );
                },
                childCount: customers.length,
              )),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ]);
          },
        )),
      ]),
    );
  }

  Widget _empty(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 72, height: 72,
        decoration: BoxDecoration(color: K.surfaceEl, borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.people_outline_rounded, color: K.t3, size: 34)),
    const SizedBox(height: 16),
    const Text('No customers yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: K.t1)),
    const SizedBox(height: 6),
    const Text('Add a customer to track udhaar', style: TextStyle(fontSize: 13, color: K.t2)),
    const SizedBox(height: 20),
    GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddCustomerScreen())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(color: K.green.withOpacity(0.1), borderRadius: BorderRadius.circular(100),
            border: Border.all(color: K.green.withOpacity(0.3))),
        child: const Text('Add First Customer', style: TextStyle(color: K.green, fontWeight: FontWeight.w600, fontSize: 14)),
      ),
    ),
  ]));
}