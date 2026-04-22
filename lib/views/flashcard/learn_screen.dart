import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'flashcard_screen.dart';

////////////////////////////////////////////////////////////
/// CONFIG — thay bằng key thật của bạn
////////////////////////////////////////////////////////////

const _kUnsplashAccessKey = "YOUR_UNSPLASH_ACCESS_KEY";

////////////////////////////////////////////////////////////
/// MODEL
////////////////////////////////////////////////////////////

class VocabWord {
  final String id;
  final String word;
  final String meaning;
  final String phonetic;
  final String example;
  final String exampleVi;
  String imageUrl; // mutable — điền sau khi fetch Unsplash

  VocabWord({
    required this.id,
    required this.word,
    required this.meaning,
    required this.phonetic,
    required this.example,
    required this.exampleVi,
    this.imageUrl = "",
  });

  factory VocabWord.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return VocabWord(
      id:        doc.id,
      word:      d["word"]      as String? ?? "",
      meaning:   d["meaning"]   as String? ?? "",
      phonetic:  d["phonetic"]  as String? ?? "",
      example:   d["example"]   as String? ?? "",
      exampleVi: d["exampleVi"] as String? ?? "",
      imageUrl:  d["imageUrl"]  as String? ?? "",
    );
  }
}

////////////////////////////////////////////////////////////
/// LEARN FLASHCARD SCREEN
////////////////////////////////////////////////////////////

class LearnFlashcardScreen extends StatefulWidget {
  final VocabTopic topic;
  const LearnFlashcardScreen({super.key, required this.topic});

  @override
  State<LearnFlashcardScreen> createState() =>
      _LearnFlashcardScreenState();
}

class _LearnFlashcardScreenState extends State<LearnFlashcardScreen>
    with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────
  List<VocabWord> _words = [];
  int _currentIndex = 0;
  bool _loading = true;
  bool _flipped = false;          // false = mặt trước (EN), true = mặt sau (VI)
  bool _speaking = false;

  // ── TTS ────────────────────────────────────────────────
  final FlutterTts _tts = FlutterTts();

  // ── Animation ──────────────────────────────────────────
  late final AnimationController _flipCtrl;
  late final Animation<double> _flipAnim;

  @override
  void initState() {
    super.initState();

    // Flip animation
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut),
    );

    // TTS config
    _tts.setLanguage("en-US");
    _tts.setSpeechRate(0.45);
    _tts.setPitch(1.0);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speaking = false);
    });

    _loadWords();
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    _tts.stop();
    super.dispose();
  }

  // ── Load từ vựng từ Firestore ──────────────────────────
  Future<void> _loadWords() async {
    final snap = await FirebaseFirestore.instance
        .collection("topics")
        .doc(widget.topic.id)
        .collection("words")
        .get();

    final words = snap.docs.map((d) => VocabWord.fromDoc(d)).toList();

    // Fetch Unsplash ảnh cho từng từ (chạy song song)
    await Future.wait(
      words.map((w) => _fetchImage(w)),
    );

    if (mounted) {
      setState(() {
        _words = words;
        _loading = false;
      });
    }
  }

  // ── Fetch ảnh Unsplash ─────────────────────────────────
  Future<void> _fetchImage(VocabWord word) async {
    if (word.imageUrl.isNotEmpty) return; // đã có URL thì bỏ qua

    try {
      final uri = Uri.parse(
        "https://api.unsplash.com/search/photos"
            "?query=${Uri.encodeComponent(word.word)}"
            "&per_page=1"
            "&orientation=landscape"
            "&client_id=$_kUnsplashAccessKey",
      );
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final results = json["results"] as List;
        if (results.isNotEmpty) {
          word.imageUrl =
              results[0]["urls"]["regular"] as String? ?? "";
        }
      }
    } catch (_) {
      // Không có ảnh thì dùng placeholder
    }
  }

  // ── TTS phát âm ────────────────────────────────────────
  Future<void> _speak(String text) async {
    if (_speaking) {
      await _tts.stop();
      setState(() => _speaking = false);
      return;
    }
    setState(() => _speaking = true);
    await _tts.speak(text);
  }

  // ── Lật card ───────────────────────────────────────────
  void _flipCard() {
    if (_flipped) {
      _flipCtrl.reverse();
    } else {
      _flipCtrl.forward();
    }
    setState(() => _flipped = !_flipped);
  }

  // ── Chuyển sang từ tiếp theo ───────────────────────────
  void _nextWord() {
    if (_currentIndex >= _words.length - 1) return;
    _flipCtrl.reset();
    setState(() {
      _flipped = false;
      _currentIndex++;
      _speaking = false;
    });
    _tts.stop();
  }

  // ── Quay lại từ trước ──────────────────────────────────
  void _prevWord() {
    if (_currentIndex <= 0) return;
    _flipCtrl.reset();
    setState(() {
      _flipped = false;
      _currentIndex--;
      _speaking = false;
    });
    _tts.stop();
  }

  // ── Lưu tiến độ học vào Firestore ─────────────────────
  Future<void> _markLearned() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final word = _words[_currentIndex];
    final colorHex = "#${widget.topic.color.value.toRadixString(16).substring(2)}";

    // 1. Lưu vào learned_words để Review hiển thị
    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("learned_words")
        .doc("${widget.topic.id}_${word.id}")
        .set({
      "uid":        user.uid,
      "wordId":     word.id,
      "word":       word.word,
      "meaning":    word.meaning,
      "phonetic":   word.phonetic,
      "example":    word.example,
      "exampleVi":  word.exampleVi,
      "topicId":    widget.topic.id,
      "topicName":  widget.topic.name,
      "topicNameVi":widget.topic.nameVi,
      "topicEmoji": widget.topic.emoji,
      "topicColor": colorHex,
      "learnedAt":  FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 2. Cập nhật vocabulary_progress (giữ nguyên)
    await FirebaseFirestore.instance
        .collection("vocabulary_progress")
        .doc("${user.uid}_${word.id}")
        .set({
      "uid":       user.uid,
      "wordId":    word.id,
      "topicId":   widget.topic.id,
      "strength":  1.0,
      "learnedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 3. Cập nhật study_sessions hôm nay
    final today = DateTime.now();
    final dateKey =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    final sessionRef = FirebaseFirestore.instance
        .collection("study_sessions")
        .doc("${user.uid}_$dateKey");

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(sessionRef);
      if (snap.exists) {
        tx.update(sessionRef, {
          "wordsLearned": FieldValue.increment(1),
        });
      } else {
        tx.set(sessionRef, {
          "uid":          user.uid,
          "date":         Timestamp.fromDate(today),
          "wordsLearned": 1,
        });
      }
    });

    // 4. Cập nhật wordsLearned trong users/{uid}
    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .update({"wordsLearned": FieldValue.increment(1)});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Đã ghi nhớ "${word.word}"'),
          duration: const Duration(seconds: 1),
          backgroundColor: const Color(0xFF06D6A0),
        ),
      );
    }

    _nextWord();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF667eea),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "${widget.topic.emoji} ${widget.topic.name}",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          if (!_loading)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  "${_currentIndex + 1}/${_words.length}",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(
          child: CircularProgressIndicator(color: Color(0xFF667eea)))
          : _words.isEmpty
          ? _buildEmptyWords()
          : _buildContent(),
    );
  }

  // ── Màn hình trống (chưa có từ) ───────────────────────
  Widget _buildEmptyWords() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("📭", style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text(
            "Chủ đề này chưa có từ vựng",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddWordSheet(),
            icon: const Icon(Icons.add),
            label: const Text("Thêm từ vựng"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ── Nội dung chính ─────────────────────────────────────
  Widget _buildContent() {
    final word = _words[_currentIndex];

    return Column(
      children: [
        // Progress bar
        _ProgressBar(
          current: _currentIndex + 1,
          total: _words.length,
          color: widget.topic.color,
        ),

        Expanded(
          child: SingleChildScrollView(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                // ── Flashcard (lật được) ───────────────
                GestureDetector(
                  onTap: _flipCard,
                  child: AnimatedBuilder(
                    animation: _flipAnim,
                    builder: (_, __) {
                      final angle = _flipAnim.value * 3.14159;
                      final showFront = _flipAnim.value < 0.5;

                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(angle),
                        child: showFront
                            ? _CardFront(
                          word: word,
                          color: widget.topic.color,
                          speaking: _speaking,
                          onSpeak: () => _speak(word.word),
                        )
                            : Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..rotateY(3.14159),
                          child: _CardBack(word: word),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Gợi ý lật
                if (!_flipped)
                  Text(
                    "Nhấn vào card để xem nghĩa",
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                  ),

                const SizedBox(height: 20),

                // ── Ví dụ câu ─────────────────────────
                _ExampleCard(word: word, color: widget.topic.color),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),

        // ── Bottom controls ─────────────────────────────
        _BottomControls(
          onPrev:         _currentIndex > 0 ? _prevWord : null,
          onNext:         _currentIndex < _words.length - 1 ? _nextWord : null,
          onLearned:      _markLearned,
          onAddWord:      _showAddWordSheet,
          isLastCard:     _currentIndex == _words.length - 1,
          topicColor:     widget.topic.color,
        ),
      ],
    );
  }

  // ── Sheet thêm từ vựng ─────────────────────────────────
  void _showAddWordSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddWordSheet(
        topicId: widget.topic.id,
        topicColor: widget.topic.color,
        onAdded: _loadWords,
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// CARD FRONT — tiếng Anh + phiên âm + ảnh + loa
////////////////////////////////////////////////////////////

class _CardFront extends StatelessWidget {
  final VocabWord word;
  final Color color;
  final bool speaking;
  final VoidCallback onSpeak;
  const _CardFront({
    required this.word,
    required this.color,
    required this.speaking,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 280),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Ảnh từ vựng
          ClipRRect(
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
            child: word.imageUrl.isNotEmpty
                ? Image.network(
              word.imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _imagePlaceholder(color),
            )
                : _imagePlaceholder(color),
          ),

          // Từ + phiên âm + loa
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        word.word,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF222222),
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Nút loa
                    GestureDetector(
                      onTap: onSpeak,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: speaking
                              ? color
                              : color.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          speaking
                              ? Icons.volume_up_rounded
                              : Icons.volume_up_outlined,
                          color: speaking ? Colors.white : color,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                if (word.phonetic.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    word.phonetic,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder(Color color) {
    return Container(
      height: 180,
      width: double.infinity,
      color: color.withOpacity(0.08),
      child: Center(
        child: Icon(Icons.image_outlined,
            size: 56, color: color.withOpacity(0.3)),
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// CARD BACK — nghĩa tiếng Việt
////////////////////////////////////////////////////////////

class _CardBack extends StatelessWidget {
  final VocabWord word;
  const _CardBack({required this.word});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 280),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          const Text(
            "Nghĩa tiếng Việt",
            style: TextStyle(
              color: Colors.white60,
              fontSize: 14,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              word.meaning,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// EXAMPLE CARD
////////////////////////////////////////////////////////////

class _ExampleCard extends StatelessWidget {
  final VocabWord word;
  final Color color;
  const _ExampleCard({required this.word, required this.color});

  @override
  Widget build(BuildContext context) {
    if (word.example.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Ví dụ",
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Highlight từ vựng trong câu ví dụ
          _HighlightedText(
            text: word.example,
            keyword: word.word,
            highlightColor: color,
          ),

          if (word.exampleVi.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              word.exampleVi,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// HIGHLIGHTED TEXT — tô đậm từ khoá trong câu ví dụ
////////////////////////////////////////////////////////////

class _HighlightedText extends StatelessWidget {
  final String text;
  final String keyword;
  final Color highlightColor;
  const _HighlightedText({
    required this.text,
    required this.keyword,
    required this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final lower = text.toLowerCase();
    final kLower = keyword.toLowerCase();
    final idx = lower.indexOf(kLower);

    if (idx == -1) {
      return Text(text,
          style: const TextStyle(
              fontSize: 16, color: Color(0xFF333333), height: 1.5));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(
            fontSize: 16, color: Color(0xFF333333), height: 1.5),
        children: [
          TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + keyword.length),
            style: TextStyle(
              color: highlightColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(text: text.substring(idx + keyword.length)),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// PROGRESS BAR
////////////////////////////////////////////////////////////

class _ProgressBar extends StatelessWidget {
  final int current;
  final int total;
  final Color color;
  const _ProgressBar({
    required this.current,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      color: Colors.grey.shade200,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: total == 0 ? 0 : current / total,
        child: Container(color: color),
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// BOTTOM CONTROLS
////////////////////////////////////////////////////////////

class _BottomControls extends StatelessWidget {
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback onLearned;
  final VoidCallback onAddWord;
  final bool isLastCard;
  final Color topicColor;
  const _BottomControls({
    required this.onPrev,
    required this.onNext,
    required this.onLearned,
    required this.onAddWord,
    required this.isLastCard,
    required this.topicColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Nút trước
          _CircleBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onPrev,
            enabled: onPrev != null,
            color: topicColor,
          ),
          const SizedBox(width: 12),

          // Nút đã nhớ / hoàn thành
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onLearned,
              icon: Icon(
                isLastCard ? Icons.emoji_events_rounded : Icons.check_rounded,
                size: 20,
              ),
              label: Text(isLastCard ? "Hoàn thành!" : "Đã nhớ ✓"),
              style: ElevatedButton.styleFrom(
                backgroundColor: topicColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Nút tiếp
          _CircleBtn(
            icon: Icons.arrow_forward_ios_rounded,
            onTap: onNext,
            enabled: onNext != null,
            color: topicColor,
          ),
          const SizedBox(width: 8),

          // Nút thêm từ
          _CircleBtn(
            icon: Icons.add,
            onTap: onAddWord,
            enabled: true,
            color: Colors.grey.shade700,
          ),
        ],
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;
  final Color color;
  const _CircleBtn({
    required this.icon,
    required this.onTap,
    required this.enabled,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: enabled ? color.withOpacity(0.1) : Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? color : Colors.grey.shade400,
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// ADD WORD BOTTOM SHEET
////////////////////////////////////////////////////////////

class _AddWordSheet extends StatefulWidget {
  final String topicId;
  final Color topicColor;
  final VoidCallback onAdded;
  const _AddWordSheet({
    required this.topicId,
    required this.topicColor,
    required this.onAdded,
  });

  @override
  State<_AddWordSheet> createState() => _AddWordSheetState();
}

class _AddWordSheetState extends State<_AddWordSheet> {
  final _word      = TextEditingController();
  final _meaning   = TextEditingController();
  final _phonetic  = TextEditingController();
  final _example   = TextEditingController();
  final _exampleVi = TextEditingController();
  bool _loading = false;

  Future<void> _save() async {
    if (_word.text.trim().isEmpty || _meaning.text.trim().isEmpty) return;
    setState(() => _loading = true);

    final ref = FirebaseFirestore.instance
        .collection("topics")
        .doc(widget.topicId);

    await ref.collection("words").add({
      "word":      _word.text.trim(),
      "meaning":   _meaning.text.trim(),
      "phonetic":  _phonetic.text.trim(),
      "example":   _example.text.trim(),
      "exampleVi": _exampleVi.text.trim(),
      "imageUrl":  "",
      "createdAt": FieldValue.serverTimestamp(),
    });

    // Tăng wordCount
    await ref.update({"wordCount": FieldValue.increment(1)});

    if (mounted) {
      Navigator.pop(context);
      widget.onAdded();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Thêm từ vựng mới",
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),

              _field(_word,      "Từ tiếng Anh *",    "elephant"),
              const SizedBox(height: 10),
              _field(_meaning,   "Nghĩa tiếng Việt *", "con voi"),
              const SizedBox(height: 10),
              _field(_phonetic,  "Phiên âm",           "/ˈelɪfənt/"),
              const SizedBox(height: 10),
              _field(_example,   "Câu ví dụ (EN)",
                  "The elephant walked slowly."),
              const SizedBox(height: 10),
              _field(_exampleVi, "Câu ví dụ (VI)",     "Con voi đi chậm chạp."),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.topicColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _loading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                      : const Text("Thêm từ",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
      TextEditingController ctrl, String label, String hint) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: widget.topicColor, width: 1.5),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _word.dispose();
    _meaning.dispose();
    _phonetic.dispose();
    _example.dispose();
    _exampleVi.dispose();
    super.dispose();
  }
}