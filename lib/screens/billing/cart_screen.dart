import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/billing_provider.dart';
import '../../models/product_model.dart';
import 'payment_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final billing = context.watch<BillingProvider>();
    final cartEntries = billing.cart.entries.toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  if (cartEntries.isNotEmpty)
                    GestureDetector(
                      onTap: () => _showClearDialog(context, billing),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE74C3C).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color:
                              const Color(0xFFE74C3C).withOpacity(0.25)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.delete_outline_rounded,
                                color: Color(0xFFE74C3C), size: 15),
                            SizedBox(width: 5),
                            Text('Clear',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFE74C3C))),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'My Cart',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      '${billing.itemCount} item${billing.itemCount == 1 ? '' : 's'}',
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.35),
                          fontWeight: FontWeight.w400),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Cart Items ─────────────────────────────────────────
            Expanded(
              child: cartEntries.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: cartEntries.length,
                itemBuilder: (context, i) {
                  final product = cartEntries[i].key;
                  final qty = cartEntries[i].value;
                  return _CartItemCard(
                      product: product, qty: qty, billing: billing);
                },
              ),
            ),

            // ── Order Summary + Proceed ───────────────────────────
            if (cartEntries.isNotEmpty) _buildSummarySection(context, billing),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shopping_cart_outlined,
                color: Colors.white.withOpacity(0.15), size: 44),
          ),
          const SizedBox(height: 20),
          const Text('Your cart is empty',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
          const SizedBox(height: 8),
          Text('Add products from the billing screen',
              style: TextStyle(
                  fontSize: 13, color: Colors.white.withOpacity(0.3))),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2ECC71).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF2ECC71).withOpacity(0.3)),
              ),
              child: const Text('Browse Products',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2ECC71))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(
      BuildContext context, BillingProvider billing) {
    final subtotal = billing.total;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.07)),
        ),
      ),
      child: Column(
        children: [
          // Summary rows
          _summaryRow('Subtotal',
              '₹${subtotal.toStringAsFixed(2)}', Colors.white.withOpacity(0.55)),
          const SizedBox(height: 8),
          _summaryRow('Discount', '₹0.00', Colors.white.withOpacity(0.35)),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF2A2A2A), height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              Text(
                '₹${subtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2ECC71),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Proceed to Payment Button
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 350),
                pageBuilder: (_, __, ___) => PaymentScreen(total: subtotal),
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
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2ECC71).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payment_rounded, color: Colors.black, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Proceed to Payment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13, color: Colors.white.withOpacity(0.45))),
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500, color: valueColor)),
      ],
    );
  }

  void _showClearDialog(BuildContext context, BillingProvider billing) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Cart',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        content: Text('Remove all items from your cart?',
            style:
            TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.55))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: Colors.white.withOpacity(0.45))),
          ),
          TextButton(
            onPressed: () {
              billing.clearCart();
              Navigator.pop(context);
            },
            child: const Text('Clear',
                style: TextStyle(
                    color: Color(0xFFE74C3C),
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─── Cart Item Card ──────────────────────────────────────────────────────────

class _CartItemCard extends StatelessWidget {
  final Product product;
  final int qty;
  final BillingProvider billing;

  const _CartItemCard({
    required this.product,
    required this.qty,
    required this.billing,
  });

  @override
  Widget build(BuildContext context) {
    final itemTotal = product.price * qty;

    return Dismissible(
      key: Key(product.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE74C3C).withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_rounded, color: Color(0xFFE74C3C), size: 24),
            SizedBox(height: 4),
            Text('Remove',
                style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFE74C3C),
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
      onDismissed: (_) => billing.removeFromCart(product),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF2ECC71).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.shopping_bag_outlined,
                  color: Color(0xFF2ECC71), size: 22),
            ),
            const SizedBox(width: 12),

            // Name & unit price
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${product.price} per unit',
                    style: TextStyle(
                        fontSize: 12, color: Colors.white.withOpacity(0.35)),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Qty controls + total
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${itemTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2ECC71)),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF252525),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _qtyButton(
                        icon: qty <= 1
                            ? Icons.delete_outline_rounded
                            : Icons.remove_rounded,
                        color: qty <= 1
                            ? const Color(0xFFE74C3C)
                            : Colors.white.withOpacity(0.6),
                        onTap: () => billing.decrementFromCart(product),
                      ),
                      Padding(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '$qty',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ),
                      _qtyButton(
                        icon: Icons.add_rounded,
                        color: qty >= product.quantity
                            ? Colors.white.withOpacity(0.2)
                            : const Color(0xFF3498DB),
                        onTap: qty >= product.quantity
                            ? null
                            : () => billing.addToCart(product),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyButton({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}