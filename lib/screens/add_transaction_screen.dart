import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/validators.dart';
import '../models/transaction_entry.dart';
import '../services/firestore_service.dart';
import '../services/expense_categorizer_service.dart';
import '../services/user_preferences_service.dart';
import '../widgets/responsive_layout.dart';

class AddTransactionScreen extends StatefulWidget {
  final String type;
  final TransactionEntry? existing;
  const AddTransactionScreen({super.key, required this.type, this.existing});
  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final formKey = GlobalKey<FormState>();
  final amount = TextEditingController(), description = TextEditingController();
  late String category;
  late DateTime date;
  bool busy = false;
  String recurrence = 'none';
  List<String> customCategories = const [];
  bool get income => widget.type == 'income';
  String? aiSuggestion;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    category =
        e?.category ??
        (income
            ? defaultIncomeCategories.first
            : defaultExpenseCategories.first);
    date = e?.date ?? DateTime.now();
    amount.text = e?.amount.toString() ?? '';
    description.text = e?.description ?? '';
    description.addListener(_suggestCategory);
    recurrence = e?.recurrence ?? 'none';
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final first = await FirestoreService.instance
        .customCategories(uid, widget.type)
        .first;
    if (mounted) setState(() => customCategories = first);
  }

  void _suggestCategory() {
    if (income || widget.existing != null) return;
    final suggestion = ExpenseCategorizerService.instance.suggest(
      description.text,
    );
    if (suggestion != aiSuggestion && mounted)
      setState(() => aiSuggestion = suggestion);
  }

  @override
  void dispose() {
    description.removeListener(_suggestCategory);
    amount.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirestoreService.instance.saveTransaction(
        TransactionEntry(
          id: widget.existing?.id ?? '',
          userId: uid,
          type: widget.type,
          amount: double.parse(amount.text),
          category: category,
          description: description.text.trim(),
          date: date,
          recurrence: recurrence,
        ),
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = <String>{
      ...(income ? defaultIncomeCategories : defaultExpenseCategories),
      ...customCategories,
    }.toList();
    final accent = AppTheme.brand;
    final soft = income ? const Color(0xFFE8F6F1) : const Color(0xFFF2F7F5);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null
              ? 'Add ${income ? 'income' : 'expense'}'
              : 'Edit transaction',
        ),
      ),
      body: SingleChildScrollView(
        child: PageFrame(
          maxWidth: 760,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TransactionHero(income: income, accent: accent, soft: soft),
              const SizedBox(height: 18),
              PremiumCard(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transaction details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'A few details now will make your reports and insights much more useful.',
                        style: TextStyle(color: Color(0xFF74817C)),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: soft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextFormField(
                          controller: amount,
                          validator: Validators.positiveAmount,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: accent,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Amount',
                            prefixText:
                                '${UserPreferencesService.instance.currencySymbol} ',
                            prefixIcon: Icon(
                              Icons.payments_rounded,
                              color: accent,
                            ),
                            fillColor: Colors.transparent,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      DropdownButtonFormField<String>(
                        initialValue: category,
                        items: cats
                            .map(
                              (x) => DropdownMenuItem(value: x, child: Text(x)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => category = v!),
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: description,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          hintText: income
                              ? 'Optional note about this income'
                              : 'Try “Uber ride” or “coffee with friends”',
                          alignLabelWithHint: true,
                          prefixIcon: const Icon(Icons.notes_rounded),
                        ),
                      ),
                      if (!income &&
                          aiSuggestion != null &&
                          aiSuggestion != category) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ActionChip(
                            avatar: const Icon(
                              Icons.auto_awesome_rounded,
                              size: 17,
                            ),
                            label: Text('Suggested: $aiSuggestion'),
                            onPressed: () =>
                                setState(() => category = aiSuggestion!),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: accent.withValues(alpha: .3),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: DropdownButtonFormField<String>(
                          initialValue: recurrence,
                          decoration: InputDecoration(
                            labelText: 'Repeat this transaction?',
                            prefixIcon: Icon(
                              Icons.repeat_rounded,
                              color: accent,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'none',
                              child: Text('Does not repeat'),
                            ),
                            DropdownMenuItem(
                              value: 'weekly',
                              child: Text('Every week'),
                            ),
                            DropdownMenuItem(
                              value: 'monthly',
                              child: Text('Every month'),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => recurrence = v ?? 'none'),
                        ),
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: () async {
                          final p = await showDatePicker(
                            context: context,
                            initialDate: date,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (p != null) setState(() => date = p);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            prefixIcon: Icon(Icons.calendar_month_rounded),
                          ),
                          child: Text(
                            '${date.day}/${date.month}/${date.year}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
                          ),
                          onPressed: busy ? null : save,
                          icon: busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  income
                                      ? Icons.add_circle_outline_rounded
                                      : Icons.check_circle_outline_rounded,
                                ),
                          label: Text(
                            busy
                                ? 'Saving...'
                                : income
                                ? 'Save income'
                                : 'Save expense',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.shield_outlined,
                      size: 15,
                      color: Color(0xFF74817C),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Private to your PennyPal account',
                      style: TextStyle(fontSize: 12, color: Color(0xFF74817C)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionHero extends StatelessWidget {
  final bool income;
  final Color accent, soft;
  const _TransactionHero({
    required this.income,
    required this.accent,
    required this.soft,
  });
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [soft, Theme.of(context).cardColor]),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: accent.withValues(alpha: .14)),
    ),
    child: Row(
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: .22),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            income ? Icons.south_west_rounded : Icons.north_east_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                income ? 'Money coming in' : 'Money going out',
                style: TextStyle(color: accent, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                income ? 'Record your income' : 'Record your expense',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                income
                    ? 'Keep your balance and progress up to date.'
                    : 'Stay aware of where your money is going.',
                style: const TextStyle(color: Color(0xFF68756F)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
