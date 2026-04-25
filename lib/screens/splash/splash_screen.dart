import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../auth/auth_wrapper.dart';
import '../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoCtrl, _textCtrl, _pulseCtrl, _dotsCtrl;
  late Animation<double> _logoScale, _logoOpacity, _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    _logoCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _textCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _dotsCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

    _logoScale   = Tween(begin: 0.55, end: 1.0).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _logoCtrl, curve: const Interval(0, 0.4, curve: Curves.easeIn)));
    _textOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _textSlide   = Tween(begin: const Offset(0, 0.35), end: Offset.zero).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));
    _pulse       = Tween(begin: 0.8, end: 1.15).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _logoCtrl.forward().then((_) => _textCtrl.forward());

    Future.delayed(const Duration(milliseconds: 3200), () {
      if (!mounted) return;
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      Navigator.pushReplacement(context, PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (_, __, ___) => const AuthWrapper(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      ));
    });
  }

  @override
  void dispose() {
    _logoCtrl.dispose(); _textCtrl.dispose(); _pulseCtrl.dispose(); _dotsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: K.bg,
      body: Stack(children: [
        // Ambient glow
        Center(child: AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) => Transform.scale(scale: _pulse.value,
              child: Container(width: 280, height: 280,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [K.green.withOpacity(0.07), Colors.transparent])))),
        )),

        // Dot grids — decorative
        Positioned(top: 70, right: 28, child: _DotGrid(opacity: 0.055)),
        Positioned(bottom: 90, left: 18, child: _DotGrid(opacity: 0.04)),

        // Core content
        Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Logo
          AnimatedBuilder(animation: _logoCtrl, builder: (_, __) =>
              Opacity(opacity: _logoOpacity.value,
                  child: Transform.scale(scale: _logoScale.value,
                      child: Container(width: 100, height: 100,
                          decoration: BoxDecoration(
                            color: K.surfaceEl,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: K.green.withOpacity(0.3), width: 1.5),
                            boxShadow: [
                              BoxShadow(color: K.green.withOpacity(0.2), blurRadius: 36, spreadRadius: 2),
                              BoxShadow(color: K.green.withOpacity(0.07), blurRadius: 70, spreadRadius: 12),
                            ],
                          ),
                          child: const Icon(Icons.storefront_rounded, color: K.green, size: 48))))),

          const SizedBox(height: 30),

          // Text
          FadeTransition(opacity: _textOpacity, child: SlideTransition(position: _textSlide,
              child: Column(children: [
                const Text('Kirana',
                    style: TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: K.t1, letterSpacing: -1.2)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: K.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: K.green.withOpacity(0.2)),
                  ),
                  child: const Text('Smart Inventory & Billing',
                      style: TextStyle(fontSize: 13, color: K.green, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                ),
              ]))),

          const SizedBox(height: 60),

          AnimatedBuilder(animation: _dotsCtrl,
              builder: (_, __) => _BounceDots(progress: _dotsCtrl.value)),
        ])),

        // Version
        FadeTransition(opacity: _textOpacity,
            child: const Positioned(bottom: 32, left: 0, right: 0,
                child: Center(child: Text('v1.0.0', style: TextStyle(fontSize: 12, color: K.t3, letterSpacing: 1))))),
      ]),
    );
  }
}

class _DotGrid extends StatelessWidget {
  final double opacity;
  const _DotGrid({required this.opacity});
  @override
  Widget build(BuildContext context) => Opacity(opacity: opacity,
      child: SizedBox(width: 90, height: 90, child: CustomPaint(painter: _DotPainter())));
}

class _DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = K.green;
    for (double x = 0; x < size.width; x += 14)
      for (double y = 0; y < size.height; y += 14)
        canvas.drawCircle(Offset(x, y), 1.5, p);
  }
  @override bool shouldRepaint(_) => false;
}

class _BounceDots extends StatelessWidget {
  final double progress;
  const _BounceDots({required this.progress});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final delay = i / 3;
          final t = ((progress - delay) % 1.0 + 1.0) % 1.0;
          final scale   = 0.55 + 0.65 * sin(t * pi).clamp(0.0, 1.0);
          final opacity = 0.25 + 0.75 * sin(t * pi).clamp(0.0, 1.0);
          return Container(margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(scale: scale,
                  child: Opacity(opacity: opacity,
                      child: Container(width: 7, height: 7,
                          decoration: const BoxDecoration(color: K.green, shape: BoxShape.circle)))));
        }));
  }
}