import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../injection_container.dart';
import '../../../../core/config/theme.dart';

// ── Training module definitions ───────────────────────────────────────────────

class _Question {
  final String text;
  final List<String> options;
  final int correctIndex;

  const _Question(
      {required this.text,
      required this.options,
      required this.correctIndex});
}

class _Module {
  final String id;
  final String title;
  final String summary;
  final IconData icon;
  final List<String> keyPoints;
  final List<_Question> questions;

  const _Module({
    required this.id,
    required this.title,
    required this.summary,
    required this.icon,
    required this.keyPoints,
    required this.questions,
  });
}

final _modules = <_Module>[
  _Module(
    id: 'mod_professionalism',
    title: 'Service Standards & Professionalism',
    summary:
        'How to present yourself, greet customers, and deliver consistently high-quality service.',
    icon: Icons.handshake_outlined,
    keyPoints: [
      'Arrive on time — contact customer if delayed by more than 10 minutes',
      'Wear clean, presentable clothing on every visit',
      'Always knock and wait, never enter a room without permission',
      'Respect the customer\'s belongings and privacy',
      'If you notice a problem outside your scope, inform the customer',
    ],
    questions: [
      _Question(
        text: 'What should you do if you are running more than 10 minutes late?',
        options: [
          'Continue without informing the customer',
          'Contact the customer through the app',
          'Cancel the booking',
          'Ask a colleague to cover',
        ],
        correctIndex: 1,
      ),
      _Question(
        text: 'You notice a leaking pipe while cleaning. What do you do?',
        options: [
          'Ignore it — outside your scope',
          'Try to fix it yourself',
          'Inform the customer calmly',
          'Leave early to avoid liability',
        ],
        correctIndex: 2,
      ),
      _Question(
        text: 'When should you enter a room that is closed?',
        options: [
          'Whenever you need to clean it',
          'Only after knocking and receiving permission',
          'Never, unless specifically requested',
          'Only when no one is home',
        ],
        correctIndex: 1,
      ),
    ],
  ),
  _Module(
    id: 'mod_safety',
    title: 'Safety & Emergency Procedures',
    summary:
        'How to respond to emergencies, your own safety, and what to do in a crisis.',
    icon: Icons.health_and_safety_outlined,
    keyPoints: [
      'If you feel unsafe, press the SOS button immediately',
      'In a fire: alert the customer, leave the building, call 119',
      'For medical emergencies, call 1990 (Suwa Seriya) immediately',
      'Never handle electrical faults — report to the customer only',
      'Keep your phone charged on every shift',
    ],
    questions: [
      _Question(
        text: 'What is the Sri Lankan national ambulance number?',
        options: ['119', '1990', '111', '118'],
        correctIndex: 1,
      ),
      _Question(
        text: 'You smell gas in the kitchen. What is the FIRST action?',
        options: [
          'Try to locate the gas source',
          'Turn on a light to see better',
          'Alert the customer and leave immediately',
          'Continue working — it might be nothing',
        ],
        correctIndex: 2,
      ),
      _Question(
        text: 'You feel unsafe at a job. What should you do?',
        options: [
          'Continue and report after the job',
          'Call a friend',
          'Press the SOS button in the app immediately',
          'Wait and see if it improves',
        ],
        correctIndex: 2,
      ),
    ],
  ),
  _Module(
    id: 'mod_privacy',
    title: 'Privacy & PDPA Compliance',
    summary:
        'Your obligations under Sri Lanka\'s data protection principles and HelaService policy.',
    icon: Icons.lock_outline,
    keyPoints: [
      'Never share a customer\'s address, phone number, or personal details',
      'Do not take photos inside a customer\'s home without permission',
      'Customer data seen during a job must not be shared with anyone',
      'If a customer asks about another worker, do not give information',
      'Report any data concern to HelaService support immediately',
    ],
    questions: [
      _Question(
        text: 'A friend asks for the address of one of your customers. You should:',
        options: [
          'Share it — they might need a cleaner too',
          'Never share customer personal data with anyone',
          'Share it only if the friend is also a HelaService worker',
          'Ask the customer first',
        ],
        correctIndex: 1,
      ),
      _Question(
        text: 'You see a customer\'s bank statement on the table. You should:',
        options: [
          'Ignore it and continue working',
          'Read it quickly in case it has payment info',
          'Take a photo for your records',
          'Move it to clean underneath and read the front',
        ],
        correctIndex: 0,
      ),
      _Question(
        text: 'Taking a photo inside a customer\'s home for social media:',
        options: [
          'Is fine if no people are in the photo',
          'Is allowed only in the kitchen or bathroom',
          'Is never permitted without explicit written consent',
          'Is fine as long as the photo is not published',
        ],
        correctIndex: 2,
      ),
    ],
  ),
  _Module(
    id: 'mod_disputes',
    title: 'Handling Difficult Situations',
    summary:
        'How to de-escalate complaints, respond to criticism, and escalate unresolved issues.',
    icon: Icons.forum_outlined,
    keyPoints: [
      'Stay calm — never argue with a customer',
      'Listen fully before responding to a complaint',
      'If unsatisfied, offer to redo the affected area if time allows',
      'Never negotiate on prices — direct to HelaService if billing concerns',
      'If you cannot resolve an issue, use the in-app incident report',
    ],
    questions: [
      _Question(
        text: 'A customer is unhappy with the cleaning quality. First step:',
        options: [
          'Argue that you did a good job',
          'Leave immediately',
          'Listen calmly and offer to redo the specific area',
          'Reduce the bill on the spot',
        ],
        correctIndex: 2,
      ),
      _Question(
        text: 'A customer asks you to do extra work not in the booking. You should:',
        options: [
          'Do it for free to keep them happy',
          'Refuse and leave',
          'Politely explain it is not in the booking and suggest rebooking',
          'Charge them cash for the extra work',
        ],
        correctIndex: 2,
      ),
      _Question(
        text: 'A customer disputes the payment amount. The correct action is:',
        options: [
          'Handle it yourself and reduce the charge',
          'Ignore it — the app handles payments',
          'Direct the customer to HelaService support via the app',
          'Accept cash to resolve the dispute',
        ],
        correctIndex: 2,
      ),
    ],
  ),
  _Module(
    id: 'mod_payments',
    title: 'Payments, Wallet & No-Cash Policy',
    summary:
        'How earnings work, the no-cash rule, and how to handle wallet and payout questions.',
    icon: Icons.account_balance_wallet_outlined,
    keyPoints: [
      'HelaService is cashless — NEVER accept cash from customers',
      'Your earnings are held in escrow and released after the job is completed',
      'You receive 80% of the booking price; 20% is the platform fee',
      'Payouts are processed weekly to your registered bank account',
      'If a payout is delayed, contact support — never ask customers directly',
    ],
    questions: [
      _Question(
        text: 'A customer offers to pay you cash to avoid the app fee. You should:',
        options: [
          'Accept — it is more money for you',
          'Accept only if the amount is small',
          'Politely decline — HelaService is cashless',
          'Report it after accepting',
        ],
        correctIndex: 2,
      ),
      _Question(
        text: 'What percentage of the booking price do you receive as earnings?',
        options: ['100%', '90%', '80%', '70%'],
        correctIndex: 2,
      ),
      _Question(
        text: 'Your payout has not arrived. What do you do?',
        options: [
          'Ask the customer for the money directly',
          'Contact HelaService support through the app',
          'Stop accepting bookings until resolved',
          'Share your bank details with the customer',
        ],
        correctIndex: 1,
      ),
    ],
  ),
];

// ── Main training page ────────────────────────────────────────────────────────

class GoldTierTrainingPage extends StatefulWidget {
  const GoldTierTrainingPage({super.key});

  @override
  State<GoldTierTrainingPage> createState() => _GoldTierTrainingPageState();
}

class _GoldTierTrainingPageState extends State<GoldTierTrainingPage> {
  late Future<Map<String, dynamic>> _progressFuture;

  @override
  void initState() {
    super.initState();
    _progressFuture = _loadProgress();
  }

  Future<Map<String, dynamic>> _loadProgress() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {};
    final doc = await sl<FirebaseFirestore>()
        .collection('workers')
        .doc(uid)
        .collection('training_progress')
        .doc('gold_tier')
        .get();
    return doc.data() ?? {};
  }

  void _refresh() => setState(() => _progressFuture = _loadProgress());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gold Tier Training')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _progressFuture,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final progress = snap.data ?? {};
          final passed = <String>{
            for (final m in _modules)
              if (progress['${m.id}_passed'] == true) m.id,
          };
          final allPassed = passed.length == _modules.length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _ProgressHeader(passed: passed.length, total: _modules.length),
              const SizedBox(height: 20),
              if (allPassed) _CompletionBanner(),
              const SizedBox(height: 8),
              ...List.generate(_modules.length, (i) {
                final mod = _modules[i];
                final isPassed = passed.contains(mod.id);
                return _ModuleCard(
                  module: mod,
                  isPassed: isPassed,
                  index: i + 1,
                  onComplete: _refresh,
                );
              }),
            ]),
          );
        },
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final int passed, total;
  const _ProgressHeader({required this.passed, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.workspace_premium,
              color: AppTheme.primaryColor, size: 24),
          const SizedBox(width: 10),
          Text('Gold Tier Training',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
          const Spacer(),
          Text('$passed / $total',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.primaryColor)),
        ]),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: total > 0 ? passed / total : 0,
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
          valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 8),
        Text(
          'Complete all $total modules and pass each quiz (≥ 70%) to earn Gold Tier status.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ]),
    );
  }
}

class _CompletionBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        const Icon(Icons.star, color: Color(0xFFF59E0B), size: 28),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Training Complete!',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
          const SizedBox(height: 4),
          Text(
            'You\'ve passed all modules. Your Gold Tier application will be reviewed within 5 business days.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ])),
      ]),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final _Module module;
  final bool isPassed;
  final int index;
  final VoidCallback onComplete;

  const _ModuleCard({
    required this.module,
    required this.isPassed,
    required this.index,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isPassed
            ? AppTheme.successColor.withValues(alpha: 0.04)
            : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPassed
              ? AppTheme.successColor.withValues(alpha: 0.4)
              : Theme.of(context).colorScheme.outline,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isPassed
                ? AppTheme.successColor.withValues(alpha: 0.12)
                : AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isPassed ? Icons.check_circle : module.icon,
            color: isPassed ? AppTheme.successColor : AppTheme.primaryColor,
            size: 22,
          ),
        ),
        title: Text(
          '$index. ${module.title}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              decoration: isPassed ? TextDecoration.none : null),
        ),
        subtitle: Text(module.summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall),
        trailing: isPassed
            ? const Icon(Icons.check_circle, color: AppTheme.successColor)
            : const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _ModuleDetailPage(
                module: module,
                isPassed: isPassed,
                onComplete: onComplete,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Module detail + quiz ──────────────────────────────────────────────────────

class _ModuleDetailPage extends StatefulWidget {
  final _Module module;
  final bool isPassed;
  final VoidCallback onComplete;

  const _ModuleDetailPage({
    required this.module,
    required this.isPassed,
    required this.onComplete,
  });

  @override
  State<_ModuleDetailPage> createState() => _ModuleDetailPageState();
}

class _ModuleDetailPageState extends State<_ModuleDetailPage> {
  bool _showingQuiz = false;
  final _answers = <int, int>{};
  bool? _quizPassed;
  int _score = 0;

  void _submitQuiz() {
    int correct = 0;
    for (int i = 0; i < widget.module.questions.length; i++) {
      if (_answers[i] == widget.module.questions[i].correctIndex) correct++;
    }
    final pct = correct / widget.module.questions.length;
    final passed = pct >= 0.7;
    setState(() {
      _score = correct;
      _quizPassed = passed;
    });
    if (passed) _saveProgress();
  }

  Future<void> _saveProgress() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await sl<FirebaseFirestore>()
        .collection('workers')
        .doc(uid)
        .collection('training_progress')
        .doc('gold_tier')
        .set(
      {
        '${widget.module.id}_passed': true,
        '${widget.module.id}_score': _score,
        '${widget.module.id}_completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.module.title)),
      body: _showingQuiz
          ? _QuizView(
              module: widget.module,
              answers: _answers,
              quizPassed: _quizPassed,
              score: _score,
              onAnswer: (q, a) => setState(() => _answers[q] = a),
              onSubmit: _submitQuiz,
              onDone: () => Navigator.pop(context),
            )
          : _ContentView(
              module: widget.module,
              isPassed: widget.isPassed,
              onStartQuiz: () => setState(() => _showingQuiz = true),
            ),
    );
  }
}

class _ContentView extends StatelessWidget {
  final _Module module;
  final bool isPassed;
  final VoidCallback onStartQuiz;

  const _ContentView({
    required this.module,
    required this.isPassed,
    required this.onStartQuiz,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(module.summary,
              style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(height: 24),
        Text('Key Points',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...module.keyPoints.map((point) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.check_circle_outline,
                color: AppTheme.primaryColor, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(point)),
          ]),
        )),
        const SizedBox(height: 24),
        if (isPassed)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              const Icon(Icons.check_circle, color: AppTheme.successColor),
              const SizedBox(width: 10),
              Text('Quiz passed!',
                  style: TextStyle(
                      color: AppTheme.successColor, fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton(
                  onPressed: onStartQuiz,
                  child: const Text('Retake')),
            ]),
          )
        else
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onStartQuiz,
              child: Text('Take Quiz (${module.questions.length} questions)'),
            ),
          ),
      ]),
    );
  }
}

class _QuizView extends StatelessWidget {
  final _Module module;
  final Map<int, int> answers;
  final bool? quizPassed;
  final int score;
  final void Function(int q, int a) onAnswer;
  final VoidCallback onSubmit;
  final VoidCallback onDone;

  const _QuizView({
    required this.module,
    required this.answers,
    required this.quizPassed,
    required this.score,
    required this.onAnswer,
    required this.onSubmit,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    if (quizPassed != null) {
      return _QuizResultView(
        passed: quizPassed!,
        score: score,
        total: module.questions.length,
        onRetake: () {},
        onDone: onDone,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Quiz — ${module.title}',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text('You need 70% to pass.',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 20),
        ...List.generate(module.questions.length, (qi) {
          final q = module.questions[qi];
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${qi + 1}. ${q.text}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...List.generate(q.options.length, (oi) {
              final selected = answers[qi] == oi;
              return GestureDetector(
                onTap: () => onAnswer(qi, oi),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: selected
                            ? AppTheme.primaryColor
                            : Theme.of(context).colorScheme.outline,
                        width: selected ? 2 : 1),
                    color: selected
                        ? AppTheme.primaryColor.withValues(alpha: 0.07)
                        : null,
                  ),
                  child: Row(children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: selected
                          ? AppTheme.primaryColor
                          : Theme.of(context).colorScheme.outline,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(q.options[oi])),
                  ]),
                ),
              );
            }),
            const SizedBox(height: 16),
          ]);
        }),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: answers.length == module.questions.length
                ? onSubmit
                : null,
            child: const Text('Submit Answers'),
          ),
        ),
      ]),
    );
  }
}

class _QuizResultView extends StatelessWidget {
  final bool passed;
  final int score, total;
  final VoidCallback onRetake;
  final VoidCallback onDone;

  const _QuizResultView({
    required this.passed,
    required this.score,
    required this.total,
    required this.onRetake,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (score / total * 100).round();
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(
          passed ? Icons.check_circle : Icons.cancel,
          size: 72,
          color: passed ? AppTheme.successColor : AppTheme.errorColor,
        ),
        const SizedBox(height: 20),
        Text(
          passed ? 'Quiz Passed!' : 'Try Again',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: passed ? AppTheme.successColor : AppTheme.errorColor,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '$score / $total correct  ($pct%)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          passed
              ? 'Great work! Module progress saved.'
              : 'You need at least 70% to pass. Re-read the module and try again.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onDone,
            child: const Text('Back to Training'),
          ),
        ),
      ]),
    );
  }
}
