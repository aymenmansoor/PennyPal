import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/budget.dart';
import '../models/transaction_entry.dart';
import '../services/firestore_service.dart';
import '../services/user_preferences_service.dart';
import '../core/validators.dart';
import '../core/app_theme.dart';
import '../widgets/pennypal_widgets.dart';
import '../widgets/responsive_layout.dart';

class BudgetScreen extends StatefulWidget { const BudgetScreen({super.key}); @override State<BudgetScreen> createState() => _S(); }
class _S extends State<BudgetScreen> {
  final amount = TextEditingController(); String category = 'Overall'; Budget? editingBudget;
  String get month => DateFormat('yyyy-MM').format(DateTime.now());
  Future<void> add() async { if (Validators.positiveAmount(amount.text) != null) return; final uid = FirebaseAuth.instance.currentUser!.uid; await FirestoreService.instance.saveBudget(Budget(id: editingBudget?.id ?? '', userId: uid, month: month, category: category, limitAmount: double.parse(amount.text))); amount.clear(); editingBudget = null; if (mounted) setState(() {}); }
  void startEdit(Budget b) => setState(() { editingBudget = b; category = b.category; amount.text = b.limitAmount.toString(); });
  @override void dispose() { amount.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(appBar: AppBar(title: const Text('Budget')), body: StreamBuilder<List<TransactionEntry>>(
      stream: FirestoreService.instance.transactions(uid), builder: (c, ts) => StreamBuilder<List<Budget>>(
        stream: FirestoreService.instance.budgets(uid), builder: (c, bs) {
          if (!ts.hasData || !bs.hasData) return const Center(child: CircularProgressIndicator());
          final tx = ts.data!, budgets = bs.data!.where((b) => b.month == month).toList();
          final expenses = tx.where((t) => t.type == 'expense' && DateFormat('yyyy-MM').format(t.date) == month).toList();
          final spent = expenses.fold<double>(0, (a, x) => a + x.amount);
          final overallMatches = budgets.where((b) => b.category == 'Overall');
          final Budget? overall = overallMatches.isEmpty ? null : overallMatches.first;
          return ListView(children: [PageFrame(maxWidth: 820, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            PageHeading(title: 'Plan your month', subtitle: 'Set spending limits and see how your money is tracking at a glance.'),
            const SizedBox(height: 18), _BudgetHero(spent: spent, limit: overall?.limitAmount, monthLabel: DateFormat.yMMMM().format(DateTime.now())),
            const SizedBox(height: 22), SectionTitle(editingBudget == null ? 'Create a budget' : 'Update budget'), const SizedBox(height: 10),
            PremiumCard(child: Column(children: [
              DropdownButtonFormField<String>(initialValue: category, decoration: const InputDecoration(labelText: 'Budget category', prefixIcon: Icon(Icons.category_outlined)), items: ['Overall', ...defaultExpenseCategories].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setState(() => category = v!)),
              const SizedBox(height: 12), TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Monthly limit', prefixText: '${UserPreferencesService.instance.currencySymbol} ', prefixIcon: const Icon(Icons.account_balance_wallet_outlined))),
              const SizedBox(height: 14), Row(children: [Expanded(child: FilledButton.icon(onPressed: add, icon: Icon(editingBudget != null ? Icons.check_rounded : Icons.add_rounded), label: Text(editingBudget != null ? 'Update budget' : 'Add budget'))), if (editingBudget != null) ...[const SizedBox(width: 8), IconButton.outlined(onPressed: () { editingBudget=null; amount.clear(); category='Overall'; setState((){}); }, icon: const Icon(Icons.close_rounded))]]),
            ])),
            const SizedBox(height: 24), SectionTitle('Your budgets'), const SizedBox(height: 10),
            if (budgets.isEmpty) const PremiumCard(child: EmptyState(icon: Icons.donut_large_rounded, title: 'No budgets yet', message: 'Create an overall monthly limit or a category budget. PennyPal will show your progress here.'))
            else ...budgets.map((b) => _BudgetProgressCard(budget: b, transactions: tx, month: month, onEdit: () => startEdit(b), onDelete: () => FirestoreService.instance.deleteBudget(uid, b.id))),
          ]))]);
        },
      ),
    ));
  }
}

class _BudgetHero extends StatelessWidget {
  final double spent; final double? limit; final String monthLabel;
  const _BudgetHero({required this.spent, required this.limit, required this.monthLabel});
  @override Widget build(BuildContext context) {
    final money = UserPreferencesService.instance.money; final hasLimit = limit != null && limit! > 0; final ratio = hasLimit ? (spent / limit!).clamp(0, 1).toDouble() : 0.0; final remaining = hasLimit ? limit! - spent : 0.0;
    return Container(width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.brandDark, AppTheme.brand], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(28), boxShadow: const [BoxShadow(color: Color(0x2B0F6B52), blurRadius: 26, offset: Offset(0, 12))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.donut_large_rounded, color: Colors.white)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('MONTHLY BUDGET', style: TextStyle(color: Color(0xFFCDE9DF), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1)), Text(monthLabel, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900))]))]),
      const SizedBox(height: 24), Text(money.format(spent), style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)), const Text('spent this month', style: TextStyle(color: Color(0xFFD9EEE7))), const SizedBox(height: 18),
      ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: ratio, minHeight: 10, backgroundColor: Colors.white24, color: Colors.white)), const SizedBox(height: 10),
      Text(hasLimit ? (remaining >= 0 ? '${money.format(remaining)} remaining of ${money.format(limit)}' : '${money.format(remaining.abs())} over your ${money.format(limit)} limit') : 'Set an Overall budget below to start tracking your monthly progress.', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
    ]));
  }
}

class _BudgetProgressCard extends StatelessWidget {
  final Budget budget; final List<TransactionEntry> transactions; final String month; final VoidCallback onEdit, onDelete;
  const _BudgetProgressCard({required this.budget, required this.transactions, required this.month, required this.onEdit, required this.onDelete});
  @override Widget build(BuildContext context) {
    final spent = transactions.where((t) => t.type == 'expense' && DateFormat('yyyy-MM').format(t.date) == month && (budget.category == 'Overall' || t.category == budget.category)).fold<double>(0, (a, x) => a + x.amount);
    final ratio = budget.limitAmount == 0 ? 0.0 : spent / budget.limitAmount; final progress = ratio.clamp(0, 1).toDouble(); final danger = ratio > 1; final warning = !danger && ratio >= .8; final accent = danger ? const Color(0xFFB93B3B) : warning ? const Color(0xFFB7791F) : AppTheme.brand; final money = UserPreferencesService.instance.money;
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: PremiumCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Container(width: 46, height: 46, decoration: BoxDecoration(color: accent.withValues(alpha: .11), borderRadius: BorderRadius.circular(15)), child: Icon(budget.category == 'Overall' ? Icons.wallet_rounded : Icons.category_rounded, color: accent)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(budget.category, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)), Text('${(ratio * 100).round()}% of budget used', style: const TextStyle(color: Color(0xFF74817C), fontSize: 12))])), IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined)), IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline))]),
      const SizedBox(height: 16), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(money.format(spent), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19, color: accent)), Text('of ${money.format(budget.limitAmount)}', style: const TextStyle(color: Color(0xFF74817C), fontWeight: FontWeight.w600))]), const SizedBox(height: 10),
      ClipRRect(borderRadius: BorderRadius.circular(12), child: LinearProgressIndicator(value: progress, minHeight: 9, backgroundColor: accent.withValues(alpha: .10), color: accent)),
      if (warning || danger) Padding(padding: const EdgeInsets.only(top: 12), child: Row(children: [Icon(danger ? Icons.warning_amber_rounded : Icons.info_outline_rounded, color: accent, size: 18), const SizedBox(width: 7), Text(danger ? 'Budget exceeded' : 'You are approaching this limit', style: TextStyle(color: accent, fontWeight: FontWeight.w700))])),
    ])));
  }
}
