import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../services/auth_service.dart';
import '../services/admin_support_service.dart';
import '../main.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int tab = 0;
  String search = '';
  String supportFilter = 'open';

  final searchCtl = TextEditingController();
  final emailCtl = TextEditingController();
  final supportService = AdminSupportService.firestore();

  static const names = [
    'Dashboard',
    'Users',
    'Support',
    'Analytics',
    'Learning',
    'Announcements',
    'Admins',
  ];

  static const navIcons = [
    Icons.dashboard_rounded,
    Icons.people_alt_rounded,
    Icons.support_agent_rounded,
    Icons.insights_rounded,
    Icons.school_rounded,
    Icons.campaign_rounded,
    Icons.admin_panel_settings_rounded,
  ];

  @override
  void dispose() {
    searchCtl.dispose();
    emailCtl.dispose();
    super.dispose();
  }

  Future<String> role() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    return doc.data()?['role'] ?? 'user';
  }

  Future<void> audit(String action, [String? target]) {
    return FirebaseFirestore.instance.collection('adminAudit').add({
      'adminId': FirebaseAuth.instance.currentUser!.uid,
      'action': action,
      'targetId': target,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  void toast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> confirm(String title, String body) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> promote() async {
    final email = emailCtl.text.trim().toLowerCase();

    if (email.isEmpty) {
      return;
    }

    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (result.docs.isEmpty) {
      toast('No registered PennyPal account uses that email.');
      return;
    }

    await result.docs.first.reference.update({'role': 'admin'});

    await audit('promote_admin', result.docs.first.id);

    emailCtl.clear();
    toast('Administrator access granted.');
  }

  Future<void> editor(
    String collection, {
    DocumentSnapshot<Map<String, dynamic>>? doc,
  }) async {
    final data = doc?.data() ?? {};

    final titleController = TextEditingController(
      text: (data['title'] ?? '').toString(),
    );

    final bodyController = TextEditingController(
      text: (data['body'] ?? '').toString(),
    );

    final ok =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(doc == null ? 'Create item' : 'Edit item'),
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bodyController,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: 'Content'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save'),
              ),
            ],
          ),
        ) ??
        false;

    if (ok && titleController.text.trim().isNotEmpty) {
      final values = {
        'title': titleController.text.trim(),
        'body': bodyController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        'published': doc == null ? true : (data['published'] ?? true),
      };

      if (doc == null) {
        await FirebaseFirestore.instance.collection(collection).add({
          ...values,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await doc.reference.update(values);
      }

      await audit('${doc == null ? 'create' : 'edit'}_$collection', doc?.id);
    }

    titleController.dispose();
    bodyController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: role(),
      builder: (context, roleSnapshot) {
        if (!roleSnapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final myRole = roleSnapshot.data!;

        if (!['admin', 'superAdmin'].contains(myRole)) {
          return const Scaffold(
            body: Center(child: Text('Administrator access required.')),
          );
        }

        final wide = MediaQuery.sizeOf(context).width >= 900;

        return Scaffold(
          drawer: wide
              ? null
              : Drawer(child: SafeArea(child: nav(myRole, true))),
          appBar: wide
              ? null
              : AppBar(
                  title: const Text('PennyPal Admin'),
                  actions: [
                    IconButton(
                      tooltip: Theme.of(context).brightness == Brightness.dark ? 'Use light mode' : 'Use dark mode',
                      onPressed: () {
                        final dark = Theme.of(context).brightness == Brightness.dark;
                        PennyPalApp.of(context)?.setThemeMode(dark ? ThemeMode.light : ThemeMode.dark);
                      },
                      icon: Icon(Theme.of(context).brightness == Brightness.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                    ),
                    const SizedBox(width: 6),
                  ],
                ),
          body: Row(
            children: [
              if (wide) SizedBox(width: 250, child: nav(myRole, false)),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .snapshots(),
                  builder: (context, usersSnapshot) {
                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('supportQueries')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, supportSnapshot) {
                        if (!usersSnapshot.hasData ||
                            !supportSnapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        return page(
                          myRole,
                          usersSnapshot.data!.docs,
                          supportSnapshot.data!.docs,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget nav(String role, bool drawer) {
    final count = role == 'superAdmin' ? 7 : 6;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            const SizedBox(height: 8),
            const ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.brand,
                child: Icon(Icons.savings_rounded, color: Colors.white),
              ),
              title: Text(
                'PennyPal',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                'ADMIN CONSOLE',
                style: TextStyle(
                  color: AppTheme.brand,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 14),
            for (int i = 0; i < count; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  selected: i == tab,
                  selectedTileColor: AppTheme.mint,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  leading: Icon(
                    navIcons[i],
                    color: i == tab ? AppTheme.brand : null,
                  ),
                  title: Text(
                    names[i],
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: i == tab ? AppTheme.brand : null,
                    ),
                  ),
                  onTap: () {
                    setState(() => tab = i);

                    if (drawer) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: Icon(Theme.of(context).brightness == Brightness.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
              title: Text(Theme.of(context).brightness == Brightness.dark ? 'Light mode' : 'Dark mode'),
              subtitle: const Text('Appearance'),
              onTap: () {
                final dark = Theme.of(context).brightness == Brightness.dark;
                PennyPalApp.of(context)?.setThemeMode(dark ? ThemeMode.light : ThemeMode.dark);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Sign out'),
              onTap: () => AuthService.instance.logout(),
            ),
          ],
        ),
      ),
    );
  }

  Widget page(
    String role,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> users,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> support,
  ) {
    if (tab == 1) {
      return usersPage(users, role);
    }

    if (tab == 2) {
      return supportPage(support);
    }

    if (tab == 3) {
      return analytics(users, support);
    }

    if (tab == 4) {
      return content(
        'learningContent',
        'Learning content',
        Icons.school_rounded,
      );
    }

    if (tab == 5) {
      return content('announcements', 'Announcements', Icons.campaign_rounded);
    }

    if (tab == 6 && role == 'superAdmin') {
      return admins(users);
    }

    return dashboard(users, support, role);
  }

  Widget shell(String title, String subtitle, Widget body, {Widget? action}) {
    final mobile = MediaQuery.sizeOf(context).width < 700;
    return ListView(
      padding: EdgeInsets.fromLTRB(mobile ? 16 : 28, mobile ? 18 : 28, mobile ? 16 : 28, 32),
      children: [
        if (mobile)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              if (action != null) ...[
                const SizedBox(height: 14),
                SizedBox(width: double.infinity, child: action),
              ],
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              ?action,
            ],
          ),
        SizedBox(height: mobile ? 18 : 24),
        body,
      ],
    );
  }

  Widget dashboard(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> users,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> support,
    String role,
  ) {
    final adminCount = users.where((u) => ['admin', 'superAdmin'].contains(u.data()['role'])).length;
    final studentCount = users.length - adminCount;
    final openSupport = support.where((d) => d.data()['status'] != 'closed').length;
    final closedSupport = support.length - openSupport;
    final mobile = MediaQuery.sizeOf(context).width < 700;

    Widget miniStatus(String label, int value, Color color, IconData icon) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(color: color.withValues(alpha: .09), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ])),
      ]),
    );

    final recentCard = Card(
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(mobile ? 16 : 22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Recent Support Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              SizedBox(height: 2),
              Text('Latest inquiries from students', style: TextStyle(fontSize: 12)),
            ])),
            if (!mobile) FilledButton.icon(onPressed: () => setState(() => tab = 2), icon: const Icon(Icons.visibility_rounded), label: const Text('View all')),
          ]),
          const SizedBox(height: 14),
          if (support.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 28), child: Center(child: Text('No support requests yet')))
          else
            ...support.take(mobile ? 4 : 5).map((document) {
              final data = document.data();
              final status = (data['status'] ?? 'open').toString();
              final isOpen = status != 'closed';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => supportDetails(document),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.outlineVariant), borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [
                      CircleAvatar(backgroundColor: (isOpen ? Colors.orange : Colors.green).withValues(alpha: .10), child: Icon(isOpen ? Icons.mail_outline_rounded : Icons.check_rounded, color: isOpen ? Colors.orange : Colors.green)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text((data['subject'] ?? 'Support Request').toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text((data['email'] ?? data['name'] ?? 'Student').toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ])),
                      const SizedBox(width: 8),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: (isOpen ? Colors.orange : Colors.green).withValues(alpha: .10), borderRadius: BorderRadius.circular(20)), child: Text(isOpen ? 'OPEN' : 'CLOSED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isOpen ? Colors.orange.shade800 : Colors.green.shade800))),
                    ]),
                  ),
                ),
              );
            }),
          if (mobile) SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => setState(() => tab = 2), icon: const Icon(Icons.arrow_forward_rounded), label: const Text('View all support requests'))),
        ]),
      ),
    );

    return shell(
      'Operations overview',
      '${role == 'superAdmin' ? 'Super Admin' : 'Administrator'} workspace',
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        LayoutBuilder(builder: (context, c) {
          final columns = c.maxWidth < 520 ? 2 : c.maxWidth < 1050 ? 2 : 4;
          final gap = mobile ? 10.0 : 16.0;
          final width = (c.maxWidth - gap * (columns - 1)) / columns;
          final cards = [
            statCard('Students', '$studentCount', Icons.school_rounded, AppTheme.brand, 'Active learners', width: width, compact: mobile),
            statCard('Open Tickets', '$openSupport', Icons.support_agent_rounded, Colors.orange, 'Need attention', width: width, compact: mobile),
            statCard('Administrators', '$adminCount', Icons.shield_rounded, Colors.deepPurple, 'Team members', width: width, compact: mobile),
            statCard('Total Users', '${users.length}', Icons.people_alt_rounded, Colors.blue, 'All accounts', width: width, compact: mobile),
          ];
          return Wrap(spacing: gap, runSpacing: gap, children: cards);
        }),
        SizedBox(height: mobile ? 18 : 28),
        Card(
          elevation: 0,
          child: Padding(
            padding: EdgeInsets.all(mobile ? 16 : 22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Support Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), SizedBox(height: 2), Text('Ticket overview', style: TextStyle(fontSize: 12))])),
                if (!mobile) TextButton(onPressed: () => setState(() => tab = 2), child: const Text('View all')),
              ]),
              const SizedBox(height: 16),
              Row(children: [Expanded(child: miniStatus('Open', openSupport, Colors.orange, Icons.priority_high_rounded)), const SizedBox(width: 10), Expanded(child: miniStatus('Closed', closedSupport, Colors.green, Icons.check_circle_rounded))]),
              const SizedBox(height: 16),
              LinearProgressIndicator(value: support.isEmpty ? 0 : closedSupport / support.length, minHeight: 9, borderRadius: BorderRadius.circular(10)),
              const SizedBox(height: 8),
              Text(support.isEmpty ? 'No support cases yet' : '${((closedSupport / support.length) * 100).round()}% resolved', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ]),
          ),
        ),
        SizedBox(height: mobile ? 14 : 20),
        recentCard,
      ]),
      action: FilledButton.icon(onPressed: () => setState(() => tab = 1), icon: const Icon(Icons.search_rounded), label: const Text('Find student')),
    );
  }

  Widget buildStatRow(String label, int value, int total, Color color) {
    final percentage = (value / total * 100).toStringAsFixed(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '$value ($percentage%)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value / total,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: .1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget statCard(
    String label,
    String value,
    IconData icon,
    Color color,
    String subtitle, {
    double width = 220,
    bool compact = false,
  }) {
    return SizedBox(
      width: width,
      child: Card(
        elevation: 0,
        color: color.withValues(alpha: .08),
        child: Padding(
          padding: EdgeInsets.all(compact ? 14 : 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(padding: EdgeInsets.all(compact ? 8 : 12), decoration: BoxDecoration(color: color.withValues(alpha: .15), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: compact ? 20 : 24)),
            SizedBox(height: compact ? 10 : 16),
            Text(value, style: TextStyle(fontSize: compact ? 24 : 32, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            const SizedBox(height: 3),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: compact ? 12 : 13, fontWeight: FontWeight.w700)),
            if (!compact) ...[const SizedBox(height: 8), Text(subtitle, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500))],
          ]),
        ),
      ),
    );
  }

  Widget usersPage(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> users,
    String role,
  ) {
    final query = search.toLowerCase();
    final mobile = MediaQuery.sizeOf(context).width < 700;
    final filtered = users.where((document) {
      final data = document.data();
      return query.isEmpty || [data['name'], data['email'], data['mobile'], document.id].any((value) => (value ?? '').toString().toLowerCase().contains(query));
    }).toList();

    return shell(
      'User management',
      'Search by name, email, mobile or UID and open the student record',
      Column(children: [
        LayoutBuilder(builder: (context, constraints) {
          final students = users.where((d) => !['admin', 'superAdmin'].contains((d.data()['role'] ?? 'student').toString())).length;
          final admins = users.length - students;
          final width = constraints.maxWidth < 620 ? (constraints.maxWidth - 10) / 2 : 190.0;
          return Wrap(spacing: 10, runSpacing: 10, children: [
            statCard('Students', '$students', Icons.school_rounded, AppTheme.brand, 'Learner accounts', width: width, compact: true),
            statCard('Administrators', '$admins', Icons.admin_panel_settings_rounded, const Color(0xFF6C4CCF), 'Admin accounts', width: width, compact: true),
          ]);
        }),
        const SizedBox(height: 14),
        TextField(
          controller: searchCtl,
          onChanged: (value) => setState(() => search = value),
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search students...'),
        ),
        const SizedBox(height: 14),
        if (filtered.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(28), child: Center(child: Text('No matching users found.'))))
        else
          ...filtered.map((document) {
            final data = document.data();
            final name = (data['name'] ?? 'User').toString();
            final email = (data['email'] ?? '').toString();
            final mobileNo = (data['mobile'] ?? '').toString();
            final userRole = (data['role'] ?? 'student').toString();
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserAdminDetail(id: document.id, data: data, audit: audit))),
                child: Padding(
                  padding: EdgeInsets.all(mobile ? 14 : 16),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    CircleAvatar(backgroundColor: AppTheme.mint, child: Text(name.isEmpty ? 'U' : name[0].toUpperCase(), style: const TextStyle(color: AppTheme.brand, fontWeight: FontWeight.w900))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text(email, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      if (mobileNo.isNotEmpty) Text(mobileNo, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ])),
                    const SizedBox(width: 8),
                    if (!mobile) Chip(label: Text(userRole)),
                    if (mobile) Tooltip(message: userRole, child: Icon(userRole == 'student' ? Icons.school_outlined : Icons.admin_panel_settings_outlined, color: AppTheme.brand)),
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right_rounded),
                  ]),
                ),
              ),
            );
          }),
      ]),
    );
  }

  Widget supportPage(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> support,
  ) {
    final filtered = support.where((document) {
      if (supportFilter == 'all') {
        return true;
      }

      if (supportFilter == 'open') {
        return document.data()['status'] != 'closed';
      }

      return document.data()['status'] == 'closed';
    }).toList();

    return shell(
      'Support centre',
      'Resolve, reopen and remove support requests',
      Column(
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final open = support.where((d) => d.data()['status'] != 'closed').length;
            final closed = support.length - open;
            final width = constraints.maxWidth < 620 ? (constraints.maxWidth - 10) / 2 : 190.0;
            return Wrap(spacing: 10, runSpacing: 10, children: [
              statCard('Open', '$open', Icons.mark_email_unread_rounded, const Color(0xFFF39A16), 'Needs attention', width: width, compact: true),
              statCard('Resolved', '$closed', Icons.check_circle_rounded, const Color(0xFF43A957), 'Completed cases', width: width, compact: true),
            ]);
          }),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'open', label: Text('Open')),
                ButtonSegment(value: 'closed', label: Text('Resolved')),
                ButtonSegment(value: 'all', label: Text('All')),
              ],
              selected: {supportFilter},
              onSelectionChanged: (selection) {
                setState(() {
                  supportFilter = selection.first;
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          ...filtered.map((document) {
            final data = document.data();

            final closed = data['status'] == 'closed';
            final statusColor = closed ? const Color(0xFF43A957) : const Color(0xFFF39A16);
            return Card(
              color: statusColor.withValues(alpha: .045),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                leading: CircleAvatar(
                  backgroundColor: statusColor.withValues(alpha: .12),
                  child: Icon(Icons.support_agent_rounded, color: statusColor),
                ),
                title: Text(
                  (data['subject'] ?? data['type'] ?? 'Support').toString(),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  '${data['name'] ?? 'Student'} • ${data['email'] ?? ''}\n${(data['message'] ?? '').toString()}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                isThreeLine: true,
                trailing: Chip(
                  label: Text((data['status'] ?? 'open').toString()),
                ),
                onTap: () => supportDetails(document),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> supportDetails(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final replyController = TextEditingController(
      text: (document.data()['adminReply'] ?? '').toString(),
    );
    await showDialog<void>(
      context: context,
      builder: (dialogContext) =>
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: document.reference.snapshots(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data() ?? document.data();
              final closed = data['status'] == 'closed';
              final createdAt = data['createdAt'] is Timestamp
                  ? DateFormat(
                      'dd MMM yyyy, HH:mm',
                    ).format((data['createdAt'] as Timestamp).toDate())
                  : 'Pending sync';
              return AlertDialog(
                title: Text((data['subject'] ?? 'Support request').toString()),
                content: SizedBox(
                  width: 620,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(
                              label: Text(
                                (data['status'] ?? 'open').toString(),
                              ),
                            ),
                            Chip(
                              label: Text(
                                (data['type'] ?? 'support').toString(),
                              ),
                            ),
                            Chip(label: Text(createdAt)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          (data['name'] ?? 'Student').toString(),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text((data['email'] ?? '').toString()),
                        const Divider(height: 28),
                        const Text(
                          'Student message',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 6),
                        SelectableText((data['message'] ?? '').toString()),
                        const SizedBox(height: 18),
                        TextField(
                          controller: replyController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Reply to student',
                            hintText: 'Write a response or resolution note…',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton.icon(
                    onPressed: () async {
                      if (await confirm(
                        'Delete request?',
                        'This permanently removes the support request.',
                      )) {
                        await document.reference.delete();
                        await audit('delete_support', document.id);
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                      }
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Close'),
                  ),
                  FilledButton.tonal(
                    onPressed: () async {
                      await document.reference.update({
                        'status': closed ? 'open' : 'closed',
                        'updatedAt': FieldValue.serverTimestamp(),
                        if (!closed) 'resolvedAt': FieldValue.serverTimestamp(),
                      });
                      await audit(
                        closed ? 'reopen_support' : 'resolve_support',
                        document.id,
                      );
                    },
                    child: Text(closed ? 'Reopen' : 'Resolve'),
                  ),
                  FilledButton.icon(
                    onPressed: () async {
                      final reply = replyController.text.trim();
                      if (reply.isEmpty) {
                        toast('Write a reply first.');
                        return;
                      }
                      try {
                        await supportService.saveReply(
                          supportId: document.id,
                          reply: reply,
                        );
                        if (mounted) {
                          toast(
                            'Reply saved. The student can see it in Support and Notifications.',
                          );
                        }
                      } on AdminSupportException catch (error) {
                        if (mounted) toast(error.message);
                      } catch (_) {
                        if (mounted) {
                          toast('The support reply could not be completed.');
                        }
                      }
                    },
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Save reply'),
                  ),
                ],
              );
            },
          ),
    );
    replyController.dispose();
  }

  Widget stat(String label, String value, IconData icon, Color color, {double? cardWidth}) {
    final mobile = MediaQuery.sizeOf(context).width < 700;
    final width = cardWidth ?? 210.0;
    return SizedBox(
      width: width,
      child: Card(
        elevation: 0,
        color: color.withValues(alpha: .08),
        child: Padding(
          padding: EdgeInsets.all(mobile ? 14 : 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(radius: mobile ? 17 : 20, backgroundColor: color.withValues(alpha: .14), child: Icon(icon, color: color, size: mobile ? 18 : 21)),
            SizedBox(height: mobile ? 9 : 13),
            Text(value, style: TextStyle(fontSize: mobile ? 23 : 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: mobile ? 11 : 13, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }

  Widget analytics(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> users,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> support,
  ) {
    final closed = support.where((d) => d.data()['status'] == 'closed').length;
    final students = users
        .where((d) => !['admin', 'superAdmin'].contains(d.data()['role']))
        .length;
    return shell(
      'Analytics & activity',
      'Monitor PennyPal usage and operational activity',
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('activityEvents')
            .orderBy('createdAt', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, activity) {
          final events = activity.data?.docs ?? [];
          final created = events
              .where(
                (d) => (d.data()['event'] ?? '').toString().contains('created'),
              )
              .length;
          final updated = events
              .where(
                (d) => (d.data()['event'] ?? '').toString().contains('updated'),
              )
              .length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () async {
                    final generated = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());
                    final report =
                        'PennyPal Admin Analytics Report\n'
                        'Generated: $generated\n\n'
                        'Students: $students\n'
                        'Total accounts: ${users.length}\n'
                        'Support cases: ${support.length}\n'
                        'Resolved: $closed\n'
                        'Open: ${support.length - closed}\n'
                        'Recent activity events: ${events.length}\n'
                        'Transactions created: $created\n'
                        'Transactions updated: $updated';
                    if (!mounted) return;
                    await showDialog<void>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Row(children: [
                          Icon(Icons.description_outlined, color: AppTheme.brand),
                          SizedBox(width: 10),
                          Expanded(child: Text('Analytics report')),
                        ]),
                        content: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: SingleChildScrollView(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(dialogContext).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: SelectableText(report),
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Close'),
                          ),
                          FilledButton.icon(
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: report));
                              if (dialogContext.mounted) {
                                ScaffoldMessenger.of(dialogContext).showSnackBar(
                                  const SnackBar(content: Text('Report copied. You can paste it into Word, email or Notes.')),
                                );
                              }
                            },
                            icon: const Icon(Icons.copy_rounded),
                            label: const Text('Copy report'),
                          ),
                        ],
                      ),
                    );
                    await audit('generate_analytics_report');
                  },
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Generate report'),
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 14.0;
                  final columns = constraints.maxWidth < 700 ? 2 : 4;
                  final cardWidth =
                      (constraints.maxWidth - gap * (columns - 1)) / columns;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      stat('Students', '$students', Icons.school_rounded,
                          AppTheme.brand, cardWidth: cardWidth),
                      stat('Recent events', '${events.length}', Icons.bolt_rounded,
                          Colors.blue, cardWidth: cardWidth),
                      stat('Support cases', '${support.length}', Icons.support_agent,
                          Colors.orange, cardWidth: cardWidth),
                      stat('Resolved', '$closed', Icons.task_alt, Colors.green,
                          cardWidth: cardWidth),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 760;
                  final resolution = Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Support resolution',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 15),
                          LinearProgressIndicator(
                            value: support.isEmpty
                                ? 0
                                : closed / support.length,
                            minHeight: 12,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            '$closed of ${support.length} requests resolved',
                          ),
                        ],
                      ),
                    ),
                  );
                  final activityCard = Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Transaction activity',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '$created created • $updated updated',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Based on the latest ${events.length} recorded application events.',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                  if (!wide) {
                    return Column(
                      children: [
                        resolution,
                        const SizedBox(height: 12),
                        activityCard,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: resolution),
                      const SizedBox(width: 12),
                      Expanded(child: activityCard),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recent application activity',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (activity.connectionState == ConnectionState.waiting)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (events.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No activity has been recorded yet.',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      else
                        ...events.take(10).map((d) {
                          final x = d.data();
                          final event = (x['event'] ?? 'activity')
                              .toString()
                              .replaceAll('_', ' ');
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              backgroundColor: AppTheme.mint,
                              child: Icon(
                                Icons.history_rounded,
                                color: AppTheme.brand,
                              ),
                            ),
                            title: Text(
                              event,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text('User ${x['userId'] ?? 'unknown'}'),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget content(String collection, String title, IconData icon) {
    return shell(
      title,
      collection == 'learningContent'
          ? 'Create and manage financial-literacy resources for students'
          : 'Create and manage student announcements',
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection(collection).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          final published = docs.where((d) => (d.data()['published'] ?? true) == true).length;
          final draft = docs.length - published;
          final summary = LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth < 620 ? (constraints.maxWidth - 10) / 2 : 190.0;
            return Wrap(spacing: 10, runSpacing: 10, children: [
              statCard('Published', '$published', Icons.check_circle_outline_rounded, AppTheme.brand, 'Visible to students', width: width, compact: true),
              statCard('Drafts', '$draft', Icons.edit_note_rounded, const Color(0xFFF39A16), 'Not yet published', width: width, compact: true),
            ]);
          });

          if (docs.isEmpty) {
            return Column(children: [summary, const SizedBox(height: 16), Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 46,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: AppTheme.mint,
                          child: Icon(icon, size: 32, color: AppTheme.brand),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          collection == 'learningContent'
                              ? 'No learning resources yet'
                              : 'No announcements yet',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          collection == 'learningContent'
                              ? 'Create the first financial-literacy lesson. It will become available in the student Learning Hub.'
                              : 'Create an announcement when you have an update for PennyPal students.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: () => editor(collection),
                          icon: const Icon(Icons.add),
                          label: Text(
                            collection == 'learningContent'
                                ? 'Create first lesson'
                                : 'Create announcement',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )]);
          }

          return Column(
            children: [summary, const SizedBox(height: 16), ...snapshot.data!.docs.map((document) {
              final data = document.data();

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.mint,
                    child: Icon(icon, color: AppTheme.brand),
                  ),
                  title: Text(
                    (data['title'] ?? 'Untitled').toString(),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    (data['body'] ?? '').toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Chip(
                        label: Text(
                          (data['published'] ?? true) ? 'Published' : 'Draft',
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            await editor(collection, doc: document);
                          }
                          if (value == 'toggle') {
                            await document.reference.update({
                              'published': !(data['published'] ?? true),
                              'updatedAt': FieldValue.serverTimestamp(),
                            });
                            await audit('publish_$collection', document.id);
                          }
                          if (value == 'delete' &&
                              await confirm(
                                'Delete item?',
                                'This cannot be undone.',
                              )) {
                            await document.reference.delete();
                            await audit('delete_$collection', document.id);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          PopupMenuItem(
                            value: 'toggle',
                            child: Text(
                              (data['published'] ?? true)
                                  ? 'Unpublish'
                                  : 'Publish',
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            })],
          );
        },
      ),
      action: FilledButton.icon(
        onPressed: () => editor(collection),
        icon: const Icon(Icons.add),
        label: const Text('Create'),
      ),
    );
  }

  Widget admins(List<QueryDocumentSnapshot<Map<String, dynamic>>> users) {
    final administrators = users
        .where(
          (document) =>
              ['admin', 'superAdmin'].contains(document.data()['role']),
        )
        .toList();

    return shell(
      'Administrator access',
      'Grant and revoke administrator privileges',
      Column(
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth < 620 ? (constraints.maxWidth - 10) / 2 : 190.0;
            return Wrap(spacing: 10, runSpacing: 10, children: [
              statCard('Administrators', '${administrators.length}', Icons.admin_panel_settings_rounded, const Color(0xFF6C4CCF), 'Privileged accounts', width: width, compact: true),
              statCard('Super admins', '${administrators.where((d) => d.data()['role'] == 'superAdmin').length}', Icons.shield_rounded, AppTheme.brand, 'Full access', width: width, compact: true),
            ]);
          }),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextField(
                    controller: emailCtl,
                    decoration: const InputDecoration(
                      labelText: 'Registered user email',
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: promote,
                      icon: const Icon(Icons.admin_panel_settings),
                      label: const Text('Make admin'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: administrators.map((document) {
                final data = document.data();

                return ListTile(
                  title: Text(
                    (data['name'] ?? 'Admin').toString(),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text((data['email'] ?? '').toString()),
                  trailing: data['role'] == 'superAdmin'
                      ? const Chip(label: Text('Super Admin'))
                      : TextButton(
                          onPressed: () async {
                            if (await confirm(
                              'Revoke admin?',
                              'Return this account to student access?',
                            )) {
                              await document.reference.update({
                                'role': 'student',
                              });

                              await audit('revoke_admin', document.id);
                            }
                          },
                          child: const Text('Revoke'),
                        ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class UserAdminDetail extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  final Future<void> Function(String, [String?]) audit;

  const UserAdminDetail({
    super.key,
    required this.id,
    required this.data,
    required this.audit,
  });

  Future<void> remove(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> reference,
    String kind,
  ) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete $kind?'),
            content: const Text(
              'This permanently removes the selected record.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (ok) {
      await reference.delete();
      await audit('delete_$kind', reference.id);
    }
  }

  Widget records(String collection, String label, IconData icon) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(id)
          .collection(collection)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No $label found.'));
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: snapshot.data!.docs.map((document) {
            final values = document.data();

            final title =
                (values['category'] ??
                        values['name'] ??
                        values['type'] ??
                        values['month'] ??
                        label)
                    .toString();

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.mint,
                  child: Icon(icon, color: AppTheme.brand),
                ),
                title: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  values.entries
                      .where((entry) => entry.key != 'userId')
                      .take(4)
                      .map((entry) => '${entry.key}: ${entry.value}')
                      .join(' • '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      remove(context, document.reference, label);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete record'),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = (data['name'] ?? 'Student').toString();

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(name),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Transactions'),
              Tab(text: 'Budgets'),
              Tab(text: 'Savings goals'),
              Tab(text: 'Categories'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppTheme.mint,
                          child: Text(
                            name.isEmpty ? 'S' : name[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 24,
                              color: AppTheme.brand,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text((data['email'] ?? '').toString()),
                        Text((data['mobile'] ?? '').toString()),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          children: [
                            Chip(
                              label: Text(
                                (data['role'] ?? 'student').toString(),
                              ),
                            ),
                            if (data['countryCode'] != null)
                              Chip(label: Text(data['countryCode'].toString())),
                            if (data['currencyCode'] != null)
                              Chip(
                                label: Text(data['currencyCode'].toString()),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Administrative changes are confirmed and recorded in the audit log.',
                  style: TextStyle(color: Color(0xFF71807A)),
                ),
              ],
            ),
            records('transactions', 'transactions', Icons.receipt_long),
            records(
              'budgets',
              'budgets',
              Icons.account_balance_wallet_outlined,
            ),
            records('savingsGoals', 'savings goals', Icons.flag),
            records('categories', 'categories', Icons.category_outlined),
          ],
        ),
      ),
    );
  }
}
