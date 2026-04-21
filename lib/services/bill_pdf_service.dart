import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../models/product_model.dart';

class BillPdfService {
  /// Generates a styled PDF bill and shares it via the system share sheet.
  static Future<void> generateAndShare({
    required BuildContext context,
    required String storeName,
    required Map<Product, int> cartItems,
    required double total,
    required String paymentMethod,
    DateTime? billDate,
  }) async {
    final date = billDate ?? DateTime.now();
    final billNo =
        'INV-${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}-${date.millisecondsSinceEpoch % 10000}';

    final pdf = pw.Document();

    // ── Colors ──────────────────────────────────────────────────
    const green = PdfColor.fromInt(0xFF2ECC71);
    const darkBg = PdfColor.fromInt(0xFF1A1A1A);
    const textLight = PdfColor.fromInt(0xFF888888);
    const white = PdfColors.white;
    const black = PdfColors.black;
    const divider = PdfColor.fromInt(0xFF333333);

    // ── Page ────────────────────────────────────────────────────
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (ctx) {
          return pw.Container(
            color: PdfColors.white,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Header Banner
                pw.Container(
                  color: darkBg,
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 40, vertical: 32),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            storeName,
                            style: pw.TextStyle(
                              fontSize: 26,
                              fontWeight: pw.FontWeight.bold,
                              color: white,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Kirana Store',
                            style: pw.TextStyle(
                              fontSize: 12,
                              color: textLight,
                            ),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: pw.BoxDecoration(
                              color: green,
                              borderRadius: const pw.BorderRadius.all(
                                  pw.Radius.circular(6)),
                            ),
                            child: pw.Text(
                              'INVOICE',
                              style: pw.TextStyle(
                                fontSize: 13,
                                fontWeight: pw.FontWeight.bold,
                                color: black,
                              ),
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            billNo,
                            style: pw.TextStyle(
                              fontSize: 11,
                              color: textLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Date & Payment Info
                pw.Container(
                  color: const PdfColor.fromInt(0xFFF8F8F8),
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 40, vertical: 16),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _pdfInfoItem('Date', _formatDate(date)),
                      _pdfInfoItem('Time', _formatTime(date)),
                      _pdfInfoItem('Payment', paymentMethod),
                      _pdfInfoItem(
                          'Items', '${cartItems.length} product(s)'),
                    ],
                  ),
                ),

                pw.SizedBox(height: 24),

                // Items Table
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 40),
                  child: pw.Column(
                    children: [
                      // Table Header
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: pw.BoxDecoration(
                          color: darkBg,
                          borderRadius: const pw.BorderRadius.all(
                              pw.Radius.circular(8)),
                        ),
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                              flex: 5,
                              child: pw.Text('PRODUCT',
                                  style: pw.TextStyle(
                                      fontSize: 10,
                                      fontWeight: pw.FontWeight.bold,
                                      color: textLight,
                                      letterSpacing: 1.0)),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text('QTY',
                                  textAlign: pw.TextAlign.center,
                                  style: pw.TextStyle(
                                      fontSize: 10,
                                      fontWeight: pw.FontWeight.bold,
                                      color: textLight,
                                      letterSpacing: 1.0)),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text('PRICE',
                                  textAlign: pw.TextAlign.center,
                                  style: pw.TextStyle(
                                      fontSize: 10,
                                      fontWeight: pw.FontWeight.bold,
                                      color: textLight,
                                      letterSpacing: 1.0)),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text('TOTAL',
                                  textAlign: pw.TextAlign.right,
                                  style: pw.TextStyle(
                                      fontSize: 10,
                                      fontWeight: pw.FontWeight.bold,
                                      color: textLight,
                                      letterSpacing: 1.0)),
                            ),
                          ],
                        ),
                      ),

                      pw.SizedBox(height: 8),

                      // Table Rows
                      ...cartItems.entries.toList().asMap().entries.map(
                            (entry) {
                          final i = entry.key;
                          final product = entry.value.key;
                          final qty = entry.value.value;
                          final itemTotal = product.price * qty;
                          final isEven = i % 2 == 0;

                          return pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: pw.BoxDecoration(
                              color: isEven
                                  ? PdfColors.white
                                  : const PdfColor.fromInt(0xFFFAFAFA),
                              border: const pw.Border(
                                bottom: pw.BorderSide(
                                    color: PdfColor.fromInt(0xFFEEEEEE),
                                    width: 0.5),
                              ),
                            ),
                            child: pw.Row(
                              children: [
                                pw.Expanded(
                                  flex: 5,
                                  child: pw.Text(
                                    product.name,
                                    style: const pw.TextStyle(fontSize: 12),
                                  ),
                                ),
                                pw.Expanded(
                                  flex: 2,
                                  child: pw.Text(
                                    '$qty',
                                    textAlign: pw.TextAlign.center,
                                    style: const pw.TextStyle(fontSize: 12),
                                  ),
                                ),
                                pw.Expanded(
                                  flex: 2,
                                  child: pw.Text(
                                    '₹${product.price.toStringAsFixed(2)}',
                                    textAlign: pw.TextAlign.center,
                                    style: const pw.TextStyle(fontSize: 12),
                                  ),
                                ),
                                pw.Expanded(
                                  flex: 2,
                                  child: pw.Text(
                                    '₹${itemTotal.toStringAsFixed(2)}',
                                    textAlign: pw.TextAlign.right,
                                    style: pw.TextStyle(
                                      fontSize: 12,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 24),

                // Total Section
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 40),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Container(
                        width: 240,
                        padding: const pw.EdgeInsets.all(16),
                        decoration: pw.BoxDecoration(
                          color: const PdfColor.fromInt(0xFFF0FFF4),
                          borderRadius: const pw.BorderRadius.all(
                              pw.Radius.circular(10)),
                          border: pw.Border(
                            left: const pw.BorderSide(
                                color: PdfColor.fromInt(0xFF2ECC71),
                                width: 3),
                          ),
                        ),
                        child: pw.Column(
                          children: [
                            pw.Row(
                              mainAxisAlignment:
                              pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Subtotal',
                                    style: pw.TextStyle(
                                        fontSize: 11, color: textLight)),
                                pw.Text(
                                    '₹${total.toStringAsFixed(2)}',
                                    style:
                                    const pw.TextStyle(fontSize: 11)),
                              ],
                            ),
                            pw.SizedBox(height: 6),
                            pw.Row(
                              mainAxisAlignment:
                              pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Discount',
                                    style: pw.TextStyle(
                                        fontSize: 11, color: textLight)),
                                pw.Text('₹0.00',
                                    style:
                                    const pw.TextStyle(fontSize: 11)),
                              ],
                            ),
                            pw.SizedBox(height: 8),
                            pw.Divider(
                                color: divider, height: 1, thickness: 0.5),
                            pw.SizedBox(height: 8),
                            pw.Row(
                              mainAxisAlignment:
                              pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('TOTAL',
                                    style: pw.TextStyle(
                                        fontSize: 14,
                                        fontWeight: pw.FontWeight.bold)),
                                pw.Text(
                                  '₹${total.toStringAsFixed(2)}',
                                  style: pw.TextStyle(
                                    fontSize: 16,
                                    fontWeight: pw.FontWeight.bold,
                                    color: green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                pw.Spacer(),

                // Footer
                pw.Container(
                  color: const PdfColor.fromInt(0xFFF8F8F8),
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 40, vertical: 16),
                  child: pw.Column(
                    children: [
                      pw.Divider(
                          color: divider, height: 1, thickness: 0.5),
                      pw.SizedBox(height: 12),
                      pw.Row(
                        mainAxisAlignment:
                        pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Thank you for shopping at $storeName!',
                            style: pw.TextStyle(
                              fontSize: 11,
                              color: textLight,
                              fontStyle: pw.FontStyle.italic,
                            ),
                          ),
                          pw.Text(
                            'Generated by Kirana Store App',
                            style: pw.TextStyle(
                                fontSize: 10, color: textLight),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // ── Save & Share ─────────────────────────────────────────────
    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$billNo.pdf');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Bill from $storeName — $billNo',
      text: 'Please find your bill attached.',
    );
  }

  static pw.Widget _pdfInfoItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                fontSize: 9,
                color: const PdfColor.fromInt(0xFF888888),
                letterSpacing: 0.8)),
        pw.SizedBox(height: 3),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 12, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  static String _formatTime(DateTime d) {
    final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final m = d.minute.toString().padLeft(2, '0');
    final period = d.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }
}