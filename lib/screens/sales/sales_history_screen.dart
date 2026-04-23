import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/firebase_service.dart';

class SalesHistoryScreen extends StatelessWidget {
  final bool embedded;
  const SalesHistoryScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (!embedded) const KBack(),
            if (!embedded) const SizedBox(height: 8),
            const Text('Sales History', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: K.t1, letterSpacing: -0.5)),
          ]),
        ),
        const SizedBox(height: 20),
        Expanded(child: StreamBuilder(
          stream: FirebaseService().getBills(),
          builder: (context, snap) {
            final bills = snap.data ?? [];
            if (bills.isEmpty) return _empty();

            final total = bills.fold<double>(0, (s, b) => s + b.total);
            final now = DateTime.now();
            final todayTotal = bills.where((b) => b.date.year==now.year && b.date.month==now.month && b.date.day==now.day)
                .fold<double>(0, (s, b) => s + b.total);

            return CustomScrollView(slivers: [
              // ── Summary cards ──────────────────────────────
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  KStat(label: 'Total Revenue', value: '₹${total.toStringAsFixed(0)}', color: K.green, icon: Icons.payments_rounded),
                  const SizedBox(width: 12),
                  KStat(label: "Today's Revenue", value: '₹${todayTotal.toStringAsFixed(0)}', color: K.blue, icon: Icons.today_rounded),
                ]),
              )),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  KStat(label: 'Total Bills', value: '${bills.length}', color: K.amber, icon: Icons.receipt_long_rounded),
                  const SizedBox(width: 12),
                  KStat(label: 'Avg. Bill Value', value: bills.isEmpty ? '₹0' : '₹${(total/bills.length).toStringAsFixed(0)}',
                      color: K.purple, icon: Icons.analytics_rounded),
                ]),
              )),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              const SliverToBoxAdapter(child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 12), child: KLabel('All Bills'))),
              SliverList(delegate: SliverChildBuilderDelegate(
                    (_, i) {
                  final bill = bills.reversed.toList()[i];
                  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
                  final hh = bill.date.hour > 12 ? bill.date.hour-12 : (bill.date.hour==0?12:bill.date.hour);
                  final mm = bill.date.minute.toString().padLeft(2,'0');
                  final pp = bill.date.hour >= 12 ? 'PM' : 'AM';

                  return Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    padding: const EdgeInsets.all(K.md),
                    decoration: BoxDecoration(
                      color: K.surface,
                      borderRadius: BorderRadius.circular(K.r3),
                      border: Border.all(color: K.b1),
                    ),
                    child: Row(children: [
                      Container(width: 44, height: 44,
                          decoration: BoxDecoration(color: K.green.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.receipt_rounded, color: K.green, size: 20)),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Bill #${bills.length - i}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: K.t1)),
                        const SizedBox(height: 3),
                        Text('${bill.date.day} ${months[bill.date.month-1]} ${bill.date.year}  ·  $hh:$mm $pp',
                            style: const TextStyle(fontSize: 12, color: K.t2)),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: K.green.withOpacity(0.08), borderRadius: BorderRadius.circular(100)),
                        child: Text('₹${bill.total.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: K.green)),
                      ),
                    ]),
                  );
                },
                childCount: bills.length,
              )),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ]);
          },
        )),
      ]),
    );
  }

  Widget _empty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 72, height: 72,
        decoration: BoxDecoration(color: K.surfaceEl, borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.receipt_long_outlined, color: K.t3, size: 34)),
    const SizedBox(height: 16),
    const Text('No sales yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: K.t1)),
    const SizedBox(height: 6),
    const Text('Confirmed bills will appear here', style: TextStyle(fontSize: 13, color: K.t2)),
  ]));
}