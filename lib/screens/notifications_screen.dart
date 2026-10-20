import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../models/budget.dart';
import '../models/savings_goal.dart';
import '../models/transaction_entry.dart';
import '../services/firestore_service.dart';
import '../services/user_preferences_service.dart';
import '../widgets/pennypal_widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Alerts & reminders')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('supportQueries').where('userId', isEqualTo: uid).snapshots(),
        builder: (context, support) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('announcements')
            .orderBy('createdAt', descending: true)
            .limit(20)
            .snapshots(),
        builder: (context, announcements) {
          return StreamBuilder<List<TransactionEntry>>(
            stream: FirestoreService.instance.transactions(uid),
            builder: (context, transactions) {
              return StreamBuilder<List<Budget>>(
                stream: FirestoreService.instance.budgets(uid),
                builder: (context, budgets) {
                  return StreamBuilder<List<SavingsGoal>>(
                    stream: FirestoreService.instance.goals(uid),
                    builder: (context, goals) {
                      if (!transactions.hasData ||
                          !budgets.hasData ||
                          !goals.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final alerts = <Widget>[];
                      for (final doc in support.data?.docs ?? []) {
                        final data = doc.data();
                        final reply = (data['adminReply'] ?? '').toString();
                        if (reply.isNotEmpty) {
                          alerts.add(_Alert(
                            icon: data['status'] == 'closed' ? Icons.task_alt_rounded : Icons.support_agent_rounded,
                            title: data['status'] == 'closed' ? 'Support request resolved' : 'PennyPal support replied',
                            message: '${data['subject'] ?? 'Support'} — $reply',
                          ));
                        }
                      }
                      for (final doc in announcements.data?.docs ?? []) {
                        final data = doc.data();
                        if ((data['published'] ?? true) != true) continue;
                        alerts.add(
                          _Alert(
                            icon: Icons.campaign_outlined,
                            title: (data['title'] ?? 'PennyPal update').toString(),
                            message: (data['body'] ?? '').toString(),
                          ),
                        );
                      }

                      final month = DateFormat('yyyy-MM').format(DateTime.now());
                      for (final budget
                          in budgets.data!.where((item) => item.month == month)) {
                        final spent = transactions.data!
                            .where(
                              (transaction) =>
                                  transaction.type == 'expense' &&
                                  DateFormat('yyyy-MM').format(transaction.date) ==
                                      month &&
                                  (budget.category == 'Overall' ||
                                      transaction.category == budget.category),
                            )
                            .fold<double>(
                              0,
                              (total, transaction) => total + transaction.amount,
                            );

                        if (spent >= budget.limitAmount * .8) {
                          final over = spent > budget.limitAmount;
                          alerts.add(
                            _Alert(
                              icon: over
                                  ? Icons.warning_amber_rounded
                                  : Icons.notifications_active_outlined,
                              title: over
                                  ? '${budget.category} budget exceeded'
                                  : '${budget.category} budget is nearly full',
                              message:
                                  'You have spent ${UserPreferencesService.instance.money.format(spent)} of your ${UserPreferencesService.instance.money.format(budget.limitAmount)} limit.',
                              danger: over,
                            ),
                          );
                        }
                      }

                      for (final goal in goals.data!.where((item) => item.progress < 1)) {
                        final now = DateTime.now();
                        final daysLeft = goal.targetDate.difference(DateTime(now.year, now.month, now.day)).inDays;
                        var monthsLeft = (goal.targetDate.year - now.year) * 12 + goal.targetDate.month - now.month;
                        if (goal.targetDate.day > now.day) monthsLeft += 1;
                        if (monthsLeft < 1) monthsLeft = 1;
                        final needed = goal.remaining / monthsLeft;
                        final behind = goal.monthlyContribution > 0 && goal.monthlyContribution < needed;
                        alerts.add(
                          _Alert(
                            icon: behind || daysLeft < 0 ? Icons.warning_amber_rounded : Icons.flag_outlined,
                            title: daysLeft < 0
                                ? 'Target date passed: ${goal.name}'
                                : behind
                                    ? 'Savings plan needs attention: ${goal.name}'
                                    : 'Keep going: ${goal.name}',
                            message: daysLeft < 0
                                ? 'Update the target date or contribution to make a new plan.'
                                : behind
                                    ? 'To reach your target on time, save about ${UserPreferencesService.instance.money.format(needed)} per month.'
                                    : '${(goal.progress * 100).toStringAsFixed(0)}% complete • ${UserPreferencesService.instance.money.format(goal.remaining)} remaining.',
                            danger: daysLeft < 0,
                          ),
                        );
                      }

                      if (alerts.isEmpty) {
                        return const EmptyState(
                          icon: Icons.notifications_none_rounded,
                          title: 'You’re all caught up',
                          message:
                              'Budget warnings, goal reminders and PennyPal announcements will appear here.',
                        );
                      }

                      return ListView(
                        padding: const EdgeInsets.all(18),
                        children: alerts,
                      );
                    },
                  );
                },
              );
            },
          );
        },
      );
        },
      ),
    );
  }
}

class _Alert extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final bool danger;

  const _Alert({
    required this.icon,
    required this.title,
    required this.message,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor:
              danger ? const Color(0xFFFFEEEE) : AppTheme.mint,
          child: Icon(
            icon,
            color: danger ? const Color(0xFFB93B3B) : AppTheme.brand,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(message),
        ),
      ),
    );
  }
}
