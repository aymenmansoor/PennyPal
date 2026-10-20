import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../models/transaction_entry.dart';
import '../services/firestore_service.dart';
import '../services/user_preferences_service.dart';
import '../widgets/pennypal_widgets.dart';
import '../widgets/responsive_layout.dart';
import 'add_transaction_screen.dart';
import 'budget_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'reports_screen.dart';
import 'ai_guidance_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final money = UserPreferencesService.instance.money;
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: StreamBuilder<List<TransactionEntry>>(
        stream: FirestoreService.instance.transactions(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load dashboard: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final tx = snapshot.data!;
          final income = tx
              .where((x) => x.type == 'income')
              .fold<double>(0, (a, b) => a + b.amount);
          final expense = tx
              .where((x) => x.type == 'expense')
              .fold<double>(0, (a, b) => a + b.amount);
          final balance = income - expense;
          final month = DateTime.now();
          final monthIncome = tx
              .where(
                (x) =>
                    x.type == 'income' &&
                    x.date.year == month.year &&
                    x.date.month == month.month,
              )
              .fold<double>(0, (a, b) => a + b.amount);
          final monthExpense = tx
              .where(
                (x) =>
                    x.type == 'expense' &&
                    x.date.year == month.year &&
                    x.date.month == month.month,
              )
              .fold<double>(0, (a, b) => a + b.amount);
          return PageFrame(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good ${_dayPart()},',
                            style: TextStyle(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFF999999)
                                  : const Color(0xFF71807A),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            FirebaseAuth.instance.currentUser?.displayName ??
                                'Student',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Alerts & reminders',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.notifications_none_rounded),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(24),
                        child: const CircleAvatar(
                          radius: 24,
                          backgroundColor: AppTheme.mint,
                          child: Icon(
                            Icons.person_rounded,
                            color: AppTheme.brand,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF0F6B52),
                        AppTheme.brand,
                        Color(0xFF1BA384),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x4D0F6B52),
                        blurRadius: 32,
                        offset: Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            color: Colors.white70,
                            size: 18,
                          ),
                          SizedBox(width: 7),
                          Text(
                            'AVAILABLE BALANCE',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: .8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        money.format(balance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _MiniMoney(
                              icon: Icons.south_west_rounded,
                              label: 'Income',
                              value: money.format(income),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 38,
                            color: Colors.white24,
                          ),
                          Expanded(
                            child: _MiniMoney(
                              icon: Icons.north_east_rounded,
                              label: 'Expenses',
                              value: money.format(expense),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const SectionTitle('Quick actions'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.add_rounded,
                        label: 'Income',
                        color: const Color(0xFFD4F5ED),
                        iconColor: const Color(0xFF059669),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AddTransactionScreen(type: 'income'),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.remove_rounded,
                        label: 'Expense',
                        color: const Color(0xFFFFDCDC),
                        iconColor: const Color(0xFFDC2626),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AddTransactionScreen(type: 'expense'),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.donut_large_rounded,
                        label: 'Budget',
                        color: const Color(0xFFFEF08A),
                        iconColor: const Color(0xFFCA8A04),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BudgetScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.insights_rounded,
                        label: 'Reports',
                        color: const Color(0xFFE9D5FF),
                        iconColor: const Color(0xFF7C3AED),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReportsScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AiGuidanceScreen(),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 24,
                            backgroundColor: AppTheme.mint,
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              color: AppTheme.brand,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ask PennyPal',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Get help with expenses, budgets, goals and your recorded spending.',
                                  style: TextStyle(
                                    color: Color(0xFF71807A),
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: AppTheme.brand,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const SectionTitle('Recent activity'),
                const SizedBox(height: 12),
                if (tx.isEmpty)
                  const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No transactions yet',
                    message:
                        'Add your first income or expense to bring your dashboard to life.',
                  )
                else
                  Card(
                    child: Column(
                      children: tx
                          .take(5)
                          .map((t) => _TransactionRow(t: t, money: money))
                          .toList(),
                    ),
                  ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'This month snapshot',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat('MMMM yyyy').format(month),
                          style: const TextStyle(color: Color(0xFF71807A)),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _SnapshotMetric(
                                label: 'Income',
                                value: money.format(monthIncome),
                                icon: Icons.south_west_rounded,
                                color: const Color(0xFF059669),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SnapshotMetric(
                                label: 'Spent',
                                value: money.format(monthExpense),
                                icon: Icons.north_east_rounded,
                                color: const Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _SnapshotMetric(
                          label: monthIncome - monthExpense >= 0
                              ? 'Net saved'
                              : 'Net overspend',
                          value: money.format(
                            (monthIncome - monthExpense).abs(),
                          ),
                          icon: monthIncome - monthExpense >= 0
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          color: monthIncome - monthExpense >= 0
                              ? AppTheme.brand
                              : const Color(0xFFDC2626),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Financial Summary',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SummaryRow(
                          icon: Icons.south_west_rounded,
                          label: 'Total Income',
                          amount: money.format(income),
                          color: const Color(0xFF059669),
                        ),
                        const SizedBox(height: 12),
                        _SummaryRow(
                          icon: Icons.north_east_rounded,
                          label: 'Total Expenses',
                          amount: money.format(expense),
                          color: const Color(0xFFDC2626),
                        ),
                        const SizedBox(height: 12),
                        Container(height: 1, color: const Color(0xFFE5E5E5)),
                        const SizedBox(height: 12),
                        _SummaryRow(
                          icon: Icons.account_balance_wallet_rounded,
                          label: 'Available Balance',
                          amount: money.format(balance),
                          color: AppTheme.brand,
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.mint,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            color: AppTheme.brand,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'This month',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${DateFormat.MMMM().format(month)} spending',
                                style: const TextStyle(
                                  color: Color(0xFF71807A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          money.format(monthExpense),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        ),
      ),
    );
  }

  static String _dayPart() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }
}

class _SnapshotMetric extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _SnapshotMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF71807A),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MiniMoney extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _MiniMoney({
    required this.icon,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color, iconColor;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252525) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Color.lerp(color, const Color(0xFF121212), 0.5)!
                      : color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final TransactionEntry t;
  final NumberFormat money;
  const _TransactionRow({required this.t, required this.money});
  @override
  Widget build(BuildContext context) {
    final income = t.type == 'income';
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: income
            ? const Color(0xFFE5F7EF)
            : const Color(0xFFFFEEEE),
        child: Icon(
          income ? Icons.south_west_rounded : Icons.north_east_rounded,
          color: income ? const Color(0xFF087A53) : const Color(0xFFB93B3B),
          size: 20,
        ),
      ),
      title: Text(
        t.category,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(DateFormat.MMMd().format(t.date)),
      trailing: Text(
        '${income ? '+' : '-'}${money.format(t.amount)}',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: income ? const Color(0xFF087A53) : const Color(0xFFB93B3B),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label, amount;
  final Color color;
  final bool isBold;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: const Color(0xFF52615B),
            ),
          ),
        ],
      ),
      Text(
        amount,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
          color: isBold ? color : const Color(0xFF1F2937),
        ),
      ),
    ],
  );
}
