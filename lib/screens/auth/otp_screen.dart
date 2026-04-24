import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart' as ap;
import '../home/home_screen.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with SingleTickerProviderStateMixin {
  // 6 individual controllers + focus nodes
  final List<TextEditingController> _ctrls =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes =
  List.generate(6, (_) => FocusNode());

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Resend countdown
  int _countdown = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    _fadeAnim =
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween(
        begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic));

    _startTimer();
    // Auto-focus first box
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _nodes[0].requestFocus());
  }

  void _startTimer() {
    _countdown = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 0) {
        t.cancel();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    for (final n in _nodes) n.dispose();
    _fadeCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String get _otp => _ctrls.map((c) => c.text).join();

  void _onKey(int i, String val) {
    if (val.isEmpty) {
      // Backspace — go back
      if (i > 0) {
        _ctrls[i].clear();
        _nodes[i - 1].requestFocus();
      }
      return;
    }
    // Handle paste (6 digits at once)
    if (val.length > 1) {
      final digits = val.replaceAll(RegExp(r'\D'), '');
      for (int j = 0; j < 6 && j < digits.length; j++) {
        _ctrls[j].text = digits[j];
      }
      _nodes[5].requestFocus();
      setState(() {});
      if (digits.length >= 6) _verify();
      return;
    }
    _ctrls[i].text = val;
    setState(() {});
    if (i < 5) {
      _nodes[i + 1].requestFocus();
    } else {
      _nodes[i].unfocus();
      _verify();
    }
  }

  Future<void> _verify() async {
    final otp = _otp;
    if (otp.length < 6) {
      kSnack(context, 'Enter all 6 digits', ok: false);
      return;
    }
    final auth = context.read<ap.AuthProvider>();
    final success = await auth.verifyOtp(otp);
    if (!mounted) return;

    if (success) {
      // Clear the entire navigation stack and go to HomeScreen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomeScreen()),
            (route) => false,
      );
    } else {
      kSnack(context, auth.error ?? 'Invalid OTP', ok: false);
      auth.clearError();
      for (final c in _ctrls) c.clear();
      _nodes[0].requestFocus();
      setState(() {});
    }
  }

  Future<void> _resend() async {
    if (_countdown > 0) return;
    final auth = context.read<ap.AuthProvider>();
    await auth.resendOtp();
    if (!mounted) return;
    if (auth.error != null) {
      kSnack(context, auth.error!, ok: false);
      auth.clearError();
    } else {
      _startTimer();
      kSnack(context, 'OTP resent successfully ✓');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<ap.AuthProvider>();
    final phone = auth.phoneNumber;
    final maskedPhone = phone.length >= 10
        ? '${phone.substring(0, phone.length - 7)}•••••${phone.substring(phone.length - 2)}'
        : phone;

    return Scaffold(
      backgroundColor: K.bg,
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
                      const SizedBox(height: 24),

                      // ── Back ──────────────────────────────
                      GestureDetector(
                        onTap: () {
                          auth.resetToPhone();
                          Navigator.pop(context);
                        },
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.arrow_back_ios_rounded,
                              color: K.t2, size: 14),
                          const SizedBox(width: 4),
                          Text('Change number',
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: K.t2,
                                  fontWeight: FontWeight.w500)),
                        ]),
                      ),

                      const SizedBox(height: 40),

                      // ── OTP Icon ─────────────────────────
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: K.green.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: K.green.withOpacity(0.25), width: 1.5),
                        ),
                        child: const Icon(Icons.sms_rounded,
                            color: K.green, size: 28),
                      ),

                      const SizedBox(height: 28),

                      const Text(
                        'Enter OTP',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: K.t1,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                              fontSize: 14, color: K.t2, height: 1.5),
                          children: [
                            const TextSpan(text: 'We sent a 6-digit code to '),
                            TextSpan(
                              text: maskedPhone,
                              style: const TextStyle(
                                  color: K.t1, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // ── OTP Boxes ─────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (i) {
                          final filled = _ctrls[i].text.isNotEmpty;
                          return _OtpBox(
                            controller: _ctrls[i],
                            focusNode: _nodes[i],
                            filled: filled,
                            onChanged: (val) => _onKey(i, val),
                          );
                        }),
                      ),

                      const SizedBox(height: 12),

                      // ── Error display ─────────────────────
                      if (auth.error != null)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          child: Row(children: [
                            const Icon(Icons.error_outline_rounded,
                                color: K.red, size: 13),
                            const SizedBox(width: 6),
                            Text(auth.error!,
                                style: const TextStyle(
                                    color: K.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500)),
                          ]),
                        ),

                      const SizedBox(height: 16),

                      // ── Demo OTP hint ─────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: K.green.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(K.r2),
                          border: Border.all(color: K.green.withOpacity(0.18)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.info_outline_rounded, color: K.green, size: 14),
                          const SizedBox(width: 8),
                          const Text('Demo OTP: ',
                              style: TextStyle(fontSize: 12, color: K.t2)),
                          const Text('2  8  0  1  0  6',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                                  color: K.green, letterSpacing: 2)),
                        ]),
                      ),

                      const SizedBox(height: 16),

                      // ── Verify Button ─────────────────────
                      KBtn(
                        label: 'Verify OTP',
                        icon: Icons.verified_rounded,
                        loading: auth.loading,
                        onTap: _otp.length == 6 ? _verify : null,
                      ),

                      const SizedBox(height: 24),

                      // ── Resend ────────────────────────────
                      Center(
                        child: GestureDetector(
                          onTap: _countdown == 0 ? _resend : null,
                          child: AnimatedOpacity(
                            opacity: _countdown == 0 ? 1.0 : 0.5,
                            duration: const Duration(milliseconds: 300),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.refresh_rounded,
                                    color: K.green, size: 15),
                                const SizedBox(width: 6),
                                Text(
                                  _countdown > 0
                                      ? 'Resend OTP in ${_countdown}s'
                                      : 'Resend OTP',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: K.green,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const Spacer(),
                      const SizedBox(height: 24),
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

// ─── Single OTP digit box ────────────────────────────────────────────────────

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool filled;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.filled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 46,
      height: 56,
      decoration: BoxDecoration(
        color: filled ? K.green.withOpacity(0.08) : K.surfaceEl,
        borderRadius: BorderRadius.circular(K.r2),
        border: Border.all(
          color: filled ? K.green.withOpacity(0.5) : K.b2,
          width: filled ? 1.5 : 1,
        ),
        boxShadow: filled
            ? [
          BoxShadow(
              color: K.green.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ]
            : null,
      ),
      child: Center(
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6, // Allow paste
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: filled ? K.green : K.t1,
            letterSpacing: 0,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: '',
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}