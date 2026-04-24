import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart' as ap;
import 'otp_screen.dart';

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});
  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen>
    with SingleTickerProviderStateMixin {
  final _phoneCtrl = TextEditingController();
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
    _fadeAnim =
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween(
        begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    final raw = _phoneCtrl.text.trim();
    if (raw.length < 10) {
      kSnack(context, 'Enter a valid 10-digit mobile number', ok: false);
      return;
    }
    final auth = context.read<ap.AuthProvider>();
    await auth.sendOtp(raw);
    if (!mounted) return;
    if (auth.error != null) {
      kSnack(context, auth.error!, ok: false);
      auth.clearError();
      return;
    }
    // Navigate to OTP screen
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const OtpScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<ap.AuthProvider>();

    return Scaffold(
      backgroundColor: K.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 56),

                      // ── Logo ─────────────────────────────
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: K.surfaceEl,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: K.green.withOpacity(0.3), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                                color: K.green.withOpacity(0.18),
                                blurRadius: 28,
                                spreadRadius: 1),
                          ],
                        ),
                        child: const Icon(Icons.storefront_rounded,
                            color: K.green, size: 30),
                      ),

                      const SizedBox(height: 32),

                      // ── Headline ─────────────────────────
                      const Text(
                        'Welcome to\nSmart Kirana',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: K.t1,
                          height: 1.15,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Enter your mobile number to get started',
                        style: TextStyle(
                            fontSize: 14, color: K.t2, height: 1.5),
                      ),

                      const SizedBox(height: 44),

                      // ── Phone Field ──────────────────────
                      const Text(
                        'MOBILE NUMBER',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: K.t3,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Container(
                        decoration: BoxDecoration(
                          color: K.surfaceEl,
                          borderRadius: BorderRadius.circular(K.r2),
                          border: Border.all(color: K.b2),
                        ),
                        child: Row(children: [
                          // Country code prefix
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border(
                                  right: BorderSide(color: K.b2)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('🇮🇳',
                                    style: TextStyle(fontSize: 18)),
                                SizedBox(width: 6),
                                Text('+91',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: K.t1)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              style: const TextStyle(
                                  color: K.t1,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2),
                              decoration: const InputDecoration(
                                hintText: '98765 43210',
                                hintStyle: TextStyle(
                                    color: K.t3,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 0.5),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                              ),
                              onSubmitted: (_) => _submit(),
                            ),
                          ),
                        ]),
                      ),

                      const SizedBox(height: 10),
                      Row(children: [
                        const Icon(Icons.lock_outline_rounded,
                            color: K.t3, size: 13),
                        const SizedBox(width: 5),
                        Text(
                          'We\'ll send a 6-digit OTP to verify',
                          style: TextStyle(
                              fontSize: 12,
                              color: K.t3.withOpacity(0.8)),
                        ),
                      ]),

                      const SizedBox(height: 36),

                      // ── Demo hint ────────────────────────
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: K.green.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(K.r2),
                          border: Border.all(color: K.green.withOpacity(0.2)),
                        ),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Icon(Icons.info_outline_rounded, color: K.green, size: 15),
                          const SizedBox(width: 8),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Demo Mode',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: K.green)),
                            const SizedBox(height: 3),
                            Text('Use +91 90998 19142 with OTP 280106',
                                style: const TextStyle(fontSize: 12, color: K.t2, height: 1.4)),
                          ])),
                        ]),
                      ),

                      const SizedBox(height: 16),

                      // ── Send OTP Button ──────────────────
                      KBtn(
                        label: 'Send OTP',
                        icon: Icons.sms_rounded,
                        loading: auth.loading,
                        onTap: _submit,
                      ),

                      const Spacer(),
                      const SizedBox(height: 24),

                      // ── Footer ───────────────────────────
                      Center(
                        child: Text(
                          'Smart Kirana · Inventory & Billing',
                          style: TextStyle(
                              fontSize: 12,
                              color: K.t3.withOpacity(0.6),
                              letterSpacing: 0.3),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}