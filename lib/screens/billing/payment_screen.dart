import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/billing_provider.dart';
import '../../models/product_model.dart';
import '../../services/firebase_service.dart';
import '../../services/bill_pdf_service.dart';

enum PaymentMethod { upi, card, cash }

class PaymentScreen extends StatefulWidget {
  final double total;
  const PaymentScreen({super.key, required this.total});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  PaymentMethod _selectedMethod = PaymentMethod.upi;
  bool _isProcessing = false;
  bool _paymentDone = false;

  // Saved before confirmBill() clears the cart
  Map<Product, int> _cartSnapshot = {};
  String _storeName = 'Kirana Store';
  bool _isGeneratingPdf = false;

  // UPI
  final _upiController = TextEditingController();

  // Card
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();

  // Cash
  final _cashController = TextEditingController();

  late AnimationController _successAnimController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _successAnimController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = CurvedAnimation(
        parent: _successAnimController, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _upiController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    _cashController.dispose();
    _successAnimController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (!_validateForm()) return;

    setState(() => _isProcessing = true);

    final billing = context.read<BillingProvider>();

    // ── Save cart + store name BEFORE confirmBill() clears the cart ──
    _cartSnapshot = Map<Product, int>.from(billing.cart);
    _storeName = await FirebaseService().getStoreName().first;

    // Simulate payment gateway delay
    await Future.delayed(const Duration(seconds: 2));

    await billing.confirmBill();

    setState(() {
      _isProcessing = false;
      _paymentDone = true;
    });

    _successAnimController.forward();
  }

  bool _validateForm() {
    switch (_selectedMethod) {
      case PaymentMethod.upi:
        if (_upiController.text.trim().isEmpty ||
            !_upiController.text.contains('@')) {
          _showError('Please enter a valid UPI ID (e.g. name@upi)');
          return false;
        }
        break;
      case PaymentMethod.card:
        final cardNum =
        _cardNumberController.text.replaceAll(' ', '');
        if (cardNum.length < 16) {
          _showError('Enter a valid 16-digit card number');
          return false;
        }
        if (_expiryController.text.length < 5) {
          _showError('Enter valid expiry date (MM/YY)');
          return false;
        }
        if (_cvvController.text.length < 3) {
          _showError('Enter valid CVV');
          return false;
        }
        if (_nameController.text.trim().isEmpty) {
          _showError('Enter cardholder name');
          return false;
        }
        break;
      case PaymentMethod.cash:
        final entered = double.tryParse(_cashController.text) ?? 0;
        if (entered < widget.total) {
          _showError(
              'Cash entered (₹${entered.toStringAsFixed(0)}) is less than total');
          return false;
        }
        break;
    }
    return true;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: const Color(0xFFE74C3C),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Text(msg,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_paymentDone) return _buildSuccessScreen();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
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
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Payment',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 6),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Amount to pay',
                  style: TextStyle(
                      fontSize: 13, color: Colors.white.withOpacity(0.4)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '₹${widget.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2ECC71),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),

            // ── Payment Method Selector ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _methodTab('UPI', Icons.account_balance_rounded,
                      PaymentMethod.upi, const Color(0xFF9B59B6)),
                  const SizedBox(width: 10),
                  _methodTab('Card', Icons.credit_card_rounded,
                      PaymentMethod.card, const Color(0xFF3498DB)),
                  const SizedBox(width: 10),
                  _methodTab('Cash', Icons.payments_rounded,
                      PaymentMethod.cash, const Color(0xFF2ECC71)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Payment Form ─────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildForm(),
              ),
            ),

            // ── Pay Button ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: GestureDetector(
                onTap: _isProcessing ? null : _processPayment,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: _isProcessing
                        ? null
                        : const LinearGradient(
                        colors: [Color(0xFF2ECC71), Color(0xFF27AE60)]),
                    color: _isProcessing
                        ? const Color(0xFF2ECC71).withOpacity(0.4)
                        : null,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _isProcessing
                        ? null
                        : [
                      BoxShadow(
                        color: const Color(0xFF2ECC71).withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: _isProcessing
                      ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.black),
                      ),
                    ),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_payButtonIcon(), color: Colors.black, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _payButtonLabel(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Method Tab ────────────────────────────────────────────────────────────

  Widget _methodTab(
      String label, IconData icon, PaymentMethod method, Color color) {
    final isSelected = _selectedMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMethod = method),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color.withOpacity(0.5) : Colors.white.withOpacity(0.06),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Colors.white.withOpacity(0.35), size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? color : Colors.white.withOpacity(0.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Forms ─────────────────────────────────────────────────────────────────

  Widget _buildForm() {
    switch (_selectedMethod) {
      case PaymentMethod.upi:
        return _buildUpiForm();
      case PaymentMethod.card:
        return _buildCardForm();
      case PaymentMethod.cash:
        return _buildCashForm();
    }
  }

  Widget _buildUpiForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('UPI ID'),
        _inputField(
          controller: _upiController,
          hint: 'yourname@upi / yourname@okicici',
          icon: Icons.alternate_email_rounded,
          iconColor: const Color(0xFF9B59B6),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        _sectionLabel('POPULAR UPI APPS'),
        const SizedBox(height: 10),
        Row(
          children: [
            _upiAppChip('GPay', const Color(0xFF4285F4)),
            const SizedBox(width: 10),
            _upiAppChip('PhonePe', const Color(0xFF5F259F)),
            const SizedBox(width: 10),
            _upiAppChip('Paytm', const Color(0xFF00BAF2)),
            const SizedBox(width: 10),
            _upiAppChip('BHIM', const Color(0xFF1A237E)),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF9B59B6).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border:
            Border.all(color: const Color(0xFF9B59B6).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.security_rounded,
                  color: Color(0xFF9B59B6), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Secured with 256-bit encryption. Your UPI details are never stored.',
                  style: TextStyle(
                      fontSize: 12, color: Colors.white.withOpacity(0.5)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _upiAppChip(String name, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Text(
          name,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: color),
        ),
      ),
    );
  }

  Widget _buildCardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card Preview
        Container(
          height: 180,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A3A6C), Color(0xFF2C3E7A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF3498DB).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8))
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.credit_card_rounded,
                      color: Colors.white, size: 28),
                  Container(
                    width: 40,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Center(
                      child: Text('VISA',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1A237E))),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ValueListenableBuilder(
                valueListenable: _cardNumberController,
                builder: (_, __, ___) {
                  final raw = _cardNumberController.text.replaceAll(' ', '');
                  final padded = raw.padRight(16, '•');
                  final formatted = padded
                      .replaceAllMapped(RegExp(r'.{4}'), (m) => '${m.group(0)} ')
                      .trim();
                  return Text(formatted,
                      style: const TextStyle(
                          fontSize: 18,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w600,
                          color: Colors.white));
                },
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ValueListenableBuilder(
                    valueListenable: _nameController,
                    builder: (_, __, ___) => Text(
                      _nameController.text.isEmpty
                          ? 'CARDHOLDER NAME'
                          : _nameController.text.toUpperCase(),
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.7),
                          letterSpacing: 1),
                    ),
                  ),
                  ValueListenableBuilder(
                    valueListenable: _expiryController,
                    builder: (_, __, ___) => Text(
                      _expiryController.text.isEmpty
                          ? 'MM/YY'
                          : _expiryController.text,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.7)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        _sectionLabel('CARD NUMBER'),
        _inputField(
          controller: _cardNumberController,
          hint: '0000 0000 0000 0000',
          icon: Icons.credit_card_rounded,
          iconColor: const Color(0xFF3498DB),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _CardNumberFormatter(),
          ],
          maxLength: 19,
        ),

        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('EXPIRY DATE'),
                  _inputField(
                    controller: _expiryController,
                    hint: 'MM/YY',
                    icon: Icons.calendar_month_rounded,
                    iconColor: const Color(0xFF3498DB),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _ExpiryFormatter(),
                    ],
                    maxLength: 5,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('CVV'),
                  _inputField(
                    controller: _cvvController,
                    hint: '•••',
                    icon: Icons.lock_rounded,
                    iconColor: const Color(0xFF3498DB),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 3,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        _sectionLabel('NAME ON CARD'),
        _inputField(
          controller: _nameController,
          hint: 'Full name as on card',
          icon: Icons.person_rounded,
          iconColor: const Color(0xFF3498DB),
          keyboardType: TextInputType.name,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
          ],
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCashForm() {
    final cashEntered = double.tryParse(_cashController.text) ?? 0;
    final change = cashEntered - widget.total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Amount due card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF2ECC71).withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border:
            Border.all(color: const Color(0xFF2ECC71).withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Amount Due',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.45))),
                  const SizedBox(height: 4),
                  Text('₹${widget.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2ECC71))),
                ],
              ),
              const Icon(Icons.payments_rounded,
                  color: Color(0xFF2ECC71), size: 40),
            ],
          ),
        ),

        const SizedBox(height: 24),

        _sectionLabel('CASH RECEIVED FROM CUSTOMER'),
        _inputField(
          controller: _cashController,
          hint: '0.00',
          icon: Icons.currency_rupee_rounded,
          iconColor: const Color(0xFF2ECC71),
          keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
        ),

        const SizedBox(height: 20),

        // Change to return
        if (cashEntered >= widget.total)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF3498DB).withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border:
              Border.all(color: const Color(0xFF3498DB).withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Change to Return',
                    style: TextStyle(
                        fontSize: 14, color: Colors.white.withOpacity(0.7))),
                Text(
                  '₹${change.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3498DB),
                  ),
                ),
              ],
            ),
          )
        else if (_cashController.text.isNotEmpty && cashEntered < widget.total)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE74C3C).withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border:
              Border.all(color: const Color(0xFFE74C3C).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFE74C3C), size: 18),
                const SizedBox(width: 8),
                Text(
                  '₹${(widget.total - cashEntered).toStringAsFixed(2)} more needed',
                  style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFE74C3C),
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.35),
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color iconColor,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    int? maxLength,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        obscureText: obscureText,
        maxLength: maxLength,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.2), fontSize: 14),
          prefixIcon: Icon(icon, color: iconColor, size: 18),
          border: InputBorder.none,
          counterText: '',
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  IconData _payButtonIcon() {
    switch (_selectedMethod) {
      case PaymentMethod.upi:
        return Icons.qr_code_scanner_rounded;
      case PaymentMethod.card:
        return Icons.credit_card_rounded;
      case PaymentMethod.cash:
        return Icons.check_circle_rounded;
    }
  }

  String _payButtonLabel() {
    switch (_selectedMethod) {
      case PaymentMethod.upi:
        return 'Pay via UPI';
      case PaymentMethod.card:
        return 'Pay ₹${widget.total.toStringAsFixed(2)}';
      case PaymentMethod.cash:
        return 'Confirm Cash Payment';
    }
  }

  // ── Success Screen ────────────────────────────────────────────────────────

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success animation
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFF2ECC71).withOpacity(0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 10))
                      ],
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 54),
                  ),
                ),

                const SizedBox(height: 32),

                const Text(
                  'Payment Successful!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Amount of ₹${widget.total.toStringAsFixed(2)} has been received.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14, color: Colors.white.withOpacity(0.45)),
                ),

                const SizedBox(height: 8),

                Text(
                  _methodLabel(),
                  style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF2ECC71),
                      fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 40),

                // Bill saved indicator
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(14),
                    border:
                    Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3498DB).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.receipt_long_rounded,
                            color: Color(0xFF3498DB), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Bill Saved',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                            Text('Recorded in Sales History',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.35))),
                          ],
                        ),
                      ),
                      const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF2ECC71), size: 20),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Download / Share Bill Button ──────────────────
                GestureDetector(
                  onTap: _isGeneratingPdf
                      ? null
                      : () async {
                    setState(() => _isGeneratingPdf = true);
                    try {
                      await BillPdfService.generateAndShare(
                        context: context,
                        storeName: _storeName,
                        cartItems: _cartSnapshot,
                        total: widget.total,
                        paymentMethod: _methodLabel(),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        backgroundColor: const Color(0xFFE74C3C),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        content: Text(
                          'Could not generate PDF: $e',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        ),
                      ));
                    } finally {
                      if (mounted) setState(() => _isGeneratingPdf = false);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF3498DB).withOpacity(0.4),
                      ),
                    ),
                    child: _isGeneratingPdf
                        ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF3498DB)),
                        ),
                      ),
                    )
                        : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.picture_as_pdf_rounded,
                            color: Color(0xFF3498DB), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Download / Share Bill',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3498DB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Done Button ───────────────────────────────────
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF2ECC71), Color(0xFF27AE60)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFF2ECC71).withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6))
                      ],
                    ),
                    child: const Text(
                      'Done',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _methodLabel() {
    switch (_selectedMethod) {
      case PaymentMethod.upi:
        return 'Paid via UPI';
      case PaymentMethod.card:
        return 'Paid via Credit/Debit Card';
      case PaymentMethod.cash:
        return 'Paid via Cash';
    }
  }
}

// ─── Text Input Formatters ───────────────────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(' ', '');
    if (text.length > 16) text = text.substring(0, 16);
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    final formatted = buffer.toString();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll('/', '');
    if (text.length > 4) text = text.substring(0, 4);
    if (text.length >= 3) {
      text = '${text.substring(0, 2)}/${text.substring(2)}';
    }
    return newValue.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}