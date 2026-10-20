import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../widgets/responsive_layout.dart';
import 'about_screen.dart';
import 'admin_screen.dart';
import 'ai_guidance_screen.dart';
import 'budget_screen.dart';
import 'learning_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'preferences_screen.dart';
import 'categories_screen.dart';
import 'reports_screen.dart';
import 'recurring_transactions_screen.dart';
import 'support_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});
  void go(BuildContext c, Widget w) =>
      Navigator.push(c, MaterialPageRoute(builder: (_) => w));
  Future<void> _handleLogout(BuildContext context) async {
    try {
      await AuthService.instance.logout();
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign out failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      child: PageFrame(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Explore',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            const Text(
              'Everything else you need to stay on track.',
              style: TextStyle(color: Color(0xFF71807A)),
            ),
            const SizedBox(height: 18),
            _Group(
              children: [
                _Tile(
                  Icons.account_balance_wallet_outlined,
                  'Budgets',
                  'Set monthly and category limits',
                  () => go(context, const BudgetScreen()),
                  const Color(0xFFE5F7EF),
                  AppTheme.brand,
                ),
                _Tile(
                  Icons.insights_outlined,
                  'Reports & insights',
                  'Understand your spending patterns',
                  () => go(context, const ReportsScreen()),
                  const Color(0xFFEEEAFE),
                  const Color(0xFF5B49B7),
                ),
                _Tile(
                  Icons.notifications_none_rounded,
                  'Alerts & reminders',
                  'Budget warnings and goal reminders',
                  () => go(context, const NotificationsScreen()),
                  const Color(0xFFFFF5D9),
                  const Color(0xFF9A6A00),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Group(
              children: [
                _Tile(
                  Icons.school_outlined,
                  'Learning Hub',
                  'Build practical financial literacy',
                  () => go(context, const LearningScreen()),
                  const Color(0xFFEAF3FF),
                  const Color(0xFF3E6FA8),
                ),
                _Tile(
                  Icons.auto_awesome_outlined,
                  'PennyPal Guide',
                  'Educational budgeting guidance',
                  () => go(context, const AiGuidanceScreen()),
                  const Color(0xFFF6EAFE),
                  const Color(0xFF7C49A8),
                ),
                _Tile(
                  Icons.support_agent_outlined,
                  'Feedback & support',
                  'Ask for help or share feedback',
                  () => go(context, const SupportScreen()),
                  const Color(0xFFFFEEEE),
                  const Color(0xFFB93B3B),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Group(
              children: [
                _Tile(
                  Icons.tune_rounded,
                  'Preferences',
                  'Country, currency and notifications',
                  () => go(context, const PreferencesScreen()),
                  const Color(0xFFE5F7EF),
                  AppTheme.brand,
                ),
                _Tile(
                  Icons.repeat_rounded,
                  'Recurring transactions',
                  'Manage weekly and monthly money',
                  () => go(context, const RecurringTransactionsScreen()),
                  const Color(0xFFEEEAFE),
                  const Color(0xFF5B49B7),
                ),
                _Tile(
                  Icons.category_outlined,
                  'Custom categories',
                  'Create categories that fit your life',
                  () => go(context, const CategoriesScreen()),
                  const Color(0xFFFFF5D9),
                  const Color(0xFF9A6A00),
                ),
                _Tile(
                  Icons.person_outline_rounded,
                  'Profile',
                  'Account and personal information',
                  () => go(context, const ProfileScreen()),
                  const Color(0xFFF0F3F2),
                  const Color(0xFF52615B),
                ),
                _Tile(
                  Icons.info_outline_rounded,
                  'About PennyPal',
                  'Learn about our mission and features',
                  () => go(context, const AboutScreen()),
                  const Color(0xFFEAF3FF),
                  const Color(0xFF3E6FA8),
                ),
              ],
            ),
            FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .get(),
              builder: (c, s) => ['admin', 'superAdmin'].contains(s.data?.data()?['role'])
                  ? Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: _Group(
                        children: [
                          _Tile(
                            Icons.admin_panel_settings_outlined,
                            'Admin console',
                            'Users, content and support overview',
                            () => go(context, const AdminScreen()),
                            const Color(0xFFFFF0E6),
                            const Color(0xFFA95A1A),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.brightness_4_rounded, color: Color(0xFF5B49B7)),
                        SizedBox(width: 10),
                        Text('Appearance', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text('Choose a theme, or let PennyPal follow your device setting.', style: TextStyle(color: Color(0xFF71807A))),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeMode>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded), label: Text('Light')),
                          ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded), label: Text('Dark')),
                          ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.settings_brightness_rounded), label: Text('System')),
                        ],
                        selected: {PennyPalApp.of(context)?.themeMode ?? ThemeMode.system},
                        onSelectionChanged: (selection) => PennyPalApp.of(context)?.setThemeMode(selection.first),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppTheme.brand),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'PennyPal is an educational budgeting and savings tracker. It is not a bank, payment service, investment platform or professional financial adviser.',
                        style: TextStyle(height: 1.4, color: Color(0xFF52615B)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => _handleLogout(context),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Group extends StatelessWidget {
  final List<Widget> children;
  const _Group({required this.children});
  @override
  Widget build(BuildContext context) => Card(child: Column(children: children));
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title, sub;
  final VoidCallback tap;
  final Color bg, fg;
  const _Tile(this.icon, this.title, this.sub, this.tap, this.bg, this.fg);
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
    leading: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: fg),
    ),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
    subtitle: Text(sub),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: tap,
  );
}
