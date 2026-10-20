import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../core/validators.dart';
import '../models/savings_goal.dart';
import '../services/firestore_service.dart';
import '../services/user_preferences_service.dart';
import '../widgets/pennypal_widgets.dart';
import '../widgets/responsive_layout.dart';

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  Future<void> _openGoal(BuildContext context, [SavingsGoal? goal]) =>
      showDialog(
        context: context,
        builder: (_) => GoalDialog(existing: goal),
      );

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings goals'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: () => _openGoal(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New goal'),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<SavingsGoal>>(
        stream: FirestoreService.instance.goals(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final goals = snapshot.data!;
          final active = goals.where((g) => !g.completed).toList();
          final completed = goals.where((g) => g.completed).toList();
          if (goals.isEmpty) {
            return EmptyState(
              icon: Icons.savings_outlined,
              title: 'Start your first savings goal',
              message:
                  'Set a target and date. PennyPal will show the monthly amount needed to stay on track.',
              action: 'Create goal',
              onAction: () => _openGoal(context),
            );
          }
          final totalSaved = active.fold<double>(
            0,
            (a, g) => a + g.currentAmount,
          );
          final totalTarget = active.fold<double>(
            0,
            (a, g) => a + g.targetAmount,
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
            children: [
              if (active.isNotEmpty) ...[
                _GoalsSummary(
                  saved: totalSaved,
                  target: totalTarget,
                  count: active.length,
                ),
                const SizedBox(height: 18),
                ...active.map(
                  (goal) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _GoalCard(
                      goal: goal,
                      onEdit: () => _openGoal(context, goal),
                      onDelete: () =>
                          FirestoreService.instance.deleteGoal(uid, goal.id),
                      onComplete: () => FirestoreService.instance.saveGoal(
                        goal.copyWith(
                          currentAmount: goal.targetAmount,
                          status: 'completed',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              if (completed.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Goal history',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                ...completed.map(
                  (g) => Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppTheme.mint,
                        child: Icon(Icons.check_rounded, color: AppTheme.brand),
                      ),
                      title: Text(
                        g.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        '${UserPreferencesService.instance.money.format(g.currentAmount)} saved',
                      ),
                      trailing: const Chip(label: Text('Completed')),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final VoidCallback onEdit, onDelete, onComplete;
  const _GoalCard({
    required this.goal,
    required this.onEdit,
    required this.onDelete,
    required this.onComplete,
  });

  int _calendarMonthsLeft(DateTime now, DateTime target) {
    if (!target.isAfter(now)) return 0;
    var months = (target.year - now.year) * 12 + target.month - now.month;
    if (target.day > now.day) months += 1;
    return months < 1 ? 1 : months;
  }

  @override
  Widget build(BuildContext context) {
    final p = goal.progress.clamp(0.0, 1.0);
    final money = UserPreferencesService.instance.money;
    final now = DateTime.now();
    final monthsLeft = _calendarMonthsLeft(now, goal.targetDate);
    final requiredMonthly = monthsLeft <= 0
        ? goal.remaining
        : goal.remaining / monthsLeft;
    final planned = goal.monthlyContribution;
    final onTrack =
        goal.remaining <= 0 || (planned > 0 && planned >= requiredMonthly);
    final targetPassed = goal.targetDate.isBefore(
      DateTime(now.year, now.month, now.day),
    );

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.mint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.flag_rounded, color: AppTheme.brand),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  goal.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Update goal')),
                  PopupMenuItem(value: 'delete', child: Text('Delete goal')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            money.format(goal.currentAmount),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          Text(
            'of ${money.format(goal.targetAmount)} target',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: p,
              minHeight: 10,
              backgroundColor: const Color(0xFFE8EFEC),
              color: AppTheme.brand,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Text(
                '${(p * 100).toStringAsFixed(0)}% complete',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.brand,
                ),
              ),
              const Spacer(),
              Text(
                '${money.format(goal.remaining)} left',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: targetPassed
                  ? const Color(0xFFFFF1F1)
                  : (onTrack ? AppTheme.mint : const Color(0xFFFFF7E2)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Target ${DateFormat.yMMMd().format(goal.targetDate)}',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF26332E)),
                ),
                const SizedBox(height: 4),
                if (targetPassed)
                  const Text(
                    'The target date has passed. Update the date or contribution to make a new plan.',
                    style: TextStyle(color: Color(0xFF5A3A3A)),
                  )
                else ...[
                  Text(
                    '$monthsLeft month${monthsLeft == 1 ? '' : 's'} remaining • save about ${money.format(requiredMonthly)} per month to reach this date.',
                  ),
                  if (planned > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      onTrack
                          ? 'Your planned ${money.format(planned)} per month is on track.'
                          : 'Your planned ${money.format(planned)} per month is below the amount needed.',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: onTrack
                            ? AppTheme.brand
                            : const Color(0xFF9A6A00),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Update progress'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: 'Mark complete',
                onPressed: onComplete,
                icon: const Icon(Icons.check_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class GoalDialog extends StatefulWidget {
  final SavingsGoal? existing;
  const GoalDialog({super.key, this.existing});
  @override
  State<GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<GoalDialog> {
  late DateTime targetDate;
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final target = TextEditingController();
  final current = TextEditingController();
  final monthly = TextEditingController();
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    final g = widget.existing;
    final now = DateTime.now();
    targetDate = g?.targetDate ?? DateTime(now.year, now.month + 1, now.day);
    if (g != null) {
      name.text = g.name;
      target.text = '${g.targetAmount}';
      current.text = '${g.currentAmount}';
      monthly.text = '${g.monthlyContribution}';
    }
  }

  @override
  void dispose() {
    name.dispose();
    target.dispose();
    current.dispose();
    monthly.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => isSaving = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final targetAmount = double.parse(target.text);
    final currentAmount = double.tryParse(current.text) ?? 0;
    if (currentAmount < 0 || currentAmount > targetAmount) {
      if (mounted) {
        setState(() => isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Current savings must be between 0 and the target amount.',
            ),
          ),
        );
      }
      return;
    }
    try {
      await FirestoreService.instance.saveGoal(
        SavingsGoal(
          id: widget.existing?.id ?? '',
          userId: uid,
          name: name.text.trim(),
          targetAmount: targetAmount,
          currentAmount: currentAmount,
          monthlyContribution: double.tryParse(monthly.text) ?? 0,
          targetDate: targetDate,
          status: widget.existing?.status ?? 'active',
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existing == null
                  ? 'Savings goal created successfully'
                  : 'Savings goal updated successfully',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => isSaving = false);
        String errorMsg = e.toString();
        if (errorMsg.contains('permission')) {
          errorMsg =
              'Unable to save goal. Please check your account permissions and try again.';
        } else if (errorMsg.contains('denied')) {
          errorMsg =
              'Access denied. Make sure you are logged in and try again.';
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMsg)));
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.existing == null ? 'Create savings goal' : 'Update savings goal',
    ),
    content: SizedBox(
      width: 460,
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                validator: (v) => Validators.requiredText(v, 'Goal name'),
                decoration: const InputDecoration(
                  labelText: 'Goal name',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: target,
                validator: Validators.positiveAmount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Target amount',
                  prefixIcon: Icon(Icons.track_changes_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: current,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Current savings',
                  prefixIcon: Icon(Icons.savings_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: monthly,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Planned monthly contribution',
                  helperText:
                      'Optional — used to check whether you are on track',
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final today = DateTime.now();
                  final first = DateTime(today.year, today.month, today.day);
                  final initial = targetDate.isBefore(first)
                      ? first.add(const Duration(days: 30))
                      : targetDate;
                  final d = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: first,
                    lastDate: DateTime(today.year + 10, 12, 31),
                  );
                  if (d != null) setState(() => targetDate = d);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Target date',
                    prefixIcon: Icon(Icons.event_outlined),
                  ),
                  child: Text(DateFormat.yMMMd().format(targetDate)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: isSaving ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: isSaving ? null : save,
        child: isSaving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Save goal'),
      ),
    ],
  );
}

class _GoalsSummary extends StatelessWidget {
  final double saved, target;
  final int count;
  const _GoalsSummary({
    required this.saved,
    required this.target,
    required this.count,
  });
  @override
  Widget build(BuildContext context) {
    final money = UserPreferencesService.instance.money;
    final p = target <= 0 ? 0.0 : (saved / target).clamp(0, 1).toDouble();
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.brandDark, AppTheme.brand],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR SAVINGS PLAN',
            style: TextStyle(
              color: Color(0xFFCDE9DF),
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            money.format(saved),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            'saved across $count active goal${count == 1 ? '' : 's'} • ${money.format((target - saved).clamp(0, double.infinity))} left',
            style: const TextStyle(color: Color(0xFFD9EEE7)),
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: p,
            minHeight: 9,
            backgroundColor: Colors.white24,
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }
}
