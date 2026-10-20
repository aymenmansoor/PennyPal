import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/transaction_entry.dart';
import '../services/firestore_service.dart';
import '../services/user_preferences_service.dart';
import '../widgets/pennypal_widgets.dart';
import 'add_transaction_screen.dart';

class RecurringTransactionsScreen extends StatelessWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final money = UserPreferencesService.instance.money;

    return Scaffold(
      appBar: AppBar(title: const Text('Recurring transactions')),
      body: StreamBuilder<List<TransactionEntry>>(
        stream: FirestoreService.instance.transactions(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final rows = snapshot.data!
              .where((transaction) => transaction.recurrence != 'none')
              .toList();

          if (rows.isEmpty) {
            return EmptyState(
              icon: Icons.repeat_rounded,
              title: 'Automate the predictable',
              message:
                  'When adding income or expense, select "Every week" or "Every month" in the repeat field to see them here.',
              action: 'Add recurring transaction',
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddTransactionScreen(type: 'expense'),
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      const CircleAvatar(child: Icon(Icons.repeat_rounded)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Recurring money',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              '${rows.length} repeating transaction${rows.length == 1 ? '' : 's'}',
                              style: const TextStyle(color: Color(0xFF71807A)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...rows.map(
                (transaction) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Icon(
                        transaction.type == 'income'
                            ? Icons.south_west_rounded
                            : Icons.north_east_rounded,
                      ),
                    ),
                    title: Text(
                      transaction.description.isEmpty
                          ? transaction.category
                          : transaction.description,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      '${transaction.category} • ${transaction.recurrence[0].toUpperCase()}${transaction.recurrence.substring(1)}',
                    ),
                    trailing: Text(
                      money.format(transaction.amount),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddTransactionScreen(
                          type: transaction.type,
                          existing: transaction,
                        ),
                      ),
                    ),
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
