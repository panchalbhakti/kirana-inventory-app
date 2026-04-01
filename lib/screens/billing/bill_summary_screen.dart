// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../providers/billing_provider.dart';
//
// class BillSummaryScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final billing = context.watch<BillingProvider>();
//
//     return Scaffold(
//       backgroundColor: const Color(0xFF0D0D0D),
//       body: SafeArea(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header
//             Padding(
//               padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
//               child: GestureDetector(
//                 onTap: () => Navigator.pop(context),
//                 child: Row(
//                   children: [
//                     Icon(Icons.arrow_back_ios_rounded,
//                         color: Colors.white.withOpacity(0.45), size: 14),
//                     const SizedBox(width: 4),
//                     Text('Back',
//                         style: TextStyle(
//                             fontSize: 13,
//                             color: Colors.white.withOpacity(0.45))),
//                   ],
//                 ),
//               ),
//             ),
//
//             const Padding(
//               padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
//               child: Text(
//                 'Bill Summary',
//                 style: TextStyle(
//                   fontSize: 26,
//                   fontWeight: FontWeight.w700,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//
//             Padding(
//               padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
//               child: Text(
//                 '${billing.cart.length} item${billing.cart.length == 1 ? '' : 's'}',
//                 style: TextStyle(
//                   fontSize: 13,
//                   color: Colors.white.withOpacity(0.35),
//                 ),
//               ),
//             ),
//
//             // Bill Items
//             Expanded(
//               child: ListView(
//                 children: billing.cart.entries.map((e) {
//                   return Container(
//                     margin: const EdgeInsets.symmetric(
//                         horizontal: 20, vertical: 5),
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFF1E1E1E),
//                       borderRadius: BorderRadius.circular(14),
//                       border: Border.all(
//                           color: Colors.white.withOpacity(0.06)),
//                     ),
//                     child: Row(
//                       children: [
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 e.key.name,
//                                 style: const TextStyle(
//                                   fontSize: 14,
//                                   fontWeight: FontWeight.w600,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               Text(
//                                 '${e.value} x ₹${e.key.price}',
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.white.withOpacity(0.4),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         Text(
//                           '₹${(e.key.price * e.value).toStringAsFixed(2)}',
//                           style: const TextStyle(
//                             fontSize: 15,
//                             fontWeight: FontWeight.w700,
//                             color: Color(0xFF2ECC71),
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 }).toList(),
//               ),
//             ),
//
//             // Total & Confirm
//             Container(
//               padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
//               decoration: BoxDecoration(
//                 color: const Color(0xFF1E1E1E),
//                 border: Border(
//                   top: BorderSide(color: Colors.white.withOpacity(0.06)),
//                 ),
//               ),
//               child: Column(
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         'Total Amount',
//                         style: TextStyle(
//                           fontSize: 14,
//                           color: Colors.white.withOpacity(0.55),
//                         ),
//                       ),
//                       Text(
//                         '₹${billing.total.toStringAsFixed(2)}',
//                         style: const TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.w700,
//                           color: Color(0xFF2ECC71),
//                         ),
//                       ),
//                     ],
//                   ),
//
//                   const SizedBox(height: 16),
//
//                   // Confirm Button
//                   GestureDetector(
//                     onTap: () async {
//                       try {
//                         await billing.confirmBill();
//
//                         if (!context.mounted) return;
//
//                         Navigator.pop(context);
//
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(
//                             backgroundColor: const Color(0xFF2ECC71),
//                             behavior: SnackBarBehavior.floating,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             content: const Text(
//                               '✓ Bill confirmed successfully!',
//                               style: TextStyle(
//                                 color: Colors.black,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ),
//                         );
//                       } catch (e) {
//                         if (!context.mounted) return;
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(
//                             backgroundColor: const Color(0xFFE74C3C),
//                             behavior: SnackBarBehavior.floating,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             content: Text(
//                               'Error: ${e.toString()}',
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ),
//                         );
//                       }
//                     },
//                     child: Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFF2ECC71),
//                         borderRadius: BorderRadius.circular(14),
//                       ),
//                       child: const Text(
//                         'Confirm & Save Bill',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w700,
//                           color: Colors.black,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/billing_provider.dart';

class BillSummaryScreen extends StatefulWidget {
  @override
  _BillSummaryScreenState createState() => _BillSummaryScreenState();
}

class _BillSummaryScreenState extends State<BillSummaryScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final billing = context.watch<BillingProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                'Bill Summary',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Text(
                '${billing.cart.length} item${billing.cart.length == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.35),
                ),
              ),
            ),

            // Bill Items
            Expanded(
              child: ListView(
                children: billing.cart.entries.map((e) {
                  return Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 5),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.key.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${e.value} x ₹${e.key.price}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${(e.key.price * e.value).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2ECC71),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            // Total & Confirm
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.06)),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.55),
                        ),
                      ),
                      Text(
                        '₹${billing.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2ECC71),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Confirm Button
                  GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () async {
                      setState(() => _isLoading = true);
                      print("Button tapped!");

                      try {
                        await billing.confirmBill();
                        print("confirmBill done!");

                        if (!mounted) return;

                        setState(() => _isLoading = false);
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF2ECC71),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            content: const Text(
                              '✓ Bill confirmed successfully!',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      } catch (e) {
                        print("ERROR: $e");
                        if (!mounted) return;
                        setState(() => _isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFFE74C3C),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            content: Text(
                              'Error: ${e.toString()}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _isLoading
                            ? const Color(0xFF2ECC71).withOpacity(0.5)
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.black),
                          ),
                        ),
                      )
                          : const Text(
                        'Confirm & Save Bill',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
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