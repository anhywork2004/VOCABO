import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class _LearnedTopic {
  final String topicId;
  final String topicName;
  final String topicNameVi;
  final String topicEmoji;
  final Color topicColor;
  final int wordCount;

  const _LearnedTopic({
    required this.topicId,
    required this.topicName,
    required this.topicNameVi,
    required this.topicEmoji,
    required this.topicColor,
    required this.wordCount,
  });
}

class _LearnedWord {
  final String id;
  final String word;
  final String meaning;
  final String phonetic;
  final String example;
  final String exampleVi;

  const _LearnedWord({
    required this.id,
    required this.word,
    required this.meaning,
    required this.phonetic,
    required this.example,
    required this.exampleVi,
  });

  factory _LearnedWord.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return _LearnedWord(
      id:        doc.id,
      word:      d['word']      ?? '',
      meaning:   d['meaning']   ?? '',
      phonetic:  d['phonetic']  ?? '',
      example:   d['example']   ?? '',
      exampleVi: d['exampleVi'] ?? '',
    );
  }
}

// ─── ReviewScreen — màn hình chọn chủ đề ─────────────────────────────────────

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            backgroundColor: const Color(0xFF667eea),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text(
                "Ôn tập",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                ),
                child: const Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 20, top: 40),
                    child: Text("🔁", style: TextStyle(fontSize: 48)),
                  ),
                ),
              ),
            ),
          ),
        ],
        body: uid.isEmpty
            ? const Center(child: Text("Vui lòng đăng nhập"))
            : _TopicListBody(uid: uid),
      ),
    );
  }
}

// ─── Danh sách chủ đề đã học ──────────────────────────────────────────────────

class _TopicListBody extends StatelessWidget {
  final String uid;
  const _TopicListBody({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('learned_words')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF667eea)));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _EmptyReview();
        }

        // Gom nhóm theo topicId
        final Map<String, _LearnedTopic> topicMap = {};
        final Map<String, int> countMap = {};

        for (final doc in docs) {
          final d = doc.data() as Map<String, dynamic>;
          final topicId = d['topicId'] as String? ?? '';
          if (topicId.isEmpty) continue;

          countMap[topicId] = (countMap[topicId] ?? 0) + 1;

          if (!topicMap.containsKey(topicId)) {
            final colorStr = d['topicColor'] as String? ?? 'FF667eea';
            final colorVal = int.tryParse(
                    colorStr.replaceFirst('#', '0xFF')) ??
                0xFF667eea;
            topicMap[topicId] = _LearnedTopic(
              topicId:     topicId,
              topicName:   d['topicName']   as String? ?? '',
              topicNameVi: d['topicNameVi'] as String? ?? '',
              topicEmoji:  d['topicEmoji']  as String? ?? '📚',
              topicColor:  Color(colorVal),
              wordCount:   0,
            );
          }
        }

        final topics = topicMap.entries.map((e) {
          final t = e.value;
          return _LearnedTopic(
            topicId:     t.topicId,
            topicName:   t.topicName,
            topicNameVi: t.topicNameVi,
            topicEmoji:  t.topicEmoji,
            topicColor:  t.topicColor,
            wordCount:   countMap[t.topicId] ?? 0,
          );
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                "Chủ đề đã học (${topics.length})",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF444444),
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.05,
                ),
                itemCount: topics.length,
                itemBuilder: (context, i) => _TopicCard(
                  topic: topics[i],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _ReviewWordsScreen(
                        uid:   uid,
                        topic: topics[i],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Topic Card ───────────────────────────────────────────────────────────────

class _TopicCard extends StatelessWidget {
  final _LearnedTopic topic;
  final VoidCallback onTap;
  const _TopicCard({required this.topic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              topic.topicColor.withOpacity(0.9),
              topic.topicColor.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: topic.topicColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Badge số từ
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${topic.wordCount} từ",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
            // Nội dung
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(topic.topicEmoji,
                      style: const TextStyle(fontSize: 34)),
                  const SizedBox(height: 8),
                  Text(
                    topic.topicName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    topic.topicNameVi,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── ReviewWordsScreen — flashcard ôn tập từng chủ đề ────────────────────────

class _ReviewWordsScreen extends StatefulWidget {
  final String uid;
  final _LearnedTopic topic;
  const _ReviewWordsScreen({required this.uid, required this.topic});

  @override
  State<_ReviewWordsScreen> createState() => _ReviewWordsScreenState();
}

class _ReviewWordsScreenState extends State<_ReviewWordsScreen>
    with SingleTickerProviderStateMixin {
  List<_LearnedWord> _words = [];
  int  _current   = 0;
  bool _isFlipped = false;
  bool _loading   = true;
  int  _known     = 0;
  int  _unknown   = 0;

  late AnimationController _flipCtrl;
  late Animation<double>    _flipAnim;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _flipAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut));
    _loadWords();
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadWords() async {
    setState(() => _loading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('learned_words')
          .where('topicId', isEqualTo: widget.topic.topicId)
          .get();

      final list = snap.docs
          .map((d) => _LearnedWord.fromDoc(d))
          .where((w) => w.word.isNotEmpty)
          .toList()
        ..shuffle(Random());

      setState(() {
        _words   = list;
        _current = 0;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _flip() {
    if (_isFlipped) {
      _flipCtrl.reverse();
    } else {
      _flipCtrl.forward();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  void _answer(bool knew) {
    knew ? _known++ : _unknown++;

    if (_isFlipped) {
      _flipCtrl.reverse();
      setState(() => _isFlipped = false);
    }

    if (_current + 1 >= _words.length) {
      _showResult();
    } else {
      setState(() => _current++);
    }
  }

  void _showResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Hoàn thành! 🎉',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ResultRow(Icons.check_circle_rounded,
                'Đã nhớ', _known, Colors.green),
            const SizedBox(height: 8),
            _ResultRow(Icons.replay_rounded,
                'Cần ôn thêm', _unknown, Colors.orange),
            const SizedBox(height: 8),
            _ResultRow(Icons.layers_rounded,
                'Tổng', _known + _unknown, Colors.blue),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Xong'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _known   = 0;
              _unknown = 0;
              _loadWords();
            },
            child: const Text('Ôn lại'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      appBar: AppBar(
        title: Text(
            "${widget.topic.topicEmoji} ${widget.topic.topicName}"),
        centerTitle: true,
        backgroundColor: widget.topic.topicColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadWords,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _words.isEmpty
              ? _EmptyWords(onBack: () => Navigator.pop(context))
              : Column(
                  children: [
                    // Progress bar
                    _ProgressBar(
                      current:    _current,
                      total:      _words.length,
                      known:      _known,
                      topicColor: widget.topic.topicColor,
                    ),
                    const SizedBox(height: 16),

                    // Flashcard
                    Expanded(
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 24),
                        child: GestureDetector(
                          onTap: _flip,
                          child: AnimatedBuilder(
                            animation: _flipAnim,
                            builder: (_, __) {
                              final angle = _flipAnim.value * pi;
                              final isFront = angle <= pi / 2;
                              return Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.001)
                                  ..rotateY(angle),
                                child: isFront
                                    ? _FrontFace(
                                        word:  _words[_current],
                                        color: widget.topic.topicColor,
                                      )
                                    : Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.identity()
                                          ..rotateY(pi),
                                        child: _BackFace(
                                            word:  _words[_current],
                                            color: widget.topic.topicColor),
                                      ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    // Hint / Buttons
                    if (!_isFlipped)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Nhấn vào thẻ để xem nghĩa',
                          style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13),
                        ),
                      ),

                    if (_isFlipped)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: _AnswerButton(
                                label: 'Ôn thêm',
                                icon:  Icons.replay_rounded,
                                color: Colors.orange,
                                onTap: () => _answer(false),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _AnswerButton(
                                label: 'Đã nhớ!',
                                icon:  Icons.check_rounded,
                                color: widget.topic.topicColor,
                                onTap: () => _answer(true),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const SizedBox(height: 76),
                  ],
                ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final int current, total, known;
  final Color topicColor;
  const _ProgressBar({
    required this.current,
    required this.total,
    required this.known,
    required this.topicColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: topicColor,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${current + 1} / $total',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13)),
              Text('✅ $known đã nhớ',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : (current + 1) / total,
              backgroundColor: Colors.white24,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FrontFace extends StatelessWidget {
  final _LearnedWord word;
  final Color color;
  const _FrontFace({required this.word, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            word.word,
            style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E)),
          ),
          if (word.phonetic.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              word.phonetic,
              style: TextStyle(
                  fontSize: 18, color: Colors.grey.shade500),
            ),
          ],
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app_rounded,
                  color: Colors.grey.shade300, size: 20),
              const SizedBox(width: 6),
              Text('Nhấn để lật',
                  style: TextStyle(
                      color: Colors.grey.shade400, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BackFace extends StatelessWidget {
  final _LearnedWord word;
  final Color color;
  const _BackFace({required this.word, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(word.word,
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const Divider(color: Colors.white24, height: 24),
          Text('Nghĩa',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.6),
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(word.meaning,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          if (word.example.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('"${word.example}"',
                      style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14)),
                  if (word.exampleVi.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(word.exampleVi,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13)),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _AnswerButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  const _ResultRow(this.icon, this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 10),
      Text(label, style: const TextStyle(fontSize: 15)),
      const Spacer(),
      Text('$count',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color)),
    ]);
  }
}

class _EmptyReview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("📭", style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text(
            "Chưa có từ nào để ôn tập",
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF444444)),
          ),
          const SizedBox(height: 8),
          const Text(
            "Hãy học từ vựng và nhấn \"Đã nhớ\" để lưu vào đây",
            style: TextStyle(color: Colors.grey, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EmptyWords extends StatelessWidget {
  final VoidCallback onBack;
  const _EmptyWords({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("🤔", style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text(
            "Không tìm thấy từ nào",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onBack,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Quay lại"),
          ),
        ],
      ),
    );
  }
}
