import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../providers/product_provider.dart';
import '../../providers/billing_provider.dart';
import '../../models/product_model.dart';
import 'cart_screen.dart';
import 'dart:io';

class BillingScreen extends StatefulWidget {
  @override
  _BillingScreenState createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isScanning = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Scan & Add to Cart ────────────────────────────────────────

  Future<void> _scanAndAddToCart() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => _isScanning = true);
    final textRecognizer = TextRecognizer();
    final inputImage = InputImage.fromFile(File(picked.path));

    try {
      final RecognizedText recognizedText =
      await textRecognizer.processImage(inputImage);
      final text = recognizedText.text;

      final products = context.read<ProductProvider>().products;
      final billing = context.read<BillingProvider>();

      final words = text
          .toLowerCase()
          .split(RegExp(r'[\s\n,]+'))
          .where((w) => w.length > 2)
          .toList();

      final matched = products.where((product) {
        final productName = product.name.toLowerCase();
        return words.any(
                (word) => productName.contains(word) || word.contains(productName));
      }).toList();

      setState(() => _isScanning = false);

      if (matched.isEmpty) {
        _showSnack('No matching products found. Try a clearer photo!',
            const Color(0xFFE74C3C));
        return;
      }

      if (matched.length == 1) {
        _addMatchedProduct(matched.first, billing);
      } else {
        _showMatchDialog(matched, billing);
      }
    } catch (e) {
      setState(() => _isScanning = false);
      _showSnack('Could not scan image. Please try again.',
          const Color(0xFFE74C3C));
    } finally {
      textRecognizer.close();
    }
  }

  void _addMatchedProduct(Product product, BillingProvider billing) {
    final currentQty = billing.cart[product] ?? 0;
    if (currentQty >= product.quantity) {
      _showSnack('Only ${product.quantity} units available for ${product.name}',
          const Color(0xFFE74C3C));
      return;
    }
    billing.addToCart(product);
    _showSnack('✓ ${product.name} added to cart!', const Color(0xFF2ECC71),
        dark: true);
  }

  void _showSnack(String msg, Color bg, {bool dark = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Text(msg,
          style: TextStyle(
              color: dark ? Colors.black : Colors.white,
              fontWeight: FontWeight.w600)),
    ));
  }

  void _showMatchDialog(List<Product> products, BillingProvider billing) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Text('Multiple matches found',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
            const SizedBox(height: 4),
            Text('Select the product to add to cart',
                style: TextStyle(
                    fontSize: 13, color: Colors.white.withOpacity(0.45))),
            const SizedBox(height: 16),
            ...products.map((p) => GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _addMatchedProduct(p, billing);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF2ECC71).withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2ECC71).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.shopping_bag_rounded,
                          color: Color(0xFF2ECC71), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                          Text('₹${p.price} • Stock: ${p.quantity}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.45))),
                        ],
                      ),
                    ),
                    const Icon(Icons.add_circle_rounded,
                        color: Color(0xFF2ECC71), size: 24),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>().products;
    final billing = context.watch<BillingProvider>();
    final cartCount = billing.itemCount;

    final filteredProducts = products
        .where(
            (p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back
                  GestureDetector(
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

                  Row(
                    children: [
                      // Scan Button
                      GestureDetector(
                        onTap: _isScanning ? null : _scanAndAddToCart,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: _isScanning
                                ? const Color(0xFF3498DB).withOpacity(0.5)
                                : const Color(0xFF3498DB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _isScanning
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          )
                              : const Row(
                            children: [
                              Icon(Icons.document_scanner_rounded,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text('Scan',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white)),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Cart Icon with Badge
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          PageRouteBuilder(
                            transitionDuration:
                            const Duration(milliseconds: 350),
                            pageBuilder: (_, __, ___) => const CartScreen(),
                            transitionsBuilder:
                                (_, animation, __, child) => SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(1.0, 0.0),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic)),
                              child: child,
                            ),
                          ),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: cartCount > 0
                                      ? const Color(0xFF2ECC71)
                                      .withOpacity(0.4)
                                      : Colors.white.withOpacity(0.08),
                                ),
                              ),
                              child: Icon(
                                Icons.shopping_cart_rounded,
                                color: cartCount > 0
                                    ? const Color(0xFF2ECC71)
                                    : Colors.white.withOpacity(0.45),
                                size: 22,
                              ),
                            ),
                            if (cartCount > 0)
                              Positioned(
                                top: -6,
                                right: -6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2ECC71),
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                      minWidth: 20, minHeight: 20),
                                  child: Text(
                                    cartCount > 99 ? '99+' : '$cartCount',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Text(
                'Billing',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Search Bar ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _searchQuery.isNotEmpty
                        ? const Color(0xFF3498DB).withOpacity(0.4)
                        : Colors.white.withOpacity(0.08),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.25), fontSize: 14),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: _searchQuery.isNotEmpty
                          ? const Color(0xFF3498DB)
                          : Colors.white.withOpacity(0.3),
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: Icon(Icons.close_rounded,
                          color: Colors.white.withOpacity(0.4),
                          size: 18),
                    )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Section Label ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SELECT PRODUCTS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.35),
                      letterSpacing: 1.2,
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    Text(
                      '${filteredProducts.length} result${filteredProducts.length == 1 ? '' : 's'}',
                      style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF3498DB).withOpacity(0.8),
                          fontWeight: FontWeight.w500),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ── Product List ──────────────────────────────────────
            Expanded(
              child: filteredProducts.isEmpty
                  ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _searchQuery.isNotEmpty
                          ? Icons.search_off_rounded
                          : Icons.inventory_2_outlined,
                      color: Colors.white.withOpacity(0.15),
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'No products found'
                          : 'No products available',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 14),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: filteredProducts.length,
                itemBuilder: (_, i) {
                  final p = filteredProducts[i];
                  final currentQty = billing.cart[p] ?? 0;
                  final inCart = currentQty > 0;
                  final isMaxReached = currentQty >= p.quantity;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isMaxReached
                            ? const Color(0xFFE74C3C).withOpacity(0.3)
                            : inCart
                            ? const Color(0xFF3498DB)
                            .withOpacity(0.3)
                            : Colors.white.withOpacity(0.06),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Product Icon
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2ECC71)
                                .withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.shopping_bag_outlined,
                              color: Color(0xFF2ECC71), size: 20),
                        ),
                        const SizedBox(width: 12),

                        // Name & Price
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text('₹${p.price}',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF2ECC71),
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 8),
                                  Text('Stock: ${p.quantity}',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: isMaxReached
                                              ? const Color(0xFFE74C3C)
                                              : Colors.white
                                              .withOpacity(0.35))),
                                  if (inCart) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3498DB)
                                            .withOpacity(0.15),
                                        borderRadius:
                                        BorderRadius.circular(6),
                                      ),
                                      child: Text('In cart: $currentQty',
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF3498DB),
                                              fontWeight:
                                              FontWeight.w600)),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Add Button
                        GestureDetector(
                          onTap: () {
                            if (isMaxReached) {
                              _showSnack(
                                  'Only ${p.quantity} units available for ${p.name}',
                                  const Color(0xFFE74C3C));
                              return;
                            }
                            billing.addToCart(p);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isMaxReached
                                  ? const Color(0xFFE74C3C)
                                  .withOpacity(0.3)
                                  : inCart
                                  ? const Color(0xFF2ECC71)
                                  : const Color(0xFF3498DB),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isMaxReached
                                  ? Icons.block_rounded
                                  : Icons.add_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── View Cart Banner (shown when cart has items) ───────
            if (cartCount > 0)
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 350),
                    pageBuilder: (_, __, ___) => const CartScreen(),
                    transitionsBuilder: (_, animation, __, child) =>
                        SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 1.0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                              parent: animation, curve: Curves.easeOutCubic)),
                          child: child,
                        ),
                  ),
                ),
                child: Container(
                  margin:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2ECC71).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$cartCount',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'View Cart',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '₹${billing.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.black, size: 14),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}