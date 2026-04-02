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
  bool _isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    qtyController.dispose();
    super.dispose();
  }

  void _save() async {
    final productProvider = context.read<ProductProvider>();
    final subProvider = context.read<SubscriptionProvider>();

    // Check product limit
    if (!productProvider.canAddProduct(subProvider.isPro)) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
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
                  TextStyle(color: Colors.white.withOpacity(0.45))),
            ),
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
      return;
    }

    final name = nameController.text.trim();
    final priceText = priceController.text.trim();
    final qtyText = qtyController.text.trim();

    if (name.isEmpty || priceText.isEmpty || qtyText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          content: const Text('Please fill in all fields',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      );
      return;
    }

    final price = double.tryParse(priceText);
    final qty = int.tryParse(qtyText);

    if (price == null || qty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          content: const Text('Enter valid price and quantity',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final product = Product(
      id: '',
      name: name,
      price: price,
      quantity: qty,
    );

    try {
      await context.read<ProductProvider>().addProduct(product);
      if (!context.mounted) return;
      setState(() => _isLoading = false);
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          content: Text('Error: ${e.toString()}',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      );
    }
  }

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
                  color: Colors.white,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(
                'Fill in the details below',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.35),
                ),
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
                              : 'Free limit reached! Upgrade to Pro for unlimited products.',
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
                            child: const Text(
                              'Upgrade',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
                  children: [
                    _inputField(
                      controller: nameController,
                      label: 'Product Name',
                      hint: 'e.g. Basmati Rice',
                      icon: Icons.shopping_bag_rounded,
                      inputType: TextInputType.text,
                    ),
                    const SizedBox(height: 16),
                    _inputField(
                      controller: priceController,
                      label: 'Price (₹)',
                      hint: 'e.g. 120.00',
                      icon: Icons.currency_rupee_rounded,
                      inputType: const TextInputType.numberWithOptions(
                          decimal: true),
                      formatter: FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ),
                    const SizedBox(height: 16),
                    _inputField(
                      controller: qtyController,
                      label: 'Quantity',
                      hint: 'e.g. 50',
                      icon: Icons.layers_rounded,
                      inputType: TextInputType.number,
                      formatter: FilteringTextInputFormatter.digitsOnly,
                    ),
                    const SizedBox(height: 40),

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
                        ),
                        child: _isLoading
                            ? const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                              AlwaysStoppedAnimation<Color>(
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
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
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
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.55),
          ),
        ),
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
            inputFormatters: formatter != null ? [formatter] : [],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.2),
                fontSize: 14,
              ),
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