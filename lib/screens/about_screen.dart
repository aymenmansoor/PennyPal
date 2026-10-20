import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../widgets/responsive_layout.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('About PennyPal')),
    body: SingleChildScrollView(
      child: PageFrame(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.brandDark, AppTheme.brand],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white24,
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PennyPal',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Smart Money for Students',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Purpose
            Text(
              'Our Mission',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F6F1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'PennyPal empowers students to take control of their finances with simple, practical tools and educational guidance. We help you track spending, set budgets, build savings goals, and develop healthy money habits for life.',
                style: TextStyle(
                  height: 1.6,
                  color: Color(0xFF2C5B50),
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Key Features
            Text(
              'What PennyPal Offers',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            _FeatureItem(
              icon: Icons.trending_up_rounded,
              title: 'Track & Manage',
              description: 'Record income and expenses with ease',
            ),
            const SizedBox(height: 12),
            _FeatureItem(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Budget Planning',
              description: 'Set monthly budgets and monitor spending',
            ),
            const SizedBox(height: 12),
            _FeatureItem(
              icon: Icons.savings_outlined,
              title: 'Savings Goals',
              description: 'Plan and track your financial goals',
            ),
            const SizedBox(height: 12),
            _FeatureItem(
              icon: Icons.school_outlined,
              title: 'Financial Education',
              description: 'Learn money management fundamentals',
            ),
            const SizedBox(height: 12),
            _FeatureItem(
              icon: Icons.insights_outlined,
              title: 'Smart Insights',
              description: 'Understand your spending patterns',
            ),
            const SizedBox(height: 28),

            // Who We're For
            Text(
              'For Students, By Educators',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5D9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'PennyPal is designed specifically for students to build financial literacy early. Our content and tools are crafted with educators to ensure practical, age-appropriate guidance that works with real student budgets and lifestyles.',
                style: TextStyle(
                  height: 1.6,
                  color: Color(0xFF5C4A1A),
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Values
            Text(
              'Our Values',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            _ValueItem('Simple', 'Easy to understand, no jargon'),
            const SizedBox(height: 8),
            _ValueItem('Educational', 'Learn money management skills'),
            const SizedBox(height: 8),
            _ValueItem('Secure', 'Your data is protected and private'),
            const SizedBox(height: 8),
            _ValueItem('Practical', 'Real tools for real student life'),
            const SizedBox(height: 28),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F5F3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'Version 1.0',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Have questions or feedback? Visit our Feedback & Support screen.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFF71807A)),
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

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F6F1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.brand, size: 24),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            Text(
              description,
              style: const TextStyle(fontSize: 14, color: Color(0xFF71807A)),
            ),
          ],
        ),
      ),
    ],
  );
}

class _ValueItem extends StatelessWidget {
  final String title;
  final String description;

  const _ValueItem(this.title, this.description);

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        margin: const EdgeInsets.only(top: 2),
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: AppTheme.brand,
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            Text(
              description,
              style: const TextStyle(fontSize: 14, color: Color(0xFF71807A)),
            ),
          ],
        ),
      ),
    ],
  );
}
