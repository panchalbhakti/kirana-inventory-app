import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/billing_provider.dart';
import '../../models/product_model.dart';
import '../../services/firebase_service.dart';
import '../../services/bill_pdf_service.dart';

enum _Method { upi, card, cash }

class PaymentScreen extends StatefulWidget {
  final double total;
  const PaymentScreen({super.key, required this.total});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with TickerProviderStateMixin {
  _Method _method = _Method.upi;
  bool _processing = false, _done = false, _pdfLoading = false;

  final _upiCtrl = TextEditingController();
  final _cardNumCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _cashCtrl = TextEditingController();

  late AnimationController _successCtrl;
  late Animation<double> _successScale;
  Map<Product, double> _cartSnapshot = {};
  String _storeName = 'Kirana Store';

  @override
  void initState() {
    super.initState();
    _successCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _successScale = CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _successCtrl.dispose();
    for (final c in [_upiCtrl, _cardNumCtrl, _expiryCtrl, _cvvCtrl, _nameCtrl, _cashCtrl]) c.dispose();
    super.dispose();
  }

  bool _validate() {
    switch (_method) {
      case _Method.upi:
        if (!_upiCtrl.text.contains('@')) { kSnack(context, 'Enter a valid UPI ID (e.g. name@upi)', ok: false); return false; }
        break;
      case _Method.card:
        if (_cardNumCtrl.text.replaceAll(' ', '').length < 16) { kSnack(context, 'Enter a valid 16-digit card number', ok: false); return false; }
        if (_expiryCtrl.text.length < 5) { kSnack(context, 'Enter valid expiry (MM/YY)', ok: false); return false; }
        if (_cvvCtrl.text.length < 3) { kSnack(context, 'Enter valid CVV', ok: false); return false; }
        if (_nameCtrl.text.trim().isEmpty) { kSnack(context, 'Enter cardholder name', ok: false); return false; }
        break;
      case _Method.cash:
        final entered = double.tryParse(_cashCtrl.text) ?? 0;
        if (entered < widget.total) { kSnack(context, '₹${(widget.total - entered).toStringAsFixed(0)} more needed', ok: false); return false; }
        break;
    }
    return true;
  }

  Future<void> _pay() async {
    if (!_validate()) return;
    setState(() => _processing = true);
    final billing = context.read<BillingProvider>();
    _cartSnapshot = Map<Product, double>.from(billing.cart);
    _storeName = await FirebaseService().getStoreName().first;
    await Future.delayed(const Duration(seconds: 2));
    await billing.confirmBill();
    setState(() { _processing = false; _done = true; });
    _successCtrl.forward();
  }

  String get _methodLabel {
    switch (_method) {
      case _Method.upi: return 'UPI';
      case _Method.card: return 'Credit/Debit Card';
      case _Method.cash: return 'Cash';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return _SuccessScreen(
      total: widget.total, method: _methodLabel,
      cartSnapshot: _cartSnapshot, storeName: _storeName,
      pdfLoading: _pdfLoading,
      onPdf: () async {
        setState(() => _pdfLoading = true);
        try {
          await BillPdfService.generateAndShare(
              context: context, storeName: _storeName,
              cartItems: _cartSnapshot, total: widget.total, paymentMethod: _methodLabel);
        } catch (e) {
          if (mounted) kSnack(context, 'PDF error: $e', ok: false);
        } finally {
          if (mounted) setState(() => _pdfLoading = false);
        }
      },
      onDone: () => Navigator.of(context).popUntil((route) => route.isFirst),
      scaleAnim: _successScale,
    );

    return Scaffold(
      backgroundColor: K.bg,
      body: SafeArea(child: Column(children: [
        // ── Header ──────────────────────────────────────────
        const Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, 0), child: Align(alignment: Alignment.centerLeft, child: KBack())),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Payment', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: K.t1, letterSpacing: -0.5)),
              Text('Amount due', style: const TextStyle(fontSize: 13, color: K.t2)),
            ]),
            const Spacer(),
            Text('₹${widget.total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: K.green, letterSpacing: -0.5)),
          ]),
        ),

        const SizedBox(height: 20),

        // ── Method Tabs ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            _tab('UPI', Icons.account_balance_rounded, _Method.upi, K.purple),
            const SizedBox(width: 10),
            _tab('Card', Icons.credit_card_rounded, _Method.card, K.blue),
            const SizedBox(width: 10),
            _tab('Cash', Icons.payments_rounded, _Method.cash, K.green),
          ]),
        ),

        const SizedBox(height: 20),

        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildForm(),
        )),

        // ── Pay Button ───────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: KBtn(
            label: _method == _Method.upi ? 'Pay via UPI' : _method == _Method.card ? 'Pay ₹${widget.total.toStringAsFixed(2)}' : 'Confirm Payment',
            icon: _method == _Method.upi ? Icons.qr_code_scanner_rounded : _method == _Method.card ? Icons.credit_card_rounded : Icons.check_circle_rounded,
            loading: _processing, onTap: _pay,
          ),
        ),
      ])),
    );
  }

  Widget _tab(String label, IconData icon, _Method method, Color color) {
    final active = _method == method;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _method = method),
      child: AnimatedContainer(duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.1) : K.surfaceEl,
          borderRadius: BorderRadius.circular(K.r2),
          border: Border.all(color: active ? color.withOpacity(0.4) : K.b2, width: active ? 1.5 : 1),
        ),
        child: Column(children: [
          Icon(icon, color: active ? color : K.t3, size: 20),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              color: active ? color : K.t3)),
        ]),
      ),
    ));
  }

  Widget _buildForm() {
    switch (_method) {
      case _Method.upi: return _UpiForm(ctrl: _upiCtrl);
      case _Method.card: return _CardForm(numCtrl: _cardNumCtrl, expiryCtrl: _expiryCtrl, cvvCtrl: _cvvCtrl, nameCtrl: _nameCtrl);
      case _Method.cash: return _CashForm(ctrl: _cashCtrl, total: widget.total);
    }
  }
}

// ─── UPI Form ─────────────────────────────────────────────────────────────────

class _UpiForm extends StatelessWidget {
  final TextEditingController ctrl;
  const _UpiForm({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    const apps = [('GPay', K.blue), ('PhonePe', K.purple), ('Paytm', Color(0xFF00BAF2)), ('BHIM', K.green)];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      KField(controller: ctrl, label: 'UPI ID', hint: 'yourname@upi or yourname@okicici',
          icon: Icons.alternate_email_rounded, keyboardType: TextInputType.emailAddress),
      const SizedBox(height: 20),
      const KLabel('Popular UPI Apps'),
      const SizedBox(height: 10),
      Row(children: apps.map((app) => Expanded(child: Container(
        margin: app.$1 != 'BHIM' ? const EdgeInsets.only(right: 8) : EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(color: app.$2.withOpacity(0.08), borderRadius: BorderRadius.circular(K.r1),
            border: Border.all(color: app.$2.withOpacity(0.2))),
        child: Text(app.$1, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: app.$2)),
      ))).toList()),
      const SizedBox(height: 16),
      Container(padding: const EdgeInsets.all(K.md),
          decoration: BoxDecoration(color: K.purple.withOpacity(0.06), borderRadius: BorderRadius.circular(K.r2),
              border: Border.all(color: K.purple.withOpacity(0.15))),
          child: Row(children: [
            const Icon(Icons.security_rounded, color: K.purple, size: 16),
            const SizedBox(width: 10),
            Expanded(child: Text('Secured with 256-bit encryption. UPI details are never stored.',
                style: TextStyle(fontSize: 12, color: K.t2))),
          ])),
    ]);
  }
}

// ─── Card Form ─────────────────────────────────────────────────────────────────

class _CardForm extends StatelessWidget {
  final TextEditingController numCtrl, expiryCtrl, cvvCtrl, nameCtrl;
  const _CardForm({required this.numCtrl, required this.expiryCtrl, required this.cvvCtrl, required this.nameCtrl});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Card preview
      ValueListenableBuilder(valueListenable: numCtrl, builder: (_, __, ___) =>
          ValueListenableBuilder(valueListenable: nameCtrl, builder: (_, __, ___) =>
              ValueListenableBuilder(valueListenable: expiryCtrl, builder: (_, __, ___) {
                final raw = numCtrl.text.replaceAll(' ', '').padRight(16, '•');
                final formatted = raw.replaceAllMapped(RegExp(r'.{4}'), (m) => '${m.group(0)} ').trim();
                return Container(height: 170,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF1A2A5C), Color(0xFF2C3A8C)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(K.r3),
                      boxShadow: [BoxShadow(color: K.blue.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Icon(Icons.credit_card_rounded, color: Colors.white, size: 26),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFFFFD700).withOpacity(0.9), borderRadius: BorderRadius.circular(4)),
                            child: const Text('VISA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF1A237E)))),
                      ]),
                      const Spacer(),
                      Text(formatted, style: const TextStyle(fontSize: 16, letterSpacing: 3, color: Colors.white, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(nameCtrl.text.isEmpty ? 'CARDHOLDER NAME' : nameCtrl.text.toUpperCase(),
                            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.65), letterSpacing: 1)),
                        Text(expiryCtrl.text.isEmpty ? 'MM/YY' : expiryCtrl.text,
                            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.65))),
                      ]),
                    ]));
              }))),

      const SizedBox(height: 20),
      KField(controller: numCtrl, label: 'Card Number', hint: '0000 0000 0000 0000',
          icon: Icons.credit_card_rounded, keyboardType: TextInputType.number, maxLength: 19,
          formatters: [FilteringTextInputFormatter.digitsOnly, _CardFmt()]),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: KField(controller: expiryCtrl, label: 'Expiry', hint: 'MM/YY',
            icon: Icons.calendar_month_rounded, keyboardType: TextInputType.number, maxLength: 5,
            formatters: [FilteringTextInputFormatter.digitsOnly, _ExpiryFmt()])),
        const SizedBox(width: 14),
        Expanded(child: KField(controller: cvvCtrl, label: 'CVV', hint: '•••',
            icon: Icons.lock_rounded, keyboardType: TextInputType.number, maxLength: 3, obscure: true,
            formatters: [FilteringTextInputFormatter.digitsOnly])),
      ]),
      const SizedBox(height: 14),
      KField(controller: nameCtrl, label: 'Name on Card', hint: 'Full name',
          icon: Icons.person_rounded, keyboardType: TextInputType.name,
          formatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]'))]),
      const SizedBox(height: 16),
    ]);
  }
}

// ─── Cash Form ─────────────────────────────────────────────────────────────────

class _CashForm extends StatefulWidget {
  final TextEditingController ctrl;
  final double total;
  const _CashForm({required this.ctrl, required this.total});
  @override
  State<_CashForm> createState() => _CashFormState();
}

class _CashFormState extends State<_CashForm> {
  @override
  Widget build(BuildContext context) {
    final entered = double.tryParse(widget.ctrl.text) ?? 0;
    final change = entered - widget.total;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.all(K.md+4),
          decoration: BoxDecoration(color: K.green.withOpacity(0.06), borderRadius: BorderRadius.circular(K.r3),
              border: Border.all(color: K.green.withOpacity(0.18))),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Amount Due', style: TextStyle(fontSize: 12, color: K.t2)),
              const SizedBox(height: 4),
              Text('₹${widget.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: K.green, letterSpacing: -0.5)),
            ]),
            const Icon(Icons.payments_rounded, color: K.green, size: 38),
          ])),
      const SizedBox(height: 20),
      KField(controller: widget.ctrl, label: 'Cash Received', hint: '0.00',
          icon: Icons.currency_rupee_rounded,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {})),
      const SizedBox(height: 14),
      if (entered >= widget.total)
        Container(padding: const EdgeInsets.all(K.md),
            decoration: BoxDecoration(color: K.blue.withOpacity(0.07), borderRadius: BorderRadius.circular(K.r2),
                border: Border.all(color: K.blue.withOpacity(0.18))),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Change to Return', style: TextStyle(fontSize: 14, color: K.t1, fontWeight: FontWeight.w500)),
              Text('₹${change.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: K.blue, letterSpacing: -0.5)),
            ]))
      else if (widget.ctrl.text.isNotEmpty)
        Container(padding: const EdgeInsets.all(K.md),
            decoration: BoxDecoration(color: K.red.withOpacity(0.06), borderRadius: BorderRadius.circular(K.r2),
                border: Border.all(color: K.red.withOpacity(0.18))),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded, color: K.red, size: 16),
              const SizedBox(width: 8),
              Text('₹${(widget.total - entered).toStringAsFixed(2)} more needed',
                  style: const TextStyle(fontSize: 13, color: K.red, fontWeight: FontWeight.w500)),
            ])),
    ]);
  }
}

// ─── Success Screen ────────────────────────────────────────────────────────────

class _SuccessScreen extends StatelessWidget {
  final double total;
  final String method;
  final Map<Product, double> cartSnapshot;
  final String storeName;
  final bool pdfLoading;
  final VoidCallback onPdf, onDone;
  final Animation<double> scaleAnim;

  const _SuccessScreen({required this.total, required this.method, required this.cartSnapshot,
    required this.storeName, required this.pdfLoading, required this.onPdf,
    required this.onDone, required this.scaleAnim});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: K.bg,
      body: SafeArea(child: Center(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ScaleTransition(scale: scaleAnim,
              child: Container(width: 110, height: 110,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF00E68A), Color(0xFF00B86E)]),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: K.green.withOpacity(0.35), blurRadius: 32, offset: const Offset(0, 10))],
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.black, size: 54))),

          const SizedBox(height: 28),
          const Text('Payment Successful!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: K.t1)),
          const SizedBox(height: 8),
          Text('₹${total.toStringAsFixed(2)} received via $method',
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: K.t2)),

          const SizedBox(height: 28),
          Container(padding: const EdgeInsets.all(K.md),
              decoration: BoxDecoration(color: K.surface, borderRadius: BorderRadius.circular(K.r2), border: Border.all(color: K.b1)),
              child: Row(children: [
                Container(width: 36, height: 36,
                    decoration: BoxDecoration(color: K.green.withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
                    child: const Icon(Icons.receipt_long_rounded, color: K.green, size: 17)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Bill Saved', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: K.t1)),
                  const Text('Recorded in Sales History', style: TextStyle(fontSize: 12, color: K.t2)),
                ])),
                const Icon(Icons.check_circle_rounded, color: K.green, size: 20),
              ])),

          const SizedBox(height: 28),

          // Download PDF
          GestureDetector(
            onTap: pdfLoading ? null : onPdf,
            child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(color: K.surfaceEl, borderRadius: BorderRadius.circular(K.r2),
                    border: Border.all(color: K.blue.withOpacity(0.35))),
                child: pdfLoading
                    ? const Center(child: SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(K.blue))))
                    : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.picture_as_pdf_rounded, color: K.blue, size: 18),
                  SizedBox(width: 8),
                  Text('Download / Share Bill', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: K.blue)),
                ])),
          ),

          const SizedBox(height: 10),

          KBtn(label: 'Done', onTap: onDone),
        ]),
      ))),
    );
  }
}

// ─── Text Formatters ───────────────────────────────────────────────────────────

class _CardFmt extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) {
    var t = n.text.replaceAll(' ', '');
    if (t.length > 16) t = t.substring(0, 16);
    final b = StringBuffer();
    for (int i = 0; i < t.length; i++) { if (i > 0 && i % 4 == 0) b.write(' '); b.write(t[i]); }
    final f = b.toString();
    return n.copyWith(text: f, selection: TextSelection.collapsed(offset: f.length));
  }
}

class _ExpiryFmt extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) {
    var t = n.text.replaceAll('/', '');
    if (t.length > 4) t = t.substring(0, 4);
    if (t.length >= 3) t = '${t.substring(0, 2)}/${t.substring(2)}';
    return n.copyWith(text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}