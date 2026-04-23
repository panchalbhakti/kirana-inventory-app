import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../models/customer_model.dart';
import '../../services/firebase_service.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;
  const CustomerDetailScreen({super.key, required this.customer});
  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final _payCtrl = TextEditingController();
  final _creditCtrl = TextEditingController();

  @override
  void dispose() { _payCtrl.dispose(); _creditCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: K.bg,
      body: SafeArea(child: Column(children: [
        // ── Header ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(children: [
            const KBack(),
            const Spacer(),
            GestureDetector(
              onTap: () => _confirmDelete(context),
              child: Container(width: 36, height: 36,
                  decoration: BoxDecoration(color: K.red.withOpacity(0.08), borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: K.red.withOpacity(0.2))),
                  child: const Icon(Icons.delete_outline_rounded, color: K.red, size: 17)),
            ),
          ]),
        ),

        // ── Customer Identity ─────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(children: [
            Container(width: 56, height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [K.green.withOpacity(0.3), K.green.withOpacity(0.1)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(child: Text(widget.customer.name[0].toUpperCase(),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: K.green)))),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.customer.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: K.t1)),
              Text(widget.customer.phone, style: const TextStyle(fontSize: 14, color: K.t2)),
            ]),
          ]),
        ),

        const SizedBox(height: 20),

        Expanded(child: StreamBuilder<List<Customer>>(
          stream: FirebaseService().getCustomerById(widget.customer.id),
          builder: (ctx, snap) {
            final c = snap.hasData && snap.data!.isNotEmpty ? snap.data!.first : widget.customer;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(children: [
                // ── Stats ──────────────────────────────────
                Row(children: [
                  KStat(label: 'Total Credit', value: '₹${c.totalCredit.toStringAsFixed(0)}', color: K.red),
                  const SizedBox(width: 12),
                  KStat(label: 'Total Paid', value: '₹${c.totalPaid.toStringAsFixed(0)}', color: K.green),
                ]),
                const SizedBox(height: 12),

                // ── Outstanding ────────────────────────────
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(K.md+4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: c.outstanding > 0
                          ? [K.amber.withOpacity(0.08), K.amber.withOpacity(0.03)]
                          : [K.green.withOpacity(0.08), K.green.withOpacity(0.03)],
                    ),
                    borderRadius: BorderRadius.circular(K.r3),
                    border: Border.all(color: c.outstanding > 0 ? K.amber.withOpacity(0.25) : K.green.withOpacity(0.25)),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Outstanding Balance', style: TextStyle(fontSize: 12, color: K.t2)),
                      const SizedBox(height: 6),
                      Text('₹${c.outstanding.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.5,
                              color: c.outstanding > 0 ? K.amber : K.green)),
                    ]),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: c.outstanding > 0 ? K.amber.withOpacity(0.1) : K.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                          c.outstanding > 0 ? Icons.account_balance_wallet_rounded : Icons.check_circle_rounded,
                          color: c.outstanding > 0 ? K.amber : K.green, size: 28),
                    ),
                  ]),
                ),

                const SizedBox(height: 24),

                // ── Record Payment ─────────────────────────
                const Align(alignment: Alignment.centerLeft, child: KLabel('Record Payment')),
                const SizedBox(height: 12),
                KField(controller: _payCtrl, label: 'Payment Amount', hint: 'e.g. 200.00',
                    icon: Icons.payments_rounded, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    formatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))]),
                const SizedBox(height: 12),
                KBtn(label: 'Record Payment', icon: Icons.check_rounded, onTap: () => _recordPayment(ctx)),

                const SizedBox(height: 24),

                // ── Add Credit ─────────────────────────────
                const Align(alignment: Alignment.centerLeft, child: KLabel('Add More Credit')),
                const SizedBox(height: 12),
                KField(controller: _creditCtrl, label: 'Credit Amount', hint: 'e.g. 300.00',
                    icon: Icons.add_card_rounded, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    formatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))]),
                const SizedBox(height: 12),
                KBtn(label: 'Add Credit', icon: Icons.add_rounded, danger: false, ghost: true, onTap: () => _addCredit(ctx)),

                const SizedBox(height: 32),
              ]),
            );
          },
        )),
      ])),
    );
  }

  void _recordPayment(BuildContext ctx) {
    final amount = double.tryParse(_payCtrl.text.trim());
    if (amount == null || amount <= 0) { kSnack(ctx, 'Enter a valid amount', ok: false); return; }
    FirebaseService().recordPayment(widget.customer.id, amount);
    _payCtrl.clear();
    kSnack(ctx, '✓ Payment of ₹${amount.toStringAsFixed(0)} recorded!');
  }

  void _addCredit(BuildContext ctx) {
    final amount = double.tryParse(_creditCtrl.text.trim());
    if (amount == null || amount <= 0) { kSnack(ctx, 'Enter a valid amount', ok: false); return; }
    FirebaseService().addMoreCredit(widget.customer.id, amount);
    _creditCtrl.clear();
    kSnack(ctx, '✓ Credit of ₹${amount.toStringAsFixed(0)} added!', ok: false);
  }

  void _confirmDelete(BuildContext ctx) {
    showDialog(context: ctx, builder: (_) => AlertDialog(
      backgroundColor: K.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(K.r3)),
      title: const Text('Delete Customer', style: TextStyle(color: K.t1, fontWeight: FontWeight.w600)),
      content: Text('Remove ${widget.customer.name} from your records?', style: const TextStyle(color: K.t2, fontSize: 14)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: K.t2))),
        TextButton(onPressed: () {
          FirebaseService().deleteCustomer(widget.customer.id);
          Navigator.pop(ctx); Navigator.pop(ctx);
        }, child: const Text('Delete', style: TextStyle(color: K.red, fontWeight: FontWeight.w600))),
      ],
    ));
  }
}