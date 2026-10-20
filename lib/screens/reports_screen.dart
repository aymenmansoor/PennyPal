import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/transaction_entry.dart';
import '../services/firestore_service.dart';
import '../services/user_preferences_service.dart';
import '../widgets/pennypal_widgets.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int days = 90;
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final money = UserPreferencesService.instance.money;
    return Scaffold(
      appBar: AppBar(title: const Text('Reports & insights')),
      body: StreamBuilder<List<TransactionEntry>>(
        stream: FirestoreService.instance.transactions(uid),
        builder: (context, s) {
          if (!s.hasData)
            return const Center(child: CircularProgressIndicator());
          final cutoff = DateTime.now().subtract(Duration(days: days));
          final all = s.data!.where((x) => x.date.isAfter(cutoff)).toList();
          if (all.isEmpty)
            return const EmptyState(
              icon: Icons.insights_outlined,
              title: 'No insights yet',
              message:
                  'Add transactions and PennyPal will turn them into useful trends.',
            );
          final income = all.where((x) => x.type == 'income').toList();
          final expenses = all.where((x) => x.type == 'expense').toList();
          final ti = income.fold<double>(0, (a, b) => a + b.amount),
              te = expenses.fold<double>(0, (a, b) => a + b.amount),
              net = ti - te;
          final by = <String, double>{};
          for (final x in expenses) {
            by[x.category] = (by[x.category] ?? 0) + x.amount;
          }
          final rows = by.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final avgSpend = te / (days / 30);
          final months = <String, List<double>>{};
          for (final x in all) {
            final k =
                '${x.date.year}-${x.date.month.toString().padLeft(2, '0')}';
            months.putIfAbsent(k, () => [0, 0]);
            months[k]![x.type == 'income' ? 0 : 1] += x.amount;
          }
          final monthRows = months.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
            children: [
              Text(
                'Your money story',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Trends, categories and savings performance in one place.',
                style: TextStyle(color: Color(0xFF71807A)),
              ),
              const SizedBox(height: 14),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 30, label: Text('30d')),
                  ButtonSegment(value: 90, label: Text('90d')),
                  ButtonSegment(value: 365, label: Text('1y')),
                ],
                selected: {days},
                onSelectionChanged: (x) => setState(() => days = x.first),
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 900 ? 4 : 2;
                  const gap = 12.0;
                  final cardWidth = (constraints.maxWidth - gap * (columns - 1)) / columns;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      _Metric('Income', money.format(ti), Icons.south_west_rounded, AppTheme.brand, width: cardWidth),
                      _Metric('Expenses', money.format(te), Icons.north_east_rounded, const Color(0xFFB94B4B), width: cardWidth),
                      _Metric(net >= 0 ? 'Net saved' : 'Net overspent', money.format(net.abs()), Icons.savings_outlined, net >= 0 ? AppTheme.brand : const Color(0xFFB94B4B), width: cardWidth),
                      _Metric('Avg monthly spend', money.format(avgSpend), Icons.calendar_month_outlined, const Color(0xFF6C63D9), width: cardWidth),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle('Monthly income vs expenses'),
                      const SizedBox(height: 16),
                      ...monthRows.take(12).map((e) {
                        final max = math.max(e.value[0], e.value[1]);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 7),
                              _Bar(
                                label: 'Income',
                                value: e.value[0],
                                max: max,
                                color: AppTheme.brand,
                                money: money,
                              ),
                              const SizedBox(height: 5),
                              _Bar(
                                label: 'Expense',
                                value: e.value[1],
                                max: max,
                                color: const Color(0xFFE66B6B),
                                money: money,
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (rows.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle('Expense distribution'),
                        const SizedBox(height: 16),
                        Center(
                          child: SizedBox(
                            width: 180,
                            height: 180,
                            child: CustomPaint(
                              painter: _DonutPainter(
                                rows.map((e) => e.value).toList(),
                              ),
                              child: Center(
                                child: Text(
                                  money.format(te),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...rows.take(8).toList().asMap().entries.map((item) {
                          final p = te == 0 ? 0.0 : item.value.value / te;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: _palette[item.key % _palette.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.value.key,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${(p * 100).toStringAsFixed(0)}% • ${money.format(item.value.value)}',
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              if (rows.isNotEmpty)
                Card(
                  color: AppTheme.mint,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppTheme.brand,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${rows.first.key} is your largest expense category in this period. It represents ${te == 0 ? '0' : (rows.first.value / te * 100).toStringAsFixed(0)}% of spending.',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final double width;
  const _Metric(this.label, this.value, this.icon, this.color, {required this.width});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Card(
      color: color.withValues(alpha: .06),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            Text(label, style: const TextStyle(color: Color(0xFF71807A))),
          ],
        ),
      ),
    ),
  );
}

class _Bar extends StatelessWidget {
  final String label;
  final double value, max;
  final Color color;
  final dynamic money;
  const _Bar({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    required this.money,
  });
  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 65,
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: max <= 0 ? 0 : value / max,
            minHeight: 9,
            backgroundColor: const Color(0xFFEDF1EF),
            color: color,
          ),
        ),
      ),
      const SizedBox(width: 8),
      SizedBox(
        width: 90,
        child: Text(
          money.format(value),
          textAlign: TextAlign.end,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}

const _palette = [
  Color(0xFF0F6B52),
  Color(0xFFF4B942),
  Color(0xFF6C63D9),
  Color(0xFFE66B6B),
  Color(0xFF4A90D9),
  Color(0xFF8B6F47),
];

class _DonutPainter extends CustomPainter {
  final List<double> values;
  _DonutPainter(this.values);
  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (a, b) => a + b);
    var start = -math.pi / 2;
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22;
    for (var i = 0; i < values.length; i++) {
      final sweep = total == 0 ? 0.0 : values[i] / total * math.pi * 2;
      paint.color = _palette[i % _palette.length];
      canvas.drawArc(rect.deflate(16), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.values != values;
}
