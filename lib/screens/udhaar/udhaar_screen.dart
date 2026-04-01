import 'package:flutter/material.dart';
import '../../models/customer_model.dart';
import '../../services/firebase_service.dart';
import 'add_customer_screen.dart';
import 'customer_detail_screen.dart';

class UdhaarScreen extends StatelessWidget {
  const UdhaarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // FIX: local variable instead of instance field
    final service = FirebaseService();

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
                                color: Colors.white.withOpacity(0.45),
                                size: 14),
                            const SizedBox(width: 4),
                            Text('Back',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.45))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Udhaar Tracker',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 400),
                        pageBuilder: (_, __, ___) => const AddCustomerScreen(),
                        transitionsBuilder: (_, animation, __, child) =>
                            FadeTransition(opacity: animation, child: child),
                      ),
                    ),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE67E22),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: StreamBuilder<List<Customer>>(
                stream: service.getCustomers(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFE67E22)),
                      ),
                    );
                  }

                  final customers = snapshot.data!;
                  final totalOutstanding = customers.fold<double>(
                      0, (sum, c) => sum + c.outstanding);

                  if (customers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline_rounded,
                              color: Colors.white.withOpacity(0.15),
                              size: 56),
                          const SizedBox(height: 16),
                          Text(
                            'No customers yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.3),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap + to add a customer',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      // Summary Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFE67E22).withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Outstanding',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.45),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '₹${totalOutstanding.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFE67E22),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Customers',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.45),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${customers.length}',
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF3498DB),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'CUSTOMERS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.35),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: customers.length,
                          itemBuilder: (_, i) {
                            final c = customers[i];
                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                PageRouteBuilder(
                                  transitionDuration:
                                  const Duration(milliseconds: 400),
                                  pageBuilder: (_, __, ___) =>
                                      CustomerDetailScreen(customer: c),
                                  transitionsBuilder:
                                      (_, animation, __, child) =>
                                      FadeTransition(
                                          opacity: animation,
                                          child: child),
                                ),
                              ),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 5),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E1E),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: c.outstanding > 0
                                        ? const Color(0xFFE67E22)
                                        .withOpacity(0.2)
                                        : const Color(0xFF2ECC71)
                                        .withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE67E22)
                                            .withOpacity(0.1),
                                        borderRadius:
                                        BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          c.name[0].toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFFE67E22),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            c.name,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            c.phone,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white
                                                  .withOpacity(0.35),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '₹${c.outstanding.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: c.outstanding > 0
                                                ? const Color(0xFFE67E22)
                                                : const Color(0xFF2ECC71),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          c.outstanding > 0
                                              ? 'Outstanding'
                                              : 'Cleared',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: c.outstanding > 0
                                                ? const Color(0xFFE67E22)
                                                .withOpacity(0.7)
                                                : const Color(0xFF2ECC71)
                                                .withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}