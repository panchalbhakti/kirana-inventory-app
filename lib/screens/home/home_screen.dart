import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../inventory/product_list_screen.dart';
import '../billing/billing_screen.dart';
import '../sales/sales_history_screen.dart';
import '../udhaar/udhaar_screen.dart';
import '../subscription/subscription_screen.dart';

class HomeScreen extends StatelessWidget {
  final FirebaseService _service = FirebaseService();

  final List<Map<String, dynamic>> _menuItems = [
    {
      'title': 'Inventory',
      'subtitle': 'Manage products & stock',
      'icon': Icons.inventory_2_rounded,
      'color': Color(0xFF2ECC71),
    },
    {
      'title': 'Billing',
      'subtitle': 'Create & manage bills',
      'icon': Icons.receipt_long_rounded,
      'color': Color(0xFF3498DB),
    },
    {
      'title': 'Sales',
      'subtitle': 'View sales history',
      'icon': Icons.bar_chart_rounded,
      'color': Color(0xFFE67E22),
    },
    {
      'title': 'Udhaar',
      'subtitle': 'Track customer credits',
      'icon': Icons.account_balance_wallet_rounded,
      'color': Color(0xFF9B59B6),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
        ? 'Good Afternoon'
        : 'Good Evening';

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.45),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      StreamBuilder<String>(
                        stream: _service.getStoreName(),
                        builder: (context, snapshot) {
                          final name = snapshot.data ?? 'Kirana Store';
                          return Text(
                            name,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _showMenu(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: const Icon(
                        Icons.menu_rounded,
                        color: Color(0xFF2ECC71),
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Stats Row
              Row(
                children: [
                  StreamBuilder(
                    stream: _service.getBills(),
                    builder: (context, snapshot) {
                      double todaySales = 0;
                      if (snapshot.hasData) {
                        final today = DateTime.now();
                        final todayBills = snapshot.data!.where((bill) =>
                        bill.date.year == today.year &&
                            bill.date.month == today.month &&
                            bill.date.day == today.day);
                        todaySales = todayBills.fold(
                            0, (sum, bill) => sum + bill.total);
                      }
                      return _statCard(
                        'Today\'s Sales',
                        '₹${todaySales.toStringAsFixed(0)}',
                        const Color(0xFF2ECC71),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  StreamBuilder(
                    stream: _service.getProducts(),
                    builder: (context, snapshot) {
                      final count =
                      snapshot.hasData ? snapshot.data!.length : 0;
                      return _statCard(
                        'Total Products',
                        '$count',
                        const Color(0xFF3498DB),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              Text(
                'Quick Access',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.45),
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: ListView.separated(
                  itemCount: _menuItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _menuItems[index];
                    return _menuCard(context, item);
                  },
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color accentColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.45),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuCard(BuildContext context, Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        Widget screen;
        switch (item['title']) {
          case 'Inventory':
            screen = ProductListScreen();
            break;
          case 'Billing':
            screen = BillingScreen();
            break;
          case 'Sales':
            screen = SalesHistoryScreen();
            break;
          case 'Udhaar':
            screen = UdhaarScreen();
            break;
          default:
            return;
        }
        Navigator.push(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 400),
              pageBuilder: (_, __, ___) => screen,
              transitionsBuilder: (_, animation, __, child) =>
                  FadeTransition(opacity: animation, child: child),
            ));
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (item['color'] as Color).withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (item['color'] as Color).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item['icon'] as IconData,
                color: item['color'] as Color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['subtitle'],
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.45),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.25),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ECC71).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Color(0xFF2ECC71),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kirana Store',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Inventory & Billing App',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            Divider(color: Colors.white.withOpacity(0.08)),

            const SizedBox(height: 8),

            _menuItem(
              icon: Icons.store_rounded,
              label: 'Edit Store Name',
              color: const Color(0xFF3498DB),
              onTap: () {
                Navigator.pop(context);
                _editStoreName(context);
              },
            ),

            const SizedBox(height: 4),

            _menuItem(
              icon: Icons.info_outline_rounded,
              label: 'About App',
              color: const Color(0xFF9B59B6),
              onTap: () {
                Navigator.pop(context);
                _showAbout(context);
              },
            ),

            const SizedBox(height: 4),

            _menuItem(
              icon: Icons.workspace_premium_rounded,
              label: 'Subscription',
              color: const Color(0xFFE67E22),
              onTap: () {
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
            ),

          ],
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white.withOpacity(0.2), size: 14),
          ],
        ),
      ),
    );
  }

  void _editStoreName(BuildContext context) {
    final controller = TextEditingController();

    // Load current store name
    _service.getStoreName().first.then((name) {
      controller.text = name;
    });

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Edit Store Name',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D0D),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter store name',
              hintStyle:
              TextStyle(color: Colors.white.withOpacity(0.3)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style:
                TextStyle(color: Colors.white.withOpacity(0.45))),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              await _service.updateStoreName(name);
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF2ECC71),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  content: const Text(
                    '✓ Store name updated!',
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              );
            },
            child: const Text('Save',
                style: TextStyle(
                    color: Color(0xFF2ECC71),
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF2ECC71).withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.storefront_rounded,
                  color: Color(0xFF2ECC71), size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              'Kirana Store',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Smart Inventory & Billing App\nVersion 1.0.0',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.45),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close',
                style: TextStyle(color: Color(0xFF2ECC71))),
          ),
        ],
      ),
    );
  }
}