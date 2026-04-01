import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/customer_model.dart';
import '../../services/firebase_service.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _creditController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _creditController.dispose();
    super.dispose();
  }

  void _save() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final creditText = _creditController.text.trim();

    if (name.isEmpty || phone.isEmpty || creditText.isEmpty) {
      _showSnackbar('Please fill in all fields', const Color(0xFFE74C3C));
      return;
    }

    final credit = double.tryParse(creditText);
    if (credit == null) {
      _showSnackbar('Enter valid credit amount', const Color(0xFFE74C3C));
      return;
    }

    setState(() => _isLoading = true);

    final customer = Customer(
      id: '',
      name: name,
      phone: phone,
      totalCredit: credit,
      totalPaid: 0,
      createdAt: DateTime.now(),
    );

    // FIX: await the addCustomer call
    await FirebaseService().addCustomer(customer);

    if (!mounted) return;
    setState(() => _isLoading = false);

    // FIX: show snackbar BEFORE pop using the parent context
    Navigator.pop(context);
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(message,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                'Add Customer',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Text(
                'Fill in customer details',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.35),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _inputField(
                      controller: _nameController,
                      label: 'Customer Name',
                      hint: 'e.g. Ramesh Kumar',
                      icon: Icons.person_rounded,
                      inputType: TextInputType.name,
                    ),
                    const SizedBox(height: 16),
                    _inputField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      hint: 'e.g. 9876543210',
                      icon: Icons.phone_rounded,
                      inputType: TextInputType.phone,
                      formatter: FilteringTextInputFormatter.digitsOnly,
                    ),
                    const SizedBox(height: 16),
                    _inputField(
                      controller: _creditController,
                      label: 'Credit Amount (₹)',
                      hint: 'e.g. 500.00',
                      icon: Icons.currency_rupee_rounded,
                      inputType:
                      const TextInputType.numberWithOptions(decimal: true),
                      formatter: FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ),
                    const SizedBox(height: 40),

                    GestureDetector(
                      onTap: _isLoading ? null : _save,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _isLoading
                              ? const Color(0xFFE67E22).withOpacity(0.6)
                              : const Color(0xFFE67E22),
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
                                  Colors.white),
                            ),
                          ),
                        )
                            : const Text(
                          'Add Customer',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required TextInputType inputType,
    TextInputFormatter? formatter,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.55),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: inputType,
            inputFormatters: formatter != null ? [formatter] : [],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.2),
                fontSize: 14,
              ),
              prefixIcon: Icon(icon,
                  color: const Color(0xFFE67E22).withOpacity(0.7), size: 20),
              border: InputBorder.none,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}