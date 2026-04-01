import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/billing_provider.dart';
import '../../widgets/bill_item_tile.dart';
import 'bill_summary_screen.dart';

class BillingScreen extends StatefulWidget {
  @override
  _BillingScreenState createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>().products;
    final billing = context.watch<BillingProvider>();

    // Filter products based on search query
    final filteredProducts = products
        .where((p) =>
        p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                children: [
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
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
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

            // Search Bar
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
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.25),
                      fontSize: 14,
                    ),
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
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white.withOpacity(0.4),
                        size: 18,
                      ),
                    )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Products Section Label
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
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Product Selection List
            SizedBox(
              height: 200,
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
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'No products found'
                          : 'No products available',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 13),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: filteredProducts.length,
                itemBuilder: (_, i) {
                  final p = filteredProducts[i];
                  final inCart = billing.cart.containsKey(p);
                  final currentQty = billing.cart[p] ?? 0;
                  final isMaxReached = currentQty >= p.quantity;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '₹${p.price}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF2ECC71),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Stock: ${p.quantity}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isMaxReached
                                          ? const Color(0xFFE74C3C)
                                          : Colors.white
                                          .withOpacity(0.35),
                                    ),
                                  ),
                                  if (inCart) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      'Added: $currentQty',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF3498DB),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (isMaxReached) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                SnackBar(
                                  backgroundColor:
                                  const Color(0xFFE74C3C),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(12)),
                                  content: Text(
                                    'Only ${p.quantity} units available for ${p.name}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                              return;
                            }
                            billing.addToCart(p);
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isMaxReached
                                  ? const Color(0xFFE74C3C)
                                  .withOpacity(0.3)
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

            const SizedBox(height: 20),

            // Cart Section Label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CART',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.35),
                      letterSpacing: 1.2,
                    ),
                  ),
                  if (billing.cart.isNotEmpty)
                    GestureDetector(
                      onTap: () => billing.clearCart(),
                      child: Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFFE74C3C).withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Cart Items
            Expanded(
              child: billing.cart.isEmpty
                  ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shopping_cart_outlined,
                        color: Colors.white.withOpacity(0.15),
                        size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Cart is empty',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView(
                children: billing.cart.entries
                    .map((e) =>
                    BillItemTile(product: e.key, qty: e.value))
                    .toList(),
              ),
            ),

            // Total & Proceed
            if (billing.cart.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.06)),
                  ),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Amount',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.45),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${billing.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2ECC71),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        PageRouteBuilder(
                          transitionDuration:
                          const Duration(milliseconds: 400),
                          pageBuilder: (_, __, ___) => BillSummaryScreen(),
                          transitionsBuilder: (_, animation, __, child) =>
                              FadeTransition(
                                  opacity: animation, child: child),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2ECC71),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'Proceed',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}