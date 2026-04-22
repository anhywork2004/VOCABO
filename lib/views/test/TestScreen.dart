import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vocabodemo/data/services/ielts_seeder.dart';

/// TestScreen — Bài kiểm tra từ vựng trắc nghiệm (4 đáp án).
/// Tab 1: từ vựng của người dùng (vocabulary)
/// Tab 2: đề IELTS random từ collection ielts_questions
class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen>
    with TickerProviderStateMixin {
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final _db  = FirebaseFirestore.instance;

  late final TabController _tabCtrl;

  List<_Question> _questions  = [];
  int             _current    = 0;
  int             _score      = 0;
  int?            _chosen;
  bool            _answered   = false;
  bool            _loading    = true;
  bool            _finished   = false;
  String          _testMode   = 'word→meaning';
  bool            _isIelts    = false;

  late AnimationController _shakeCtrl;
  late Animation<double>   _shakeAnim;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        setState(() {
          _isIelts  = _tabCtrl.index == 1;
          _finished = false;
        });
        _loadQuestions();
      }
    });
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));
    _loadQuestions();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> _loadQuestions() async {
    setState(() { _loading = true; _finished = false; });
    try {
      List<_VocabItem> all = [];

      if (_isIelts) {
        // ── IELTS: đọc từ collection ielts_questions (random 60)
        final snap = await _db
            .collection('ielts_questions')
            .limit(200)
            .get();

        all = snap.docs
            .map((d) => _VocabItem.fromDoc(d))
            .where((v) => v.word.isNotEmpty && v.meaning.isNotEmpty)
            .toList()
          ..shuffle(Random());
      } else {
        // ── My Words: đọc từ learned_words của user
        final snap = await _db
            .collection('users')
            .doc(_uid)
            .collection('learned_words')
            .limit(60)
            .get();

        all = snap.docs
            .map((d) => _VocabItem.fromDoc(d))
            .where((v) => v.word.isNotEmpty && v.meaning.isNotEmpty)
            .toList()
          ..shuffle(Random());

        // Fallback: nếu learned_words rỗng thì dùng vocabulary cũ
        if (all.length < 4) {
          final snap2 = await _db
              .collection('users')
              .doc(_uid)
              .collection('vocabulary')
              .limit(60)
              .get();
          all = snap2.docs
              .map((d) => _VocabItem.fromDoc(d))
              .where((v) => v.word.isNotEmpty && v.meaning.isNotEmpty)
              .toList()
            ..shuffle(Random());
        }
      }

      if (all.length < 4) {
        setState(() => _loading = false);
        _showSnack(_isIelts
            ? 'Chưa có dữ liệu IELTS. Nhấn nút "Tải dữ liệu IELTS" để bắt đầu.'
            : 'Cần ít nhất 4 từ. Hãy học thêm từ vựng!');
        return;
      }

      final pool = all.take(20).toList();
      final questions = <_Question>[];

      for (int i = 0; i < pool.length; i++) {
        final correct = pool[i];
        final distractors = (List.of(pool)..remove(correct))
          ..shuffle(Random());
        final choices = [correct, ...distractors.take(3)]
          ..shuffle(Random());

        questions.add(_Question(
          vocab:        correct,
          choices:      choices,
          correctIndex: choices.indexOf(correct),
          mode:         _testMode,
        ));
      }

      setState(() {
        _questions = questions;
        _current   = 0;
        _score     = 0;
        _chosen    = null;
        _answered  = false;
        _loading   = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showSnack('Error: $e');
    }
  }

  // ── Answer ────────────────────────────────────────────────────────────────

  void _selectAnswer(int idx) {
    if (_answered) return;
    final isCorrect = idx == _questions[_current].correctIndex;
    if (isCorrect) _score++;
    else _shakeCtrl.forward(from: 0);

    // ✅ Ghi lại kết quả để hiển thị "Review Mistakes"
    _questions[_current].userCorrect = isCorrect;

    setState(() { _chosen = idx; _answered = true; });

    // Cập nhật trạng thái từ trên Firestore
    final word = _questions[_current].vocab;
    _db
        .collection('users')
        .doc(_uid)
        .collection('vocabulary')
        .doc(word.id)
        .update({
      'testScore':  FieldValue.increment(isCorrect ? 1 : 0),
      'testCount':  FieldValue.increment(1),
      'status':     isCorrect ? 'learned' : 'learning',
      'lastTest':   FieldValue.serverTimestamp(),
    });
  }

  void _next() {
    if (_current + 1 >= _questions.length) {
      _saveSession();
      setState(() => _finished = true);
    } else {
      setState(() {
        _current++;
        _chosen   = null;
        _answered = false;
      });
    }
  }

  Future<void> _saveSession() async {
    final pct = (_score / _questions.length * 100).round();
    await _db.collection('users').doc(_uid).set({
      'lastTestScore':  pct,
      'lastTestDate':   FieldValue.serverTimestamp(),
      'totalTests':     FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _seedIelts() async {
    setState(() => _loading = true);
    await IeltsSeeder.seed(
      onProgress: (msg) => debugPrint(msg),
    );
    await _loadQuestions();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      appBar: AppBar(
        title: const Text('Test'),
        centerTitle: true,
        backgroundColor: const Color(0xff3d40f1),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Mode toggle
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _loading || _finished
                  ? null
                  : () {
                setState(() {
                  _testMode = _testMode == 'word→meaning'
                      ? 'meaning→word'
                      : 'word→meaning';
                });
                _loadQuestions();
              },
              child: Text(
                _testMode == 'word→meaning' ? 'W→M' : 'M→W',
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _finished
          ? _ResultPage(
        score: _score,
        total: _questions.length,
        questions: _questions,
        onRetry: _loadQuestions,
        onExit: () => Navigator.pop(context),
      )
          : _questions.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined,
                size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _isIelts ? 'Chưa có dữ liệu IELTS' : 'Chưa đủ từ vựng',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              _isIelts
                  ? 'Nhấn bên dưới để tải 200+ từ IELTS Academic'
                  : 'Học ít nhất 4 từ để bắt đầu kiểm tra',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            if (_isIelts) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _seedIelts,
                icon: const Icon(Icons.download_rounded),
                label: const Text('Tải dữ liệu IELTS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF764ba2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Mất khoảng 1-2 phút, chỉ cần làm 1 lần',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      )
          : _QuizBody(
        question:  _questions[_current],
        current:   _current,
        total:     _questions.length,
        score:     _score,
        chosen:    _chosen,
        answered:  _answered,
        shakeAnim: _shakeAnim,
        onSelect:  _selectAnswer,
        onNext:    _next,
      ),
    );
  }
}

// ─── Quiz body ────────────────────────────────────────────────────────────────

class _QuizBody extends StatelessWidget {
  final _Question  question;
  final int        current, total, score;
  final int?       chosen;
  final bool       answered;
  final Animation<double> shakeAnim;
  final void Function(int) onSelect;
  final VoidCallback onNext;

  const _QuizBody({
    required this.question,
    required this.current,
    required this.total,
    required this.score,
    required this.chosen,
    required this.answered,
    required this.shakeAnim,
    required this.onSelect,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          color: const Color(0xFF764ba2),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${current + 1} / $total',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13)),
                  Text('Score: $score',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (current + 1) / total,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  minHeight: 5,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Prompt card
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 16,
                          offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        question.mode == 'word→meaning' ? 'What does this mean?' : 'Which word matches?',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        question.mode == 'word→meaning'
                            ? question.vocab.word
                            : question.vocab.meaning,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E)),
                      ),
                      if (question.mode == 'word→meaning' &&
                          question.vocab.phonetic.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(question.vocab.phonetic,
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade500)),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Choices
                ...List.generate(question.choices.length, (i) {
                  final label = question.mode == 'word→meaning'
                      ? question.choices[i].meaning
                      : question.choices[i].word;
                  final isCorrect = i == question.correctIndex;
                  final isChosen  = i == chosen;

                  Color? bg, border, textColor;
                  if (answered) {
                    if (isCorrect) {
                      bg = Colors.green.withOpacity(0.12);
                      border = Colors.green;
                      textColor = Colors.green.shade800;
                    } else if (isChosen) {
                      bg = Colors.red.withOpacity(0.10);
                      border = Colors.red;
                      textColor = Colors.red.shade800;
                    } else {
                      bg = Colors.grey.withOpacity(0.05);
                      border = Colors.grey.shade200;
                      textColor = Colors.grey.shade500;
                    }
                  }

                  final tile = GestureDetector(
                    onTap: () => onSelect(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(
                        color: bg ?? Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: border ?? Colors.grey.shade200,
                            width: answered && isCorrect ? 2 : 1),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Row(children: [
                        // Letter badge
                        Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: answered && isCorrect
                                ? Colors.green
                                : answered && isChosen
                                ? Colors.red
                                : const Color(0xFF764ba2)
                                .withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: answered && isCorrect
                                ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 16)
                                : answered && isChosen
                                ? const Icon(Icons.close_rounded,
                                color: Colors.white, size: 16)
                                : Text(
                                ['A', 'B', 'C', 'D'][i],
                                style: const TextStyle(
                                    color: Color(0xFF764ba2),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(label,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: textColor ?? Colors.black87)),
                        ),
                      ]),
                    ),
                  );

                  // Rung nhẹ khi chọn sai
                  if (answered && isChosen && !isCorrect) {
                    return AnimatedBuilder(
                      animation: shakeAnim,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(
                            sin(shakeAnim.value * pi * 4) * 6, 0),
                        child: child,
                      ),
                      child: tile,
                    );
                  }
                  return tile;
                }),

                // Next button
                if (answered)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF764ba2),
                        foregroundColor: Colors.white,
                        padding:
                        const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: onNext,
                      child: Text(
                        current + 1 >= total ? 'See Results' : 'Next →',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Result page ──────────────────────────────────────────────────────────────

class _ResultPage extends StatelessWidget {
  final int score, total;
  final List<_Question> questions;
  final VoidCallback onRetry, onExit;

  const _ResultPage({
    required this.score,
    required this.total,
    required this.questions,
    required this.onRetry,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final pct  = (score / total * 100).round();
    final emoji = pct >= 80 ? '🏆' : pct >= 60 ? '👍' : '💪';
    final msg   = pct >= 80
        ? 'Excellent!'
        : pct >= 60
        ? 'Good job!'
        : 'Keep practising!';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(emoji, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 10),
          Text(msg,
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('$score / $total correct ($pct%)',
              style: TextStyle(
                  fontSize: 16, color: Colors.grey.shade600)),
          const SizedBox(height: 28),

          // Score ring
          _ScoreRing(pct: pct),
          const SizedBox(height: 28),

          // Review wrong answers
          if (questions.any((q) => q.userCorrect == false))
            _WrongAnswerSection(
                questions:
                questions.where((q) => q.userCorrect == false).toList()),

          const SizedBox(height: 28),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.exit_to_app_rounded),
                label: const Text('Exit'),
                onPressed: onExit,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF764ba2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                onPressed: onRetry,
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  final int pct;
  const _ScoreRing({required this.pct});

  @override
  Widget build(BuildContext context) {
    final color = pct >= 80
        ? Colors.green
        : pct >= 60
        ? Colors.orange
        : Colors.red;
    return SizedBox(
      width: 120, height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: pct / 100,
            strokeWidth: 10,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation(color),
          ),
          Text('$pct%',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }
}

class _WrongAnswerSection extends StatelessWidget {
  final List<_Question> questions;
  const _WrongAnswerSection({required this.questions});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Review Mistakes',
            style:
            TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...questions.map((q) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: Colors.red.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(q.vocab.word,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(height: 4),
              Text('Correct: ${q.vocab.meaning}',
                  style: const TextStyle(
                      color: Colors.green,
                      fontSize: 14)),
            ],
          ),
        )),
      ],
    );
  }
}

// ─── Data models ──────────────────────────────────────────────────────────────

class _VocabItem {
  final String id, word, phonetic, meaning;
  _VocabItem(
      {required this.id,
        required this.word,
        required this.phonetic,
        required this.meaning});

  factory _VocabItem.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return _VocabItem(
      id:       doc.id,
      word:     d['word']    ?? '',
      phonetic: d['phonetic']?? '',
      meaning:  d['meaning'] ?? d['definition'] ?? '',
    );
  }
}

class _Question {
  final _VocabItem    vocab;
  final List<_VocabItem> choices;
  final int           correctIndex;
  final String        mode;
  bool?               userCorrect; // null = unanswered

  _Question({
    required this.vocab,
    required this.choices,
    required this.correctIndex,
    required this.mode,
  });
}