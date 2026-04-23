import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/firebase_service.dart';
import '../../providers/product_provider.dart';
import '../inventory/product_list_screen.dart';
import '../billing/billing_screen.dart';
import '../sales/sales_history_screen.dart';
import '../udhaar/udhaar_screen.dart';
import '../subscription/subscription_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _tab = 0;
  final _svc = FirebaseService();
  late AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
    context.read<ProductProvider>().init();
  }

  @override
  void dispose() { _fadeCtrl.dispose(); super.dispose(); }

  Widget get _page {
    switch (_tab) {
      case 0: return _Dashboard(svc: _svc, onMenu: _showMenu);
      case 1: return ProductListScreen(embedded: true);
      case 2: return BillingScreen(embedded: true);
      case 3: return SalesHistoryScreen(embedded: true);
      default: return UdhaarScreen(embedded: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: K.surface,
      ),
      child: Scaffold(
        backgroundColor: K.bg,
        resizeToAvoidBottomInset: false,
        body: FadeTransition(opacity: _fadeCtrl, child: _page),
        bottomNavigationBar: _BottomBar(current: _tab, onTap: (i) => setState(() => _tab = i)),
      ),
    );
  }

  void _showMenu(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: K.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(K.r4))),
      builder: (_) => _MenuSheet(svc: _svc),
    );
  }
}

// ─── Bottom Bar ──────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _BottomBar({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      (icon: Icons.home_rounded, label: 'Home'),
      (icon: Icons.inventory_2_rounded, label: 'Inventory'),
      (icon: Icons.receipt_long_rounded, label: 'Billing'),
      (icon: Icons.bar_chart_rounded, label: 'Sales'),
      (icon: Icons.account_balance_wallet_rounded, label: 'Udhaar'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: K.surface,
        border: Border(top: BorderSide(color: K.b1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, -6))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final active = current == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
                    decoration: BoxDecoration(
                      color: active ? K.green.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(K.r1),
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      AnimatedScale(scale: active ? 1.1 : 1.0, duration: const Duration(milliseconds: 200),
                          child: Icon(item.icon, color: active ? K.green : K.t3, size: active ? 28 : 26)),
                      const SizedBox(height: 3),
                      Text(item.label, style: TextStyle(fontSize: 10,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                          color: active ? K.green : K.t3)),
                    ]),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─── Dashboard ───────────────────────────────────────────────────────────────

class _Dashboard extends StatelessWidget {
  final FirebaseService svc;
  final Function(BuildContext) onMenu;
  const _Dashboard({required this.svc, required this.onMenu});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final h = now.hour;
    final greeting = h < 12 ? '☀️ Good Morning' : h < 17 ? '🌤 Good Afternoon' : '🌙 Good Evening';

    return SafeArea(
      child: CustomScrollView(slivers: [
        // ── Header ──────────────────────────────────────────
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(greeting, style: const TextStyle(fontSize: 13, color: K.t2, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              StreamBuilder<String>(
                stream: svc.getStoreName(),
                builder: (_, s) => Text(s.data ?? 'Kirana Store',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: K.t1, letterSpacing: -0.5)),
              ),
            ]),
            Builder(builder: (ctx) => GestureDetector(
              onTap: () => onMenu(ctx),
              child: Container(width: 44, height: 44,
                  decoration: BoxDecoration(color: K.surfaceEl, borderRadius: BorderRadius.circular(K.r2), border: Border.all(color: K.b2)),
                  child: const Icon(Icons.menu_rounded, color: K.green, size: 22)),
            )),
          ]),
        )),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // ── Stats 2x2 ─────────────────────────────────────
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: StreamBuilder(
            stream: svc.getBills(),
            builder: (_, billSnap) {
              double today = 0, month = 0; int todayBills = 0;
              if (billSnap.hasData) {
                final t = DateTime.now();
                for (final b in billSnap.data!) {
                  final sameDay = b.date.year==t.year && b.date.month==t.month && b.date.day==t.day;
                  final sameMo = b.date.year==t.year && b.date.month==t.month;
                  if (sameDay) { today += b.total; todayBills++; }
                  if (sameMo) month += b.total;
                }
              }
              return Column(children: [
                Row(children: [
                  KStat(label: "Today's Sales", value: '₹${today.toStringAsFixed(0)}', color: K.green, icon: Icons.trending_up_rounded),
                  const SizedBox(width: 12),
                  KStat(label: 'Monthly Revenue', value: '₹${month.toStringAsFixed(0)}', color: K.blue, icon: Icons.calendar_month_rounded),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  StreamBuilder(stream: svc.getProducts(), builder: (_, s) =>
                      KStat(label: 'Products', value: '${s.data?.length ?? 0}', color: K.purple, icon: Icons.inventory_2_rounded)),
                  const SizedBox(width: 12),
                  KStat(label: "Today's Bills", value: '$todayBills', color: K.amber, icon: Icons.receipt_long_rounded),
                ]),
              ]);
            },
          ),
        )),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // ── Low Stock Alert ────────────────────────────────
        SliverToBoxAdapter(child: StreamBuilder(
          stream: svc.getProducts(),
          builder: (_, s) {
            if (!s.hasData) return const SizedBox();
            final low = s.data!.where((p) => p.quantity > 0 && p.quantity <= 5).toList();
            final out = s.data!.where((p) => p.quantity <= 0).toList();
            if (low.isEmpty && out.isEmpty) return const SizedBox();
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Container(
                padding: const EdgeInsets.all(K.md),
                decoration: BoxDecoration(
                  color: K.amber.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(K.r3),
                  border: Border.all(color: K.amber.withOpacity(0.22)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.warning_amber_rounded, color: K.amber, size: 15),
                    const SizedBox(width: 7),
                    Text(
                      out.isNotEmpty ? '${out.length} out of stock · ${low.length} low' : '${low.length} products running low',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: K.amber),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Wrap(spacing: 7, runSpacing: 6,
                    children: [...out, ...low].take(5).map((p) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: p.quantity <= 0 ? K.red.withOpacity(0.1) : K.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: p.quantity <= 0 ? K.red.withOpacity(0.25) : K.amber.withOpacity(0.25)),
                      ),
                      child: Text(
                        p.quantity <= 0 ? '${p.name} · Out' : '${p.name} · ${p.quantityDisplay}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                            color: p.quantity <= 0 ? K.red : K.amber),
                      ),
                    )).toList(),
                  ),
                ]),
              ),
            );
          },
        )),

        // ── Recent Bills ───────────────────────────────────
        const SliverToBoxAdapter(child: Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: KLabel('Recent Bills'),
        )),

        SliverToBoxAdapter(child: StreamBuilder(
          stream: svc.getBills(),
          builder: (_, s) {
            if (!s.hasData || s.data!.isEmpty) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Container(
                  padding: const EdgeInsets.all(K.lg),
                  decoration: BoxDecoration(color: K.surface, borderRadius: BorderRadius.circular(K.r3), border: Border.all(color: K.b1)),
                  child: Column(children: [
                    const Icon(Icons.receipt_long_outlined, color: K.t3, size: 36),
                    const SizedBox(height: 10),
                    const Text('No bills yet', style: TextStyle(color: K.t2, fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    const Text('Tap Billing below to create your first bill', style: TextStyle(color: K.t3, fontSize: 12)),
                  ]),
                ),
              );
            }
            final bills = s.data!.reversed.take(5).toList();
            const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(children: bills.asMap().entries.map((e) {
                final bill = e.value; final idx = e.key;
                final hh = bill.date.hour > 12 ? bill.date.hour-12 : (bill.date.hour==0?12:bill.date.hour);
                final mm = bill.date.minute.toString().padLeft(2,'0');
                final pp = bill.date.hour >= 12 ? 'PM' : 'AM';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(K.md),
                  decoration: BoxDecoration(color: K.surface, borderRadius: BorderRadius.circular(K.r2), border: Border.all(color: K.b1)),
                  child: Row(children: [
                    Container(width: 40, height: 40,
                        decoration: BoxDecoration(color: K.green.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.receipt_rounded, color: K.green, size: 18)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Bill #${idx+1}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: K.t1)),
                      Text('${bill.date.day} ${months[bill.date.month-1]} · $hh:$mm $pp',
                          style: const TextStyle(fontSize: 12, color: K.t2)),
                    ])),
                    Text('₹${bill.total.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: K.green)),
                  ]),
                );
              }).toList()),
            );
          },
        )),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ]),
    );
  }
}

// ─── Menu Sheet ───────────────────────────────────────────────────────────────

class _MenuSheet extends StatelessWidget {
  final FirebaseService svc;
  const _MenuSheet({required this.svc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: K.b3, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Row(children: [
          Container(width: 48, height: 48,
              decoration: BoxDecoration(color: K.green.withOpacity(0.1), borderRadius: BorderRadius.circular(K.r2)),
              child: const Icon(Icons.storefront_rounded, color: K.green, size: 24)),
          const SizedBox(width: 14),
          StreamBuilder<String>(
            stream: svc.getStoreName(),
            builder: (_, s) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.data ?? 'Kirana Store', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: K.t1)),
              const Text('Kirana App v1.0.0', style: TextStyle(fontSize: 12, color: K.t2)),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        Divider(color: K.b1),
        const SizedBox(height: 8),
        _tile(context, Icons.store_rounded, 'Edit Store Name', K.blue, () {
          Navigator.pop(context); _editName(context);
        }),
        const SizedBox(height: 6),
        _tile(context, Icons.workspace_premium_rounded, 'Subscription', K.amber, () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => SubscriptionScreen()));
        }),
        const SizedBox(height: 6),
        _tile(context, Icons.info_outline_rounded, 'About', K.purple, () {
          Navigator.pop(context); _about(context);
        }),
      ]),
    );
  }

  Widget _tile(BuildContext ctx, IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(color: K.surfaceEl, borderRadius: BorderRadius.circular(K.r2)),
        child: Row(children: [
          Container(width: 34, height: 34,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, color: color, size: 17)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: K.t1)),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios_rounded, color: K.t3, size: 13),
        ]),
      ),
    );
  }

  void _editName(BuildContext ctx) {
    final ctrl = TextEditingController();
    svc.getStoreName().first.then((n) => ctrl.text = n);
    showDialog(context: ctx, builder: (_) => AlertDialog(
      backgroundColor: K.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(K.r3)),
      title: const Text('Edit Store Name', style: TextStyle(color: K.t1, fontWeight: FontWeight.w600)),
      content: Container(
        decoration: BoxDecoration(color: K.surfaceEl, borderRadius: BorderRadius.circular(K.r2), border: Border.all(color: K.b2)),
        child: TextField(controller: ctrl, style: const TextStyle(color: K.t1),
            decoration: const InputDecoration(hintText: 'Store name', hintStyle: TextStyle(color: K.t3),
                border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: K.t2))),
        TextButton(onPressed: () async {
          final name = ctrl.text.trim();
          if (name.isEmpty) return;
          await svc.updateStoreName(name);
          if (!ctx.mounted) return;
          Navigator.pop(ctx);
          kSnack(ctx, '✓ Store name updated!');
        }, child: const Text('Save', style: TextStyle(color: K.green, fontWeight: FontWeight.w700))),
      ],
    ));
  }

  void _about(BuildContext ctx) {
    showDialog(context: ctx, builder: (_) => AlertDialog(
      backgroundColor: K.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(K.r3)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 64, height: 64,
            decoration: BoxDecoration(color: K.green.withOpacity(0.1), borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.storefront_rounded, color: K.green, size: 32)),
        const SizedBox(height: 16),
        const Text('Kirana Store', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: K.t1)),
        const SizedBox(height: 8),
        const Text('Smart Inventory & Billing\nVersion 1.0.0', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: K.t2)),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: K.green)))],
    ));
  }
}