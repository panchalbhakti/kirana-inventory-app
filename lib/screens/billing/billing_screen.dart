import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/product_provider.dart';
import '../../providers/billing_provider.dart';
import '../../models/product_model.dart';
import 'cart_screen.dart';
import 'dart:io';

class BillingScreen extends StatefulWidget {
  final bool embedded;
  const BillingScreen({super.key, this.embedded = false});
  @override
  _BillingScreenState createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _scanning = false;

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _scan() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked == null) return;
    setState(() => _scanning = true);
    final recognizer = TextRecognizer();
    try {
      final result = await recognizer.processImage(InputImage.fromFile(File(picked.path)));
      final words = result.text.toLowerCase().split(RegExp(r'[\s\n,]+')).where((w) => w.length > 2).toList();
      final products = context.read<ProductProvider>().products;
      final matched = products.where((p) => words.any((w) =>
      p.name.toLowerCase().contains(w) || w.contains(p.name.toLowerCase()))).toList();
      if (!mounted) return;
      if (matched.isEmpty) { kSnack(context, 'No matching products found', ok: false); return; }
      if (matched.length == 1) { _addToCart(matched.first); return; }
      _showMatchSheet(matched);
    } finally {
      recognizer.close();
      if (mounted) setState(() => _scanning = false);
    }
  }

  void _addToCart(Product p) {
    final billing = context.read<BillingProvider>();
    final current = billing.cart[p] ?? 0.0;
    if (current >= p.quantity) { kSnack(context, 'Only ${p.quantityDisplay} available', ok: false); return; }
    billing.addToCart(p);
    kSnack(context, '${p.name} added to cart ✓');
  }

  void _showMatchSheet(List<Product> products) {
    showModalBottomSheet(
      context: context,
      backgroundColor: K.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(K.r4))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: K.b3, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 14),
          const Text('Multiple matches', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: K.t1)),
          const SizedBox(height: 14),
          ...products.map((p) => GestureDetector(
            onTap: () { Navigator.pop(context); _addToCart(p); },
            child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: K.surfaceEl, borderRadius: BorderRadius.circular(K.r2),
                    border: Border.all(color: K.b2)),
                child: Row(children: [
                  Container(width: 36, height: 36,
                      decoration: BoxDecoration(color: K.green.withOpacity(0.08), borderRadius: BorderRadius.circular(9)),
                      child: const Icon(Icons.shopping_bag_outlined, color: K.green, size: 18)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: K.t1)),
                    Text(p.priceDisplay, style: const TextStyle(fontSize: 12, color: K.green)),
                  ])),
                  const Icon(Icons.add_circle_rounded, color: K.green, size: 22),
                ])),
          )),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>().products;
    final billing = context.watch<BillingProvider>();
    final cartCount = billing.itemCount;
    final filtered = _query.isEmpty ? products : products.where((p) => p.name.toLowerCase().contains(_query.toLowerCase())).toList();

    return SafeArea(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (!widget.embedded) const KBack(),
              if (!widget.embedded) const SizedBox(height: 8),
              const Text('Billing', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: K.t1, letterSpacing: -0.5)),
              const Text('Add products to cart', style: TextStyle(fontSize: 13, color: K.t2)),
            ]),
            Row(children: [
              // Scan
              GestureDetector(
                onTap: _scanning ? null : _scan,
                child: Container(width: 42, height: 42,
                    decoration: BoxDecoration(color: K.blue, borderRadius: BorderRadius.circular(K.r2)),
                    child: _scanning
                        ? const Padding(padding: EdgeInsets.all(11),
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                        : const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 20)),
              ),
              const SizedBox(width: 10),
              // Cart icon with badge
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
                child: Stack(clipBehavior: Clip.none, children: [
                  AnimatedContainer(duration: const Duration(milliseconds: 200),
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: cartCount > 0 ? K.green.withOpacity(0.12) : K.surfaceEl,
                        borderRadius: BorderRadius.circular(K.r2),
                        border: Border.all(color: cartCount > 0 ? K.green.withOpacity(0.4) : K.b2),
                      ),
                      child: Icon(Icons.shopping_cart_rounded, color: cartCount > 0 ? K.green : K.t2, size: 20)),
                  if (cartCount > 0) Positioned(top: -5, right: -5,
                      child: Container(
                          width: 18, height: 18,
                          decoration: const BoxDecoration(color: K.green, shape: BoxShape.circle),
                          child: Center(child: Text('$cartCount',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black))))),
                ]),
              ),
            ]),
          ]),
        ),

        const SizedBox(height: 16),

        // ── Search ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(color: K.surfaceEl, borderRadius: BorderRadius.circular(K.r2), border: Border.all(color: K.b2)),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(color: K.t1, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: const TextStyle(color: K.t3, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: K.t3, size: 18),
                suffixIcon: _query.isNotEmpty ? GestureDetector(onTap: () { _searchCtrl.clear(); setState(() => _query = ''); },
                    child: const Icon(Icons.close_rounded, color: K.t3, size: 16)) : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: KLabel(_query.isEmpty ? 'All Products' : '${filtered.length} Results'),
        ),
        const SizedBox(height: 10),

        // ── Product List ─────────────────────────────────────
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.inventory_2_outlined, color: K.t3, size: 40),
            const SizedBox(height: 12),
            Text(_query.isNotEmpty ? 'No products found' : 'No products in inventory',
                style: const TextStyle(color: K.t2, fontSize: 14)),
          ]))
              : ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final p = filtered[i];
              final inCartQty = billing.cart[p] ?? 0.0;
              final inCart = inCartQty > 0;
              final maxed = inCartQty >= p.quantity;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(K.md),
                decoration: BoxDecoration(
                  color: K.surface,
                  borderRadius: BorderRadius.circular(K.r3),
                  border: Border.all(color: inCart ? K.green.withOpacity(0.25) : K.b1),
                ),
                child: Row(children: [
                  Container(width: 44, height: 44,
                      decoration: BoxDecoration(color: K.green.withOpacity(0.07), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.shopping_bag_outlined, color: K.green, size: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: K.t1)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Text(p.priceDisplay, style: const TextStyle(fontSize: 12, color: K.green, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: maxed ? K.red.withOpacity(0.08) : K.surfaceEl,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text('Stock: ${p.quantityDisplay}',
                            style: TextStyle(fontSize: 10, color: maxed ? K.red : K.t3, fontWeight: FontWeight.w500)),
                      ),
                      if (inCart) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: K.green.withOpacity(0.08), borderRadius: BorderRadius.circular(100)),
                          child: Text(_fmtQty(inCartQty, p.unit),
                              style: const TextStyle(fontSize: 10, color: K.green, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ]),
                  ])),
                  GestureDetector(
                    onTap: () {
                      if (maxed) { kSnack(context, 'Max stock reached for ${p.name}', ok: false); return; }
                      billing.addToCart(p);
                    },
                    child: AnimatedContainer(duration: const Duration(milliseconds: 150),
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: maxed ? K.red.withOpacity(0.1) : inCart ? K.green : K.green,
                          borderRadius: BorderRadius.circular(K.r1),
                        ),
                        child: Icon(maxed ? Icons.block_rounded : Icons.add_rounded,
                            color: maxed ? K.red : Colors.black, size: 18)),
                  ),
                ]),
              );
            },
          ),
        ),

        // ── View Cart Banner ─────────────────────────────────
        if (cartCount > 0)
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF00E68A), Color(0xFF00B86E)]),
                borderRadius: BorderRadius.circular(K.r3),
                boxShadow: [BoxShadow(color: K.green.withOpacity(0.28), blurRadius: 16, offset: const Offset(0, 5))],
              ),
              child: Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                    child: Text('$cartCount', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.black))),
                const SizedBox(width: 12),
                const Text('View Cart', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black)),
                const Spacer(),
                Text('₹${billing.total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.black)),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.black, size: 13),
              ]),
            ),
          ),
      ]),
    );
  }

  String _fmtQty(double qty, ProductUnit unit) {
    if (unit == ProductUnit.pcs) return '${qty.toInt()} in cart';
    final s = qty == qty.truncateToDouble() ? qty.toInt().toString() : qty.toStringAsFixed(1);
    return '$s ${unit.label} in cart';
  }
}