import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/subscription_provider.dart';
import '../subscription/subscription_screen.dart';

class AddProductScreen extends StatefulWidget {
  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final qtyController = TextEditingController();

  ProductUnit _selectedUnit = ProductUnit.pcs;
  bool _isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    qtyController.dispose();
    super.dispose();
  }

  // ─── Unit Selector Bottom Sheet ────────────────────────────────

  void _showUnitPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Unit of Measurement',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                'This defines how the product is weighed/counted',
                style: TextStyle(
                    fontSize: 12, color: Colors.white.withOpacity(0.35)),
              ),
              const SizedBox(height: 20),
              ...ProductUnit.values.map((unit) {
                final isSelected = _selectedUnit == unit;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedUnit = unit);
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2ECC71).withOpacity(0.1)
                          : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF2ECC71).withOpacity(0.4)
                            : Colors.white.withOpacity(0.07),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF2ECC71).withOpacity(0.15)
                                : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              unit.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? const Color(0xFF2ECC71)
                                    : Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                unit.displayName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Cart step: ${_stepLabel(unit)}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withOpacity(0.3)),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF2ECC71), size: 20),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  String _stepLabel(ProductUnit unit) {
    switch (unit) {
      case ProductUnit.kg:
        return '+0.5 kg per tap (e.g. 0.5, 1.0, 1.5 kg)';
      case ProductUnit.g:
        return '+100 g per tap (e.g. 100, 200, 500 g)';
      case ProductUnit.litre:
        return '+0.5 L per tap (e.g. 0.5, 1.0, 1.5 L)';
      case ProductUnit.ml:
        return '+100 ml per tap (e.g. 100, 200, 500 ml)';
      case ProductUnit.pcs:
        return '+1 per tap (e.g. 1, 2, 3 pcs)';
    }
  }

  // ─── Save ──────────────────────────────────────────────────────

  void _save() async {
    final productProvider = context.read<ProductProvider>();
    final subProvider = context.read<SubscriptionProvider>();

    if (!productProvider.canAddProduct(subProvider.isPro)) {
      _showUpgradeDialog();
      return;
    }

    final name = nameController.text.trim();
    final priceText = priceController.text.trim();
    final qtyText = qtyController.text.trim();

    if (name.isEmpty || priceText.isEmpty || qtyText.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    final price = double.tryParse(priceText);
    final qty = double.tryParse(qtyText);

    if (price == null || price <= 0) {
      _showError('Enter a valid price');
      return;
    }
    if (qty == null || qty <= 0) {
      _showError('Enter a valid quantity');
      return;
    }

    // Validate unit-specific qty (e.g. kg shouldn't be 0.1)
    if (_selectedUnit == ProductUnit.kg || _selectedUnit == ProductUnit.litre) {
      if (qty < 0.5) {
        _showError(
            'Minimum stock for ${_selectedUnit.label} is 0.5. Use g or ml for smaller amounts.');
        return;
      }
    }
    if (_selectedUnit == ProductUnit.g || _selectedUnit == ProductUnit.ml) {
      if (qty < 100) {
        _showError(
            'Minimum stock for ${_selectedUnit.label} is 100. Use kg or litre for larger amounts.');
        return;
      }
    }

    setState(() => _isLoading = true);

    final product = Product(
      id: '',
      name: name,
      price: price,
      quantity: qty,
      unit: _selectedUnit,
    );

    try {
      await context.read<ProductProvider>().addProduct(product);
      if (!context.mounted) return;
      setState(() => _isLoading = false);
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      setState(() => _isLoading = false);
      _showError('Error: ${e.toString()}');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: const Color(0xFFE74C3C),
      behavior: SnackBarBehavior.floating,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Text(msg,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600)),
    ));
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.workspace_premium_rounded,
                color: Color(0xFFE67E22), size: 22),
            SizedBox(width: 8),
            Text('Upgrade to Pro',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
        content: Text(
          'You have reached the free limit of 20 products. Upgrade to Pro for unlimited products!',
          style: TextStyle(color: Colors.white.withOpacity(0.6)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style:
                  TextStyle(color: Colors.white.withOpacity(0.45)))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 400),
                  pageBuilder: (_, __, ___) => SubscriptionScreen(),
                  transitionsBuilder: (_, animation, __, child) =>
                      FadeTransition(opacity: animation, child: child),
                ),
              );
            },
            child: const Text('Upgrade',
                style: TextStyle(
                    color: Color(0xFFE67E22),
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final subProvider = context.watch<SubscriptionProvider>();
    final canAdd = productProvider.canAddProduct(subProvider.isPro);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Row(
                  children: [
                    Icon(Icons.arrow_back_ios_rounded,
                        color: Colors.white.withOpacity(0.45), size: 14),
                    const SizedBox(width: 4),
                    Text('Back',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.45))),
                  ],
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Text(
                'Add Product',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(
                'Fill in the product details below',
                style: TextStyle(
                    fontSize: 13, color: Colors.white.withOpacity(0.35)),
              ),
            ),

            // Free limit banner
            if (!subProvider.isPro)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: canAdd
                        ? const Color(0xFF2ECC71).withOpacity(0.08)
                        : const Color(0xFFE74C3C).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: canAdd
                          ? const Color(0xFF2ECC71).withOpacity(0.2)
                          : const Color(0xFFE74C3C).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        canAdd
                            ? Icons.info_outline_rounded
                            : Icons.lock_rounded,
                        color: canAdd
                            ? const Color(0xFF2ECC71)
                            : const Color(0xFFE74C3C),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          canAdd
                              ? '${productProvider.remainingFreeSlots} free slots remaining'
                              : 'Free limit reached! Upgrade to Pro.',
                          style: TextStyle(
                            fontSize: 13,
                            color: canAdd
                                ? const Color(0xFF2ECC71)
                                : const Color(0xFFE74C3C),
                          ),
                        ),
                      ),
                      if (!canAdd)
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            PageRouteBuilder(
                              transitionDuration:
                              const Duration(milliseconds: 400),
                              pageBuilder: (_, __, ___) =>
                                  SubscriptionScreen(),
                              transitionsBuilder:
                                  (_, animation, __, child) =>
                                  FadeTransition(
                                      opacity: animation, child: child),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE67E22),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Upgrade',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    _inputField(
                      controller: nameController,
                      label: 'Product Name',
                      hint: 'e.g. Basmati Rice',
                      icon: Icons.shopping_bag_rounded,
                      inputType: TextInputType.text,
                    ),
                    const SizedBox(height: 16),

                    // ── Unit Selector ─────────────────────────────
                    _fieldLabel('Unit of Measurement'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _showUnitPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: const Color(0xFF2ECC71).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2ECC71).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _selectedUnit.label,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2ECC71),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedUnit.displayName,
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            Icon(Icons.keyboard_arrow_down_rounded,
                                color: Colors.white.withOpacity(0.4),
                                size: 22),
                          ],
                        ),
                      ),
                    ),

                    // Unit hint
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 12,
                              color: Colors.white.withOpacity(0.3)),
                          const SizedBox(width: 5),
                          Text(
                            _stepLabel(_selectedUnit),
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.3)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Price — labeled with unit context
                    _inputField(
                      controller: priceController,
                      label: 'Price per ${_selectedUnit.label} (₹)',
                      hint: _selectedUnit == ProductUnit.pcs
                          ? 'e.g. 10.00'
                          : _selectedUnit == ProductUnit.kg
                          ? 'e.g. 80.00 per kg'
                          : _selectedUnit == ProductUnit.g
                          ? 'e.g. 0.08 per g'
                          : 'e.g. 45.00',
                      icon: Icons.currency_rupee_rounded,
                      inputType: const TextInputType.numberWithOptions(
                          decimal: true),
                      formatter: FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,3}')),
                    ),
                    const SizedBox(height: 16),

                    // Quantity — decimal allowed for kg/g/litre/ml
                    _inputField(
                      controller: qtyController,
                      label: 'Stock Quantity (${_selectedUnit.label})',
                      hint: _selectedUnit == ProductUnit.pcs
                          ? 'e.g. 50'
                          : _selectedUnit == ProductUnit.kg
                          ? 'e.g. 25.5 (kg)'
                          : _selectedUnit == ProductUnit.g
                          ? 'e.g. 5000 (g)'
                          : _selectedUnit == ProductUnit.litre
                          ? 'e.g. 10.5 (litres)'
                          : 'e.g. 2000 (ml)',
                      icon: Icons.layers_rounded,
                      inputType: _selectedUnit == ProductUnit.pcs
                          ? TextInputType.number
                          : const TextInputType.numberWithOptions(
                          decimal: true),
                      formatter: _selectedUnit == ProductUnit.pcs
                          ? FilteringTextInputFormatter.digitsOnly
                          : FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,3}')),
                    ),

                    const SizedBox(height: 8),

                    // Quick qty chips for weight/volume units
                    if (_selectedUnit != ProductUnit.pcs) ...[
                      _fieldLabel('QUICK FILL STOCK'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _quickQtyChips(),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Save Button
                    GestureDetector(
                      onTap: _isLoading ? null : _save,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _isLoading
                              ? const Color(0xFF2ECC71).withOpacity(0.6)
                              : const Color(0xFF2ECC71),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: _isLoading
                              ? null
                              : [
                            BoxShadow(
                              color: const Color(0xFF2ECC71)
                                  .withOpacity(0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: _isLoading
                            ? const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.black),
                            ),
                          ),
                        )
                            : const Text(
                          'Save Product',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick qty chips e.g. 1kg, 5kg, 10kg, 25kg ────────────────────────────

  List<Widget> _quickQtyChips() {
    final options = <String>[];
    switch (_selectedUnit) {
      case ProductUnit.kg:
        options.addAll(['1', '2', '5', '10', '25', '50']);
        break;
      case ProductUnit.g:
        options.addAll(['100', '250', '500', '1000', '2000', '5000']);
        break;
      case ProductUnit.litre:
        options.addAll(['0.5', '1', '2', '5', '10', '20']);
        break;
      case ProductUnit.ml:
        options.addAll(['100', '250', '500', '1000', '2000']);
        break;
      case ProductUnit.pcs:
        break;
    }

    return options.map((val) {
      return GestureDetector(
        onTap: () {
          qtyController.text = val;
          setState(() {});
        },
        child: Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: qtyController.text == val
                ? const Color(0xFF2ECC71).withOpacity(0.15)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: qtyController.text == val
                  ? const Color(0xFF2ECC71).withOpacity(0.4)
                  : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Text(
            '$val ${_selectedUnit.label}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: qtyController.text == val
                  ? const Color(0xFF2ECC71)
                  : Colors.white.withOpacity(0.5),
            ),
          ),
        ),
      );
    }).toList();
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Colors.white.withOpacity(0.55),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required TextInputType inputType,
    TextInputFormatter? formatter,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: inputType,
            onChanged: (_) => setState(() {}), // refresh quick chip highlight
            inputFormatters: formatter != null ? [formatter] : [],
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.2), fontSize: 14),
              prefixIcon: Icon(icon,
                  color: const Color(0xFF2ECC71).withOpacity(0.7),
                  size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}