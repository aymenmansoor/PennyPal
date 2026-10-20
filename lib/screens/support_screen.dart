import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../core/validators.dart';
import '../core/app_theme.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController(),
      email = TextEditingController(),
      subject = TextEditingController(),
      message = TextEditingController();
  String type = 'support';
  int rating = 5;
  bool sending = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    name.text = user?.displayName ?? '';
    email.text = user?.email ?? '';
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    subject.dispose();
    message.dispose();
    super.dispose();
  }

  Future<void> send() async {
    if (!formKey.currentState!.validate() || sending) return;
    setState(() => sending = true);
    try {
      await FirestoreService.instance.sendSupport(
        FirebaseAuth.instance.currentUser!.uid,
        type: type,
        name: name.text.trim(),
        email: email.text.trim(),
        subject: subject.text.trim(),
        message: message.text.trim(),
        rating: type == 'feedback' ? rating : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Submitted. If you are offline, PennyPal will sync it when your connection returns.',
            ),
          ),
        );
        subject.clear();
        message.clear();
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback & Support')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
        children: [
          Form(
            key: formKey,
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: AppTheme.mint,
                          child: Icon(
                            Icons.support_agent_rounded,
                            color: AppTheme.brand,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                type == 'support'
                                    ? 'How can we help?'
                                    : 'Help us improve PennyPal',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                type == 'support'
                                    ? 'Send a support request and track the administrator response below.'
                                    : 'Share what worked, what did not, or what you would like to see next.',
                                style: const TextStyle(
                                  color: Color(0xFF71807A),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'support',
                        icon: Icon(Icons.support_agent_outlined),
                        label: Text('Support'),
                      ),
                      ButtonSegment(
                        value: 'feedback',
                        icon: Icon(Icons.rate_review_outlined),
                        label: Text('Feedback'),
                      ),
                    ],
                    selected: {type},
                    onSelectionChanged: (s) => setState(() => type = s.first),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: name,
                          validator: (v) => Validators.requiredText(v, 'Name'),
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.email,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        if (type == 'feedback') ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            initialValue: rating,
                            items: [1, 2, 3, 4, 5]
                                .map(
                                  (x) => DropdownMenuItem(
                                    value: x,
                                    child: Text('$x star${x == 1 ? '' : 's'}'),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => rating = v!),
                            decoration: const InputDecoration(
                              labelText: 'Rating',
                              prefixIcon: Icon(Icons.star_outline_rounded),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: subject,
                          validator: (v) =>
                              Validators.requiredText(v, 'Subject'),
                          decoration: const InputDecoration(
                            labelText: 'Subject',
                            prefixIcon: Icon(Icons.subject_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: message,
                          maxLines: 5,
                          validator: (v) =>
                              Validators.requiredText(v, 'Message'),
                          decoration: const InputDecoration(
                            labelText: 'Message',
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: sending ? null : send,
                            icon: sending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded),
                            label: Text(
                              sending
                                  ? 'Sending…'
                                  : 'Submit ${type == 'support' ? 'request' : 'feedback'}',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Your requests',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('supportQueries')
                .where('userId', isEqualTo: uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final docs = snapshot.data?.docs ?? [];
              docs.sort((a, b) {
                final at = a.data()['createdAt'] as Timestamp?;
                final bt = b.data()['createdAt'] as Timestamp?;
                return (bt?.millisecondsSinceEpoch ?? 0).compareTo(
                  at?.millisecondsSinceEpoch ?? 0,
                );
              });
              if (docs.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(22),
                    child: Text(
                      'No support requests yet. New requests and administrator replies will appear here.',
                    ),
                  ),
                );
              }
              return Column(
                children: docs.map((doc) {
                  final x = doc.data();
                  final reply = (x['adminReply'] ?? '').toString();
                  return Card(
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.mint,
                        child: Icon(
                          x['status'] == 'closed'
                              ? Icons.check_rounded
                              : Icons.chat_bubble_outline_rounded,
                          color: AppTheme.brand,
                        ),
                      ),
                      title: Text(
                        (x['subject'] ?? 'Support').toString(),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        '${x['status'] == 'closed' ? 'Resolved' : 'Open'}${reply.isNotEmpty ? ' • Admin replied' : ''}',
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(),
                              const Text(
                                'Your message',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 5),
                              Text((x['message'] ?? '').toString()),
                              if (reply.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppTheme.mint,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'PennyPal support',
                                        style: TextStyle(
                                          color: AppTheme.brand,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(reply),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
