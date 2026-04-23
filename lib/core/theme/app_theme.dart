import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Design Tokens ──────────────────────────────────────────────────────────

class K {
  // Backgrounds — deep charcoal, not pure black
  static const bg        = Color(0xFF0C0C12);
  static const surface   = Color(0xFF141420);
  static const surfaceEl = Color(0xFF1C1C2A);
  static const surfaceHi = Color(0xFF242432);

  // ONE primary accent — signature green
  static const green     = Color(0xFF00E68A);
  static const greenDim  = Color(0xFF00B86E);
  static const greenGlow = Color(0xFF00E68A);

  // Semantic
  static const red       = Color(0xFFFF4D6A);
  static const amber     = Color(0xFFFFAA00);
  static const blue      = Color(0xFF4D9EFF);
  static const purple    = Color(0xFF9B7FFF);

  // Text hierarchy
  static const t1        = Color(0xFFF2F2FA);   // primary
  static const t2        = Color(0xFF8080A0);   // secondary
  static const t3        = Color(0xFF444460);   // muted

  // Borders
  static const b1        = Color(0xFF1A1A2A);   // subtle
  static const b2        = Color(0xFF28283C);   // default
  static const b3        = Color(0xFF3C3C54);   // strong

  // Spacing
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;

  // Radius
  static const r1 = 10.0;
  static const r2 = 14.0;
  static const r3 = 18.0;
  static const r4 = 24.0;
}

// ─── App Theme ───────────────────────────────────────────────────────────────

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: K.bg,
    colorScheme: const ColorScheme.dark(
      primary: K.green,
      secondary: K.green,
      surface: K.surface,
      error: K.red,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: K.bg,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
      ),
    ),
    dividerTheme: const DividerThemeData(color: K.b1, thickness: 1),
  );
}

// ─── Shared Widgets ──────────────────────────────────────────────────────────

/// Primary action button — green glow style
class KBtn extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool loading;
  final bool danger;
  final bool ghost;

  const KBtn({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.loading = false,
    this.danger = false,
    this.ghost = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = danger ? K.red : ghost ? Colors.transparent : K.green;
    final Color fg = danger ? Colors.white : ghost ? K.green : Colors.black;

    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: loading ? bg.withOpacity(0.45) : bg,
          borderRadius: BorderRadius.circular(K.r2),
          border: ghost
              ? Border.all(color: K.green.withOpacity(0.4), width: 1.5)
              : null,
          boxShadow: (!ghost && !danger && !loading)
              ? [BoxShadow(color: K.green.withOpacity(0.22), blurRadius: 18, offset: const Offset(0, 6))]
              : null,
        ),
        child: loading
            ? Center(child: SizedBox(width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(fg))))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (icon != null) ...[Icon(icon, color: fg, size: 18), const SizedBox(width: 8)],
          Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: fg, letterSpacing: 0.1)),
        ]),
      ),
    );
  }
}

/// Standard card
class KCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? accent;
  final VoidCallback? onTap;

  const KCard({super.key, required this.child, this.padding, this.accent, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(K.md),
        decoration: BoxDecoration(
          color: K.surface,
          borderRadius: BorderRadius.circular(K.r3),
          border: Border.all(color: accent?.withOpacity(0.2) ?? K.b1),
        ),
        child: child,
      ),
    );
  }
}

/// Back nav row
class KBack extends StatelessWidget {
  const KBack({super.key});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.arrow_back_ios_rounded, color: K.t2, size: 14),
        const SizedBox(width: 4),
        Text('Back', style: TextStyle(fontSize: 14, color: K.t2, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

/// Input field
class KField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? formatters;
  final ValueChanged<String>? onChanged;
  final int? maxLength;
  final bool obscure;

  const KField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.formatters,
    this.onChanged,
    this.maxLength,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: K.t2, letterSpacing: 0.3)),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: K.surfaceEl,
          borderRadius: BorderRadius.circular(K.r2),
          border: Border.all(color: K.b2),
        ),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: formatters,
          obscureText: obscure,
          maxLength: maxLength,
          onChanged: onChanged,
          style: const TextStyle(color: K.t1, fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: K.t3, fontSize: 14),
            prefixIcon: Icon(icon, color: K.green.withOpacity(0.65), size: 18),
            border: InputBorder.none,
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(horizontal: K.md, vertical: K.md),
          ),
        ),
      ),
    ]);
  }
}

/// Section label
class KLabel extends StatelessWidget {
  final String text;
  const KLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: K.t3, letterSpacing: 1.4));
  }
}

/// Stat card
class KStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  const KStat({super.key, required this.label, required this.value, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(K.md),
        decoration: BoxDecoration(
          color: K.surface,
          borderRadius: BorderRadius.circular(K.r3),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: const TextStyle(fontSize: 11, color: K.t2, fontWeight: FontWeight.w500)),
            if (icon != null) Icon(icon, color: color.withOpacity(0.4), size: 15),
          ]),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.5)),
        ]),
      ),
    );
  }
}

void kSnack(BuildContext ctx, String msg, {bool ok = true}) {
  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
    backgroundColor: ok ? K.green : K.red,
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.all(16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    content: Text(msg, style: TextStyle(color: ok ? Colors.black : Colors.white,
        fontWeight: FontWeight.w600, fontSize: 13)),
  ));
}