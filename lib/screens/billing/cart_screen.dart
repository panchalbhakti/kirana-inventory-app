import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/billing_provider.dart';
import '../../models/product_model.dart';
import 'payment_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final billing = context.watch<BillingProvider>();
    final entries = billing.cart.entries.toList();

    return Scaffold(
      backgroundColor: K.bg,
      body: SafeArea(child: Column(children: [
        // ── Header ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(children: [
            const KBack(),
            const Spacer(),
            if (entries.isNotEmpty)
              GestureDetector(
                onTap: () => _confirmClear(context, billing),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: K.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(K.r1),
                    border: Border.all(color: K.red.withOpacity(0.2)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.delete_outline_rounded, color: K.red, size: 14),
                    SizedBox(width: 5),
                    Text('Clear', style: TextStyle(fontSize: 13, color: K.red, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(children: [
            const Text('My Cart', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: K.t1, letterSpacing: -0.5)),
            const SizedBox(width: 10),
            if (entries.isNotEmpty) Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('${billing.itemCount} item${billing.itemCount == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 14, color: K.t2)),
            ),
          ]),
        ),

        const SizedBox(height: 16),

        // ── Items ────────────────────────────────────────────
        Expanded(
          child: entries.isEmpty
              ? _emptyState(context)
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: entries.length,
            itemBuilder: (_, i) => _CartItem(
              product: entries[i].key,
              qty: entries[i].value,
              billing: billing,
            ),
          ),
        ),

        // ── Summary ──────────────────────────────────────────
        if (entries.isNotEmpty) _Summary(billing: billing),
      ])),
    );
  }

  void _confirmClear(BuildContext ctx, BillingProvider billing) {
    showDialog(context: ctx, builder: (_) => AlertDialog(
      backgroundColor: K.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(K.r3)),
      title: const Text('Clear Cart', style: TextStyle(color: K.t1, fontWeight: FontWeight.w600)),
      content: const Text('Remove all items from your cart?', style: TextStyle(color: K.t2, fontSize: 14)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: K.t2))),
        TextButton(onPressed: () { billing.clearCart(); Navigator.pop(ctx); },
            child: const Text('Clear', style: TextStyle(color: K.red, fontWeight: FontWeight.w600))),
      ],
    ));
  }

  Widget _emptyState(BuildContext ctx) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 80, height: 80,
        decoration: BoxDecoration(color: K.surfaceEl, shape: BoxShape.circle),
        child: const Icon(Icons.shopping_cart_outlined, color: K.t3, size: 38)),
    const SizedBox(height: 18),
    const Text('Your cart is empty', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: K.t1)),
    const SizedBox(height: 6),
    const Text('Add products from the Billing screen', style: TextStyle(fontSize: 13, color: K.t2)),
    const SizedBox(height: 22),
    GestureDetector(
      onTap: () => Navigator.pop(ctx),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(color: K.green.withOpacity(0.1), borderRadius: BorderRadius.circular(100),
            border: Border.all(color: K.green.withOpacity(0.3))),
        child: const Text('Browse Products', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: K.green)),
      ),
    ),
  ]));
}

class _CartItem extends StatelessWidget {
  final Product product;
  final double qty;
  final BillingProvider billing;
  const _CartItem({required this.product, required this.qty, required this.billing});

  @override
  Widget build(BuildContext context) {
    final total = product.price * qty;
    final atMin = qty <= product.unit.minQty;
    final atMax = qty >= product.quantity;

    return Dismissible(
      key: Key(product.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: K.red.withOpacity(0.1), borderRadius: BorderRadius.circular(K.r3)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.delete_rounded, color: K.red, size: 22),
          const SizedBox(height: 4),
          const Text('Remove', style: TextStyle(fontSize: 10, color: K.red, fontWeight: FontWeight.w600)),
        ]),
      ),
      onDismissed: (_) => billing.removeFromCart(product),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(K.md),
        decoration: BoxDecoration(
          color: K.surface,
          borderRadius: BorderRadius.circular(K.r3),
          border: Border.all(color: K.b1),
        ),
        child: Row(children: [
          Container(width: 46, height: 46,
              decoration: BoxDecoration(color: K.green.withOpacity(0.07), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.shopping_bag_outlined, color: K.green, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(product.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: K.t1), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(product.priceDisplay, style: const TextStyle(fontSize: 12, color: K.t2)),
          ])),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('₹${total.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: K.green)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: K.surfaceEl, borderRadius: BorderRadius.circular(K.r1)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _qtyBtn(atMin ? Icons.delete_outline_rounded : Icons.remove_rounded,
                    atMin ? K.red : K.t2, () => billing.decrementFromCart(product)),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(_fmtQty(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: K.t1))),
                _qtyBtn(Icons.add_rounded, atMax ? K.t3 : K.green, atMax ? null : () => billing.addToCart(product)),
              ]),
            ),
          ]),
        ]),
      ),
    );
  }

  String _fmtQty() {
    if (product.unit == ProductUnit.pcs) return '${qty.toInt()}';
    if (qty == qty.truncateToDouble()) return '${qty.toInt()} ${product.unit.label}';
    return '${qty.toStringAsFixed(1)} ${product.unit.label}';
  }

  Widget _qtyBtn(IconData icon, Color color, VoidCallback? onTap) {
    return GestureDetector(onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(8), child: Icon(icon, color: color, size: 15)));
  }
}

class _Summary extends StatelessWidget {
  final BillingProvider billing;
  const _Summary({required this.billing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: K.surface,
        border: Border(top: BorderSide(color: K.b1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: Column(children: [
        _row('Subtotal', '₹${billing.total.toStringAsFixed(2)}', K.t2),
        const SizedBox(height: 6),
        _row('Discount', '₹0.00', K.t3),
        const SizedBox(height: 12),
        Divider(color: K.b2, height: 1),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: K.t1)),
          Text('₹${billing.total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: K.green, letterSpacing: -0.5)),
        ]),
        const SizedBox(height: 16),
        KBtn(
          label: 'Proceed to Payment',
          icon: Icons.payment_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentScreen(total: billing.total))),
        ),
      ]),
    );
  }

  Widget _row(String l, String v, Color c) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(l, style: const TextStyle(fontSize: 13, color: K.t2)),
    Text(v, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: c)),
  ]);
}