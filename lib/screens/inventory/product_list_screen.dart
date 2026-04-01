import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/product_card.dart';
import 'add_product_screen.dart';

class ProductListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    provider.init();

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Row(
                          children: [
                            Icon(Icons.arrow_back_ios_rounded,
                                color: Colors.white.withOpacity(0.45), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Back',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.45),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Inventory',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  // Add Button
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 400),
                        pageBuilder: (_, __, ___) => AddProductScreen(),
                        transitionsBuilder: (_, animation, __, child) =>
                            FadeTransition(opacity: animation, child: child),
                      ),
                    ),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2ECC71),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: Colors.black, size: 24),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Product count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '${provider.products.length} products',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.35),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Product List
            Expanded(
              child: provider.products.isEmpty
                  ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        color: Colors.white.withOpacity(0.15), size: 56),
                    const SizedBox(height: 16),
                    Text(
                      'No products yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.3),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap + to add your first product',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: provider.products.length,
                padding: const EdgeInsets.only(bottom: 20),
                itemBuilder: (_, i) =>
                    ProductCard(product: provider.products[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}