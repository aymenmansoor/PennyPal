import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../models/transaction_entry.dart';
import '../services/firestore_service.dart';
import '../services/user_preferences_service.dart';
import '../widgets/pennypal_widgets.dart';
import 'add_transaction_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});
  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String type = 'all', category = 'All', period = 'all';
  String query = '';
  DateTimeRange? range;
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final money = UserPreferencesService.instance.money;
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transactions',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Search, filter and manage your money activity.',
                  style: TextStyle(color: Color(0xFF71807A)),
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (v) => setState(() => query = v.toLowerCase()),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'Search transactions...',
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...['all', 'income', 'expense'].map(
                        (v) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(v[0].toUpperCase() + v.substring(1)),
                            selected: type == v,
                            onSelected: (_) => setState(() => type = v),
                          ),
                        ),
                      ),
                      ...['all','week','month'].map((v)=>Padding(padding:const EdgeInsets.only(right:8),child:ChoiceChip(label:Text(v=='all'?'Any time':v=='week'?'This week':'This month'),selected:period==v,onSelected:(_)=>setState((){period=v;range=null;})))),
                      ActionChip(
                        avatar: const Icon(Icons.date_range_outlined, size: 18),
                        label: Text(
                          range == null
                              ? 'Date'
                              : '${DateFormat.MMMd().format(range!.start)} – ${DateFormat.MMMd().format(range!.end)}',
                        ),
                        onPressed: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                            initialDateRange: range,
                          );
                          if (picked != null) setState(() => range = picked);
                        },
                      ),
                      if (range != null)
                        IconButton(
                          onPressed: () => setState(() => range = null),
                          icon: const Icon(Icons.close_rounded),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<TransactionEntry>>(
              stream: FirestoreService.instance.transactions(uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final categories = {
                  'All',
                  ...snapshot.data!.map((e) => e.category),
                }.toList()..sort();
                if (!categories.contains(category)) category = 'All';
                final items = snapshot.data!.where((t) {
                  final q =
                      query.isEmpty ||
                      t.category.toLowerCase().contains(query) ||
                      t.description.toLowerCase().contains(query);
                  final ty = type == 'all' || t.type == type;
                  final cat = category == 'All' || t.category == category;
                  final now=DateTime.now();
                  final periodStart=period=='week'?now.subtract(Duration(days:now.weekday-1)):period=='month'?DateTime(now.year,now.month,1):null;
                  final dt = range != null
                      ? (!t.date.isBefore(range!.start) && t.date.isBefore(range!.end.add(const Duration(days:1))))
                      : (periodStart==null || !t.date.isBefore(periodStart));
                  return q && ty && cat && dt;
                }).toList();
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: DropdownButtonFormField<String>(
                        initialValue: category,
                        items: categories
                            .map(
                              (x) => DropdownMenuItem(value: x, child: Text(x)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => category = v ?? 'All'),
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: items.isEmpty
                          ? const EmptyState(
                              icon: Icons.search_off_rounded,
                              title: 'Nothing found',
                              message: 'Try changing your search or filters.',
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                8,
                                18,
                                100,
                              ),
                              itemCount: items.length,
                              separatorBuilder: (_, index) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final t = items[index];
                                final income = t.type == 'income';
                                return Card(
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: income
                                          ? const Color(0xFFE5F7EF)
                                          : const Color(0xFFFFEEEE),
                                      child: Icon(
                                        income
                                            ? Icons.south_west_rounded
                                            : Icons.north_east_rounded,
                                        color: income
                                            ? const Color(0xFF087A53)
                                            : const Color(0xFFB93B3B),
                                      ),
                                    ),
                                    title: Text(
                                      t.category,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${DateFormat.yMMMd().format(t.date)}${t.description.isEmpty ? '' : ' • ${t.description}'}',
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (v) async {
                                        if (v == 'edit') {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  AddTransactionScreen(
                                                    type: t.type,
                                                    existing: t,
                                                  ),
                                            ),
                                          );
                                        } else {
                                          await FirestoreService.instance
                                              .deleteTransaction(uid, t.id);
                                        }
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Edit'),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete'),
                                        ),
                                      ],
                                      child: Text(
                                        '${income ? '+' : '-'}${money.format(t.amount)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: income
                                              ? AppTheme.brand
                                              : const Color(0xFFB93B3B),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
