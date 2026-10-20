import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../widgets/pennypal_widgets.dart';
import 'add_transaction_screen.dart';
import 'dashboard_screen.dart';
import 'more_screen.dart';
import 'savings_screen.dart';
import 'transaction_history_screen.dart';
import 'ai_guidance_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  final pages = const [
    DashboardScreen(),
    TransactionHistoryScreen(),
    SavingsScreen(),
    MoreScreen(),
  ];

  void addTransaction() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add transaction',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              _AddChoice(
                icon: Icons.south_west_rounded,
                title: 'Add income',
                subtitle: 'Allowance, salary, scholarship or gift',
                color: const Color(0xFFE5F7EF),
                foreground: const Color(0xFF087A53),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const AddTransactionScreen(type: 'income'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _AddChoice(
                icon: Icons.north_east_rounded,
                title: 'Add expense',
                subtitle: 'Food, transport, bills and more',
                color: const Color(0xFFFFEEEE),
                foreground: const Color(0xFFB93B3B),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const AddTransactionScreen(type: 'expense'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final desktop = constraints.maxWidth >= 900;
      if (!desktop) {
        return Scaffold(
          body: IndexedStack(index: index, children: pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (v) => setState(() => index = v),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded, color: AppTheme.brand),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(
                  Icons.receipt_long_rounded,
                  color: AppTheme.brand,
                ),
                label: 'Activity',
              ),
              NavigationDestination(
                icon: Icon(Icons.flag_outlined),
                selectedIcon: Icon(Icons.flag_rounded, color: AppTheme.brand),
                label: 'Goals',
              ),
              NavigationDestination(
                icon: Icon(Icons.grid_view_rounded),
                selectedIcon: Icon(
                  Icons.grid_view_rounded,
                  color: AppTheme.brand,
                ),
                label: 'More',
              ),
            ],
          ),
          floatingActionButton: _GuideFab(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AiGuidanceScreen()),
            ),
          ),
        );
      }
      return Scaffold(
        floatingActionButton: _GuideFab(
          extended: true,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AiGuidanceScreen()),
          ),
        ),
        body: Row(
          children: [
            Container(
              width: 236,
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.fromLTRB(18, 26, 18, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const PennyPalLogo(size: 44),
                      const SizedBox(width: 12),
                      Text(
                        'PennyPal',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : AppTheme.ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 34),
                  _NavItem(
                    icon: Icons.home_rounded,
                    label: 'Overview',
                    selected: index == 0,
                    onTap: () => setState(() => index = 0),
                  ),
                  _NavItem(
                    icon: Icons.receipt_long_rounded,
                    label: 'Activity',
                    selected: index == 1,
                    onTap: () => setState(() => index = 1),
                  ),
                  _NavItem(
                    icon: Icons.flag_rounded,
                    label: 'Savings goals',
                    selected: index == 2,
                    onTap: () => setState(() => index = 2),
                  ),
                  _NavItem(
                    icon: Icons.grid_view_rounded,
                    label: 'Explore',
                    selected: index == 3,
                    onTap: () => setState(() => index = 3),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: addTransaction,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add transaction'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Smarter student money',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF999999)
                          : const Color(0xFF7B8883),
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: IndexedStack(index: index, children: pages),
            ),
          ],
        ),
      );
    },
  );
}


class _GuideFab extends StatelessWidget {
  final VoidCallback onPressed;
  final bool extended;
  const _GuideFab({required this.onPressed, this.extended = false});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (extended) {
      return FloatingActionButton.extended(
        heroTag: 'pennypal-guide-desktop',
        tooltip: 'Ask PennyPal Guide',
        onPressed: onPressed,
        backgroundColor: AppTheme.brand,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.smart_toy_rounded),
        label: const Text('Ask PennyPal', style: TextStyle(fontWeight: FontWeight.w800)),
      );
    }
    return FloatingActionButton(
      heroTag: 'pennypal-guide-mobile',
      tooltip: 'Ask PennyPal Guide',
      onPressed: onPressed,
      backgroundColor: dark ? const Color(0xFF1F7A73) : AppTheme.brand,
      foregroundColor: Colors.white,
      child: const Icon(Icons.smart_toy_rounded),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? (isDark ? const Color(0xFF1A4A42) : AppTheme.mint)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 21,
                  color: selected
                      ? AppTheme.brand
                      : (isDark
                            ? const Color(0xFF888888)
                            : const Color(0xFF6E7A75)),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected
                        ? AppTheme.brand
                        : (isDark
                              ? const Color(0xFFCCCCCC)
                              : const Color(0xFF46534E)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddChoice extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color, foreground;
  final VoidCallback onTap;
  const _AddChoice({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.foreground,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => ListTile(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    tileColor: color,
    leading: CircleAvatar(
      backgroundColor: Colors.white,
      child: Icon(icon, color: foreground),
    ),
    title: Text(
      title,
      style: TextStyle(fontWeight: FontWeight.w800, color: foreground),
    ),
    subtitle: Text(
      subtitle,
      style: TextStyle(color: Color.lerp(foreground, Colors.black, 0.3)),
    ),
    trailing: Icon(Icons.arrow_forward_rounded, color: foreground),
    onTap: onTap,
  );
}
