import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../models/customer_model.dart';
import '../../services/firebase_service.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});
  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _nameCtrl   = TextEditingController();
  final _phoneCtrl  = TextEditingController();
  final _creditCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() { _nameCtrl.dispose(); _phoneCtrl.dispose(); _creditCtrl.dispose(); super.dispose(); }

  void _save() async {
    final name   = _nameCtrl.text.trim();
    final phone  = _phoneCtrl.text.trim();
    final credit = double.tryParse(_creditCtrl.text.trim()) ?? 0;

    if (name.isEmpty)  { kSnack(context, 'Enter customer name', ok: false); return; }
    if (phone.isEmpty) { kSnack(context, 'Enter phone number', ok: false); return; }
    if (credit <= 0)   { kSnack(context, 'Enter a valid credit amount', ok: false); return; }

    setState(() => _loading = true);
    try {
      await FirebaseService().addCustomer(Customer(id: '', name: name, phone: phone, totalCredit: credit, totalPaid: 0, createdAt: DateTime.now()));
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      kSnack(context, 'Error: $e', ok: false);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: K.bg,
      body: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const KBack(),
          const SizedBox(height: 12),
          const Text('Add Customer', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: K.t1, letterSpacing: -0.5)),
          const Text('Fill in customer details', style: TextStyle(fontSize: 13, color: K.t2)),
        ])),
        const SizedBox(height: 24),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(children: [
          KField(controller: _nameCtrl, label: 'Customer Name', hint: 'e.g. Ramesh Kumar', icon: Icons.person_rounded),
          const SizedBox(height: 16),
          KField(controller: _phoneCtrl, label: 'Phone Number', hint: 'e.g. 9876543210', icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone, formatters: [FilteringTextInputFormatter.digitsOnly]),
          const SizedBox(height: 16),
          KField(controller: _creditCtrl, label: 'Credit Amount (₹)', hint: 'e.g. 500.00', icon: Icons.currency_rupee_rounded,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              formatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))]),
          const SizedBox(height: 32),
          KBtn(label: 'Add Customer', icon: Icons.person_add_rounded, loading: _loading, onTap: _save),
          const SizedBox(height: 24),
        ]))),
      ])),
    );
  }
}