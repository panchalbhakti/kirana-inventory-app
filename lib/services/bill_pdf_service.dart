import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../models/product_model.dart';

class BillPdfService {
  static Future<void> generateAndShare({
    required BuildContext context,
    required String storeName,
    required Map<Product, double> cartItems,
    required double total,
    required String paymentMethod,
    DateTime? billDate,
  }) async {
    final date = billDate ?? DateTime.now();
    final billNo = 'INV-${date.year}${date.month.toString().padLeft(2,'0')}${date.day.toString().padLeft(2,'0')}-${date.millisecondsSinceEpoch % 10000}';

    // ── Color palette (matches app) ──────────────────────────
    const bgDark    = PdfColor.fromInt(0xFF141420);
    const green     = PdfColor.fromInt(0xFF00E68A);
    const white     = PdfColors.white;
    const textDim   = PdfColor.fromInt(0xFF8080A0);
    const border    = PdfColor.fromInt(0xFF28283C);
    const rowEven   = PdfColors.white;
    const rowOdd    = PdfColor.fromInt(0xFFF7F7FC);

    final pdf = pw.Document();

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (ctx) => pw.Container(
        color: PdfColors.white,
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [

          // ── Header ────────────────────────────────────────
          pw.Container(
            color: bgDark,
            padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 28),
            child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(storeName, style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: white)),
                pw.SizedBox(height: 4),
                pw.Text('Kirana Store · Smart Billing', style: pw.TextStyle(fontSize: 11, color: textDim)),
              ]),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: pw.BoxDecoration(color: green, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6))),
                    child: pw.Text('INVOICE', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.black))),
                pw.SizedBox(height: 6),
                pw.Text(billNo, style: pw.TextStyle(fontSize: 10, color: textDim)),
              ]),
            ]),
          ),

          // ── Meta row ─────────────────────────────────────
          pw.Container(
            color: const PdfColor.fromInt(0xFFF5F5FA),
            padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 14),
            child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              _meta('Date', _fmtDate(date)),
              _meta('Time', _fmtTime(date)),
              _meta('Payment', paymentMethod),
              _meta('Items', '${cartItems.length}'),
            ]),
          ),

          pw.SizedBox(height: 20),

          // ── Table ────────────────────────────────────────
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 40),
            child: pw.Column(children: [
              // Header row
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: pw.BoxDecoration(color: bgDark, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
                child: pw.Row(children: [
                  pw.Expanded(flex: 5, child: pw.Text('PRODUCT', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textDim, letterSpacing: 0.8))),
                  pw.Expanded(flex: 2, child: pw.Text('QTY', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textDim, letterSpacing: 0.8))),
                  pw.Expanded(flex: 2, child: pw.Text('RATE', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textDim, letterSpacing: 0.8))),
                  pw.Expanded(flex: 2, child: pw.Text('TOTAL', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textDim, letterSpacing: 0.8))),
                ]),
              ),
              pw.SizedBox(height: 6),

              // Data rows
              ...cartItems.entries.toList().asMap().entries.map((e) {
                final i = e.key; final p = e.value.key; final qty = e.value.value;
                final itemTotal = p.price * qty;
                final qtyStr = p.unit == ProductUnit.pcs
                    ? '${qty.toInt()} ${p.unit.label}'
                    : qty == qty.truncateToDouble()
                    ? '${qty.toInt()} ${p.unit.label}'
                    : '${qty.toStringAsFixed(2)} ${p.unit.label}';

                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: pw.BoxDecoration(
                    color: i % 2 == 0 ? rowEven : rowOdd,
                    border: const pw.Border(bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFEEEEF5), width: 0.5)),
                  ),
                  child: pw.Row(children: [
                    pw.Expanded(flex: 5, child: pw.Text(p.name, style: const pw.TextStyle(fontSize: 12))),
                    pw.Expanded(flex: 2, child: pw.Text(qtyStr, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 12))),
                    pw.Expanded(flex: 2, child: pw.Text('Rs.${p.price.toStringAsFixed(2)}', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 12))),
                    pw.Expanded(flex: 2, child: pw.Text('Rs.${itemTotal.toStringAsFixed(2)}', textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
                  ]),
                );
              }),
            ]),
          ),

          pw.SizedBox(height: 20),

          // ── Total box ────────────────────────────────────
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 40),
            child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
              pw.Container(width: 230,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFF0FFF8),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                  border: pw.Border.all(color: const PdfColor.fromInt(0xFF00E68A), width: 1.5),
                ),
                child: pw.Column(children: [
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                    pw.Text('Subtotal', style: pw.TextStyle(fontSize: 11, color: textDim)),
                    pw.Text('Rs.${total.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 11)),
                  ]),
                  pw.SizedBox(height: 6),
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                    pw.Text('Discount', style: pw.TextStyle(fontSize: 11, color: textDim)),
                    pw.Text('Rs.0.00', style: const pw.TextStyle(fontSize: 11)),
                  ]),
                  pw.SizedBox(height: 8),
                  pw.Divider(color: border, height: 1, thickness: 0.5),
                  pw.SizedBox(height: 8),
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                    pw.Text('TOTAL', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Rs.${total.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: green)),
                  ]),
                ]),
              ),
            ]),
          ),

          pw.Spacer(),

          // ── Footer ───────────────────────────────────────
          pw.Container(
            color: const PdfColor.fromInt(0xFFF5F5FA),
            padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 14),
            child: pw.Column(children: [
              pw.Divider(color: border, height: 1, thickness: 0.5),
              pw.SizedBox(height: 10),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('Thank you for shopping at $storeName!',
                    style: pw.TextStyle(fontSize: 11, color: textDim, fontStyle: pw.FontStyle.italic)),
                pw.Text('Generated by Kirana App', style: pw.TextStyle(fontSize: 10, color: textDim)),
              ]),
            ]),
          ),
        ]),
      ),
    ));

    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$billNo.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)],
        subject: 'Bill from $storeName — $billNo',
        text: 'Please find your bill attached.');
  }

  static pw.Widget _meta(String label, String value) {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(label, style: pw.TextStyle(fontSize: 9, color: const PdfColor.fromInt(0xFF888888), letterSpacing: 0.6)),
      pw.SizedBox(height: 3),
      pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
    ]);
  }

  static String _fmtDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month-1]} ${d.year}';
  }

  static String _fmtTime(DateTime d) {
    final h = d.hour > 12 ? d.hour-12 : (d.hour==0?12:d.hour);
    final m = d.minute.toString().padLeft(2,'0');
    return '$h:$m ${d.hour>=12?"PM":"AM"}';
  }
}