import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/product_provider.dart';
import '../../models/product_model.dart';
import 'add_product_screen.dart';
import 'scan_product_screen.dart';

class ProductListScreen extends StatefulWidget {
  final bool embedded;
  const ProductListScreen({super.key, this.embedded = false});
  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String _query = '';
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    provider.init();
    final products = _query.isEmpty
        ? provider.products
        : provider.products.where((p) => p.name.toLowerCase().contains(_query.toLowerCase())).toList();

    return SafeArea(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (!widget.embedded) const KBack(),
              if (!widget.embedded) const SizedBox(height: 8),
              const Text('Inventory', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: K.t1, letterSpacing: -0.5)),
              Text('${provider.products.length} products', style: const TextStyle(fontSize: 13, color: K.t2)),
            ]),
            Row(children: [
              _iconBtn(Icons.document_scanner_rounded, K.blue, () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => ScanProductScreen()))),
              const SizedBox(width: 10),
              _iconBtn(Icons.add_rounded, K.green, () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => AddProductScreen())),
                  iconColor: Colors.black),
            ]),
          ]),
        ),

        const SizedBox(height: 16),

        // ── Search ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(color: K.surfaceEl,
                borderRadius: BorderRadius.circular(K.r2), border: Border.all(color: K.b2)),
            child: TextField(
              controller: _ctrl,
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(color: K.t1, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: const TextStyle(color: K.t3, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: K.t3, size: 18),
                suffixIcon: _query.isNotEmpty ? GestureDetector(onTap: () { _ctrl.clear(); setState(() => _query = ''); },
                    child: const Icon(Icons.close_rounded, color: K.t3, size: 16)) : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── List ────────────────────────────────────────────
        Expanded(
          child: products.isEmpty
              ? _emptyState()
              : ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            itemCount: products.length,
            itemBuilder: (_, i) => _ProductTile(product: products[i]),
          ),
        ),
      ]),
    );
  }

  Widget _iconBtn(IconData icon, Color bg, VoidCallback onTap, {Color? iconColor}) =>
      GestureDetector(onTap: onTap,
          child: Container(width: 42, height: 42,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(K.r2)),
              child: Icon(icon, color: iconColor ?? Colors.white, size: 20)));

  Widget _emptyState() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 72, height: 72,
        decoration: BoxDecoration(color: K.surfaceEl, borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.inventory_2_outlined, color: K.t3, size: 34)),
    const SizedBox(height: 16),
    Text(_query.isNotEmpty ? 'No products found' : 'Your shelf is empty',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: K.t1)),
    const SizedBox(height: 6),
    Text(_query.isNotEmpty ? 'Try a different search' : 'Tap + to add your first product',
        style: const TextStyle(fontSize: 13, color: K.t2)),
  ]));
}

class _ProductTile extends StatelessWidget {
  final Product product;
  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final lowStock = product.quantity <= 5 && product.quantity > 0;
    final outOfStock = product.quantity <= 0;
    final stockColor = outOfStock ? K.red : lowStock ? K.amber : K.t2;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(K.md),
      decoration: BoxDecoration(
        color: K.surface,
        borderRadius: BorderRadius.circular(K.r3),
        border: Border.all(color: outOfStock ? K.red.withOpacity(0.2) : lowStock ? K.amber.withOpacity(0.2) : K.b1),
      ),
      child: Row(children: [
        Container(width: 44, height: 44,
            decoration: BoxDecoration(color: K.green.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.shopping_bag_outlined, color: K.green, size: 20)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(product.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: K.t1)),
          const SizedBox(height: 4),
          Row(children: [
            Text(product.priceDisplay, style: const TextStyle(fontSize: 13, color: K.green, fontWeight: FontWeight.w600)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: stockColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: stockColor.withOpacity(0.25)),
              ),
              child: Text(
                outOfStock ? 'Out of stock' : product.quantityDisplay,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: stockColor),
              ),
            ),
          ]),
        ])),
        GestureDetector(
          onTap: () => _confirmDelete(context),
          child: Container(width: 34, height: 34,
              decoration: BoxDecoration(color: K.red.withOpacity(0.08), borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.delete_outline_rounded, color: K.red, size: 17)),
        ),
      ]),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: K.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(K.r3)),
      title: const Text('Delete Product', style: TextStyle(color: K.t1, fontWeight: FontWeight.w600)),
      content: Text('Remove "${product.name}" from inventory?', style: const TextStyle(color: K.t2, fontSize: 14)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: K.t2))),
        TextButton(onPressed: () {
          context.read<ProductProvider>().deleteProduct(product.id);
          Navigator.pop(context);
        }, child: const Text('Delete', style: TextStyle(color: K.red, fontWeight: FontWeight.w600))),
      ],
    ));
  }
}