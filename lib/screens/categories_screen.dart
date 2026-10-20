import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/firestore_service.dart';
import '../widgets/pennypal_widgets.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  Future<void> _add(BuildContext context) async {
    final name = TextEditingController();
    String type = 'expense';
    int colorValue = 0xFF0F6B52;
    String iconName = 'category';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create category'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Category name',
                    hintText: 'e.g. Books, Freelance work',
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: iconName,
                  decoration: const InputDecoration(labelText: 'Icon'),
                  items: const [
                    DropdownMenuItem(value: 'category', child: Text('Category')),
                    DropdownMenuItem(value: 'food', child: Text('Food')),
                    DropdownMenuItem(value: 'transport', child: Text('Transport')),
                    DropdownMenuItem(value: 'school', child: Text('Education')),
                    DropdownMenuItem(value: 'work', child: Text('Work')),
                    DropdownMenuItem(value: 'home', child: Text('Home')),
                  ],
                  onChanged: (value) => setDialogState(
                    () => iconName = value ?? 'category',
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  initialValue: colorValue,
                  decoration: const InputDecoration(labelText: 'Colour'),
                  items: const [
                    DropdownMenuItem(value: 0xFF0F6B52, child: Text('Emerald')),
                    DropdownMenuItem(value: 0xFF4A90D9, child: Text('Blue')),
                    DropdownMenuItem(value: 0xFF6C63D9, child: Text('Purple')),
                    DropdownMenuItem(value: 0xFFE66B6B, child: Text('Coral')),
                    DropdownMenuItem(value: 0xFFF4B942, child: Text('Gold')),
                  ],
                  onChanged: (value) => setDialogState(
                    () => colorValue = value ?? 0xFF0F6B52,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'expense',
                        icon: Icon(Icons.north_east_rounded),
                        label: Text('Expense'),
                      ),
                      ButtonSegment(
                        value: 'income',
                        icon: Icon(Icons.south_west_rounded),
                        label: Text('Income'),
                      ),
                    ],
                    selected: {type},
                    onSelectionChanged: (value) =>
                        setDialogState(() => type = value.first),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (name.text.trim().isEmpty) return;
                await FirestoreService.instance.addCategory(
                  FirebaseAuth.instance.currentUser!.uid,
                  type: type,
                  name: name.text.trim(),
                  colorValue: colorValue,
                  iconName: iconName,
                );
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Custom categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New category'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('categories')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return EmptyState(
              icon: Icons.category_outlined,
              title: 'Make PennyPal fit your life',
              message:
                  'Create custom income or expense categories such as Books, Subscriptions or Freelance work. They will appear when you record a transaction.',
              action: 'Create your first category',
              onAction: () => _add(context),
            );
          }

          final incomeCount =
              docs.where((d) => d.data()['type'] == 'income').length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppTheme.mint,
                        child: Icon(
                          Icons.category_outlined,
                          color: AppTheme.brand,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your categories',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${docs.length} custom • $incomeCount income • ${docs.length - incomeCount} expense',
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
              ...docs.map((d) {
                final x = d.data();
                final income = x['type'] == 'income';
                final colorValue = (x['colorValue'] ?? 0xFF0F6B52) as int;
                final color = Color(colorValue);
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 7,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: .12),
                      child: Icon(
                        _iconFor((x['iconName'] ?? 'category').toString()),
                        color: color,
                      ),
                    ),
                    title: Text(
                      (x['name'] ?? 'Category').toString(),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      income ? 'Income category' : 'Expense category',
                    ),
                    trailing: IconButton(
                      tooltip: 'Delete category',
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () =>
                          FirestoreService.instance.deleteCategory(uid, d.id),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

IconData _iconFor(String name) => switch (name) {
      'food' => Icons.restaurant_rounded,
      'transport' => Icons.directions_bus_rounded,
      'school' => Icons.school_rounded,
      'work' => Icons.work_outline_rounded,
      'home' => Icons.home_outlined,
      _ => Icons.category_rounded,
    };
