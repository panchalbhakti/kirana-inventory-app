import 'package:flutter/material.dart';
import '../models/product_model.dart';

class BillItemTile extends StatelessWidget {
  final Product product;
  final int qty;

  const BillItemTile({required this.product, required this.qty});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF3498DB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.shopping_cart_rounded,
              color: Color(0xFF3498DB),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              product.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${(product.price * qty).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2ECC71),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$qty x ₹${product.price}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.35),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}