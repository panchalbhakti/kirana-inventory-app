import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/subscription_provider.dart';
import '../subscription/subscription_screen.dart';

class AddProductScreen extends StatefulWidget {
  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  ProductUnit _unit = ProductUnit.pcs;
  bool _loading = false;

  @override
  void dispose() { _nameCtrl.dispose(); _priceCtrl.dispose(); _qtyCtrl.dispose(); super.dispose(); }

  void _pickUnit() {
    showModalBottomSheet(
      context: context,
      backgroundColor: K.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(K.r4))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: K.b3, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Unit of Measurement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: K.t1)),
          const SizedBox(height: 4),
          const Text('Defines how the product is weighed or counted', style: TextStyle(fontSize: 12, color: K.t2)),
          const SizedBox(height: 16),
          ...ProductUnit.values.map((u) {
            final sel = _unit == u;
            return GestureDetector(
              onTap: () { setState(() => _unit = u); Navigator.pop(context); },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: sel ? K.green.withOpacity(0.08) : K.surfaceEl,
                  borderRadius: BorderRadius.circular(K.r2),
                  border: Border.all(color: sel ? K.green.withOpacity(0.35) : K.b2, width: sel ? 1.5 : 1),
                ),
                child: Row(children: [
                  Container(width: 36, height: 36,
                      decoration: BoxDecoration(
                          color: sel ? K.green.withOpacity(0.12) : K.b2,
                          borderRadius: BorderRadius.circular(9)),
                      child: Center(child: Text(u.label,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: sel ? K.green : K.t2)))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(u.displayName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                        color: sel ? K.t1 : K.t2)),
                    Text(_stepHint(u), style: const TextStyle(fontSize: 11, color: K.t3)),
                  ])),
                  if (sel) const Icon(Icons.check_circle_rounded, color: K.green, size: 20),
                ]),
              ),
            );
          }),
        ]),
      ),
    );
  }

  String _stepHint(ProductUnit u) {
    switch (u) {
      case ProductUnit.kg: return 'Steps: 0.5, 1.0, 1.5 kg...';
      case ProductUnit.g: return 'Steps: 100, 200, 500 g...';
      case ProductUnit.litre: return 'Steps: 0.5, 1.0, 1.5 L...';
      case ProductUnit.ml: return 'Steps: 100, 200, 500 ml...';
      case ProductUnit.pcs: return 'Steps: 1, 2, 3 pcs...';
    }
  }

  void _save() async {
    final pp = context.read<ProductProvider>();
    final sp = context.read<SubscriptionProvider>();
    if (!pp.canAddProduct(sp.isPro)) { _showUpgrade(); return; }

    final name = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim());
    final qty = double.tryParse(_qtyCtrl.text.trim());

    if (name.isEmpty || price == null || qty == null) {
      kSnack(context, 'Please fill all fields', ok: false); return;
    }
    if (price <= 0 || qty <= 0) { kSnack(context, 'Price and quantity must be positive', ok: false); return; }

    setState(() => _loading = true);
    try {
      await pp.addProduct(Product(id: '', name: name, price: price, quantity: qty, unit: _unit));
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      kSnack(context, 'Error: $e', ok: false);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showUpgrade() {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: K.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(K.r3)),
      title: const Row(children: [
        Icon(Icons.workspace_premium_rounded, color: K.amber, size: 22),
        SizedBox(width: 8),
        Text('Upgrade to Pro', style: TextStyle(color: K.t1, fontWeight: FontWeight.w600)),
      ]),
      content: const Text('You have reached the free limit of 20 products. Upgrade to Pro for unlimited products.',
          style: TextStyle(color: K.t2, fontSize: 14)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: K.t2))),
        TextButton(onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => SubscriptionScreen())); },
            child: const Text('Upgrade', style: TextStyle(color: K.amber, fontWeight: FontWeight.w700))),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SubscriptionProvider>();
    final pp = context.watch<ProductProvider>();
    final canAdd = pp.canAddProduct(sp.isPro);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: K.bg,
      body: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const KBack(),
            const SizedBox(height: 12),
            const Text('Add Product', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: K.t1, letterSpacing: -0.5)),
            const Text('Fill in the product details', style: TextStyle(fontSize: 13, color: K.t2)),
          ]),
        ),
        const SizedBox(height: 16),

        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const ClampingScrollPhysics(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Free plan banner — inside scroll so it doesn't steal fixed height
            if (!sp.isPro) Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: canAdd ? K.green.withOpacity(0.06) : K.red.withOpacity(0.06),
                borderRadius: BorderRadius.circular(K.r2),
                border: Border.all(color: canAdd ? K.green.withOpacity(0.18) : K.red.withOpacity(0.18)),
              ),
              child: Row(children: [
                Icon(canAdd ? Icons.info_outline_rounded : Icons.lock_rounded,
                    color: canAdd ? K.green : K.red, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(canAdd ? '${pp.remainingFreeSlots} free slots remaining' : 'Free limit reached — upgrade to Pro',
                    style: TextStyle(fontSize: 12, color: canAdd ? K.green : K.red, fontWeight: FontWeight.w500))),
                if (!canAdd) GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubscriptionScreen())),
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: K.amber, borderRadius: BorderRadius.circular(8)),
                      child: const Text('Upgrade', style: TextStyle(fontSize: 11, color: Colors.black, fontWeight: FontWeight.w700))),
                ),
              ]),
            ),

            KField(controller: _nameCtrl, label: 'Product Name', hint: 'e.g. Basmati Rice', icon: Icons.shopping_bag_rounded),
            const SizedBox(height: 16),

            // Unit selector
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Unit of Measurement', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: K.t2)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickUnit,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: K.surfaceEl, borderRadius: BorderRadius.circular(K.r2),
                      border: Border.all(color: K.green.withOpacity(0.3))),
                  child: Row(children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: K.green.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                        child: Text(_unit.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: K.green))),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_unit.displayName, style: const TextStyle(fontSize: 14, color: K.t1))),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: K.t2, size: 20),
                  ]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 6, 0, 0),
                child: Text(_stepHint(_unit), style: const TextStyle(fontSize: 11, color: K.t3)),
              ),
            ]),

            const SizedBox(height: 16),

            KField(controller: _priceCtrl, label: 'Price per ${_unit.label} (₹)',
                hint: _unit == ProductUnit.pcs ? 'e.g. 10.00' : 'e.g. 80.00',
                icon: Icons.currency_rupee_rounded,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                formatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,3}'))]),

            const SizedBox(height: 16),

            KField(controller: _qtyCtrl, label: 'Stock Quantity (${_unit.label})',
                hint: _unit == ProductUnit.pcs ? 'e.g. 50' : _unit == ProductUnit.kg ? 'e.g. 25.5' : 'e.g. 5000',
                icon: Icons.layers_rounded,
                keyboardType: _unit == ProductUnit.pcs ? TextInputType.number : const TextInputType.numberWithOptions(decimal: true),
                formatters: _unit == ProductUnit.pcs
                    ? [FilteringTextInputFormatter.digitsOnly]
                    : [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,3}'))],
                onChanged: (_) => setState(() {})),

            // Quick fill chips
            if (_unit != ProductUnit.pcs) ...[
              const SizedBox(height: 12),
              const Align(alignment: Alignment.centerLeft,
                  child: Text('QUICK FILL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: K.t3, letterSpacing: 1.2))),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: _quickChips()),
            ],

            const SizedBox(height: 32),
            KBtn(label: 'Save Product', icon: Icons.check_rounded, loading: _loading, onTap: _save),
            const SizedBox(height: 24),
          ]),
        )),
      ])),
    );
  }

  List<Widget> _quickChips() {
    final opts = <String>[];
    switch (_unit) {
      case ProductUnit.kg: opts.addAll(['1','2','5','10','25','50']); break;
      case ProductUnit.g: opts.addAll(['100','250','500','1000','2000']); break;
      case ProductUnit.litre: opts.addAll(['0.5','1','2','5','10']); break;
      case ProductUnit.ml: opts.addAll(['100','250','500','1000']); break;
      case ProductUnit.pcs: break;
    }
    return opts.map((v) {
      final sel = _qtyCtrl.text == v;
      return GestureDetector(
        onTap: () { _qtyCtrl.text = v; setState(() {}); },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: sel ? K.green.withOpacity(0.12) : K.surfaceEl,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: sel ? K.green.withOpacity(0.4) : K.b2),
          ),
          child: Text('$v ${_unit.label}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
              color: sel ? K.green : K.t2)),
        ),
      );
    }).toList();
  }
}