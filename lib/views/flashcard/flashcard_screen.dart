import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'learn_screen.dart';

////////////////////////////////////////////////////////////
/// PRESET TOPICS — chủ đề có sẵn với danh sách từ vựng
////////////////////////////////////////////////////////////

class PresetTopic {
  final String name;
  final String nameVi;
  final String emoji;
  final Color color;
  final List<String> words;

  const PresetTopic({
    required this.name,
    required this.nameVi,
    required this.emoji,
    required this.color,
    required this.words,
  });
}

const List<PresetTopic> kPresetTopics = [
  PresetTopic(
    name: "Animals",
    nameVi: "Động vật",
    emoji: "🐾",
    color: Color(0xFFFF6B6B),
    words: [
      "elephant","lion","tiger","dolphin","eagle","rabbit","wolf",
      "giraffe","penguin","crocodile","butterfly","octopus","kangaroo",
      "cheetah","gorilla","flamingo","panda","koala","jaguar","hawk",
    ],
  ),
  PresetTopic(
    name: "Food",
    nameVi: "Đồ ăn",
    emoji: "🍎",
    color: Color(0xFFFF9F1C),
    words: [
      "apple","banana","mango","strawberry","avocado","broccoli",
      "salmon","noodle","rice","cheese","chocolate","mushroom",
      "pineapple","coconut","almond","blueberry","cucumber","tomato",
      "watermelon","lemon",
    ],
  ),
  PresetTopic(
    name: "Travel",
    nameVi: "Du lịch",
    emoji: "✈️",
    color: Color(0xFF3A86FF),
    words: [
      "passport","luggage","airport","hotel","tourism","adventure",
      "destination","journey","ticket","reservation","landmark",
      "souvenir","itinerary","explore","culture","museum","beach",
      "mountain","cruise","backpack",
    ],
  ),
  PresetTopic(
    name: "Technology",
    nameVi: "Công nghệ",
    emoji: "💻",
    color: Color(0xFF8338EC),
    words: [
      "algorithm","database","network","software","hardware","cybersecurity",
      "artificial","interface","bandwidth","processor","wireless","browser",
      "download","encryption","firewall","server","protocol","digital",
      "innovation","automation",
    ],
  ),
  PresetTopic(
    name: "Business",
    nameVi: "Kinh doanh",
    emoji: "💼",
    color: Color(0xFF06D6A0),
    words: [
      "investment","revenue","profit","strategy","marketing","entrepreneur",
      "contract","negotiation","dividend","budget","shareholder","merger",
      "bankruptcy","franchise","commodity","inflation","interest","assets",
      "liability","capital",
    ],
  ),
  PresetTopic(
    name: "Health",
    nameVi: "Sức khoẻ",
    emoji: "❤️",
    color: Color(0xFFFF006E),
    words: [
      "medicine","symptom","diagnosis","therapy","nutrition","exercise",
      "vitamin","antibody","immune","vaccine","surgeon","pharmacy",
      "mental","anxiety","depression","recovery","prevention","hygiene",
      "cardiovascular","metabolism",
    ],
  ),
  PresetTopic(
    name: "Nature",
    nameVi: "Thiên nhiên",
    emoji: "🌿",
    color: Color(0xFF2EC4B6),
    words: [
      "forest","ocean","desert","volcano","glacier","ecosystem",
      "biodiversity","atmosphere","hurricane","earthquake","waterfall",
      "coral","drought","erosion","habitat","fossil","mineral",
      "rainfall","climate","lightning",
    ],
  ),
  PresetTopic(
    name: "Education",
    nameVi: "Giáo dục",
    emoji: "🎓",
    color: Color(0xFFFFBE0B),
    words: [
      "knowledge","scholarship","curriculum","academic","research",
      "examination","diploma","graduate","lecture","laboratory",
      "thesis","semester","tuition","discipline","textbook","assignment",
      "concept","theory","skill","certificate",
    ],
  ),
];

////////////////////////////////////////////////////////////
/// MODEL
////////////////////////////////////////////////////////////

class VocabTopic {
  final String id;
  final String name;
  final String nameVi;
  final String emoji;
  final Color color;
  final int wordCount;
  final bool isPreset;

  const VocabTopic({
    required this.id,
    required this.name,
    required this.nameVi,
    required this.emoji,
    required this.color,
    required this.wordCount,
    this.isPreset = false,
  });

  factory VocabTopic.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return VocabTopic(
      id:        doc.id,
      name:      d["name"]      as String? ?? "",
      nameVi:    d["nameVi"]    as String? ?? "",
      emoji:     d["emoji"]     as String? ?? "📚",
      color:     Color(int.parse(
          (d["color"] as String? ?? "FF667eea").replaceFirst("#", "0xFF"))),
      wordCount: (d["wordCount"] as num? ?? 0).toInt(),
      isPreset:  d["isPreset"]  as bool? ?? false,
    );
  }

  // Tạo từ PresetTopic (chưa có trong Firestore)
  static VocabTopic fromPreset(PresetTopic p) => VocabTopic(
    id:        "",
    name:      p.name,
    nameVi:    p.nameVi,
    emoji:     p.emoji,
    color:     p.color,
    wordCount: p.words.length,
    isPreset:  true,
  );
}

////////////////////////////////////////////////////////////
/// FLASHCARD SCREEN
////////////////////////////////////////////////////////////

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: const Color(0xFF667eea),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 60),
              title: const Text(
                "Học từ vựng",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF667eea),
                      const Color(0xFF764ba2),
                    ],
                  ),
                ),
                child: const Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 20, top: 40),
                    child: Text("📖", style: TextStyle(fontSize: 48)),
                  ),
                ),
              ),
            ),

            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TabBar(
                    controller: _tab,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: const EdgeInsets.all(4),
                    dividerColor: Colors.transparent,
                    labelColor: const Color(0xFF667eea),
                    unselectedLabelColor: Colors.white,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(text: "Chủ đề có sẵn"),
                      Tab(text: "Của tôi"),
                    ],
                  ),
                ),
              ),
            ),

            // 👉 FIX nút +
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: IconButton(
                  onPressed: () => _showAddTopicDialog(context),
                  icon: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          )
        ],
        body: TabBarView(
          controller: _tab,
          children: [
            // Tab 1: Chủ đề preset
            _PresetTopicsTab(),
            // Tab 2: Chủ đề người dùng tự tạo
            _MyTopicsTab(
              onAddTopic: () => _showAddTopicDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTopicDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddTopicSheet(),
    );
  }
}

////////////////////////////////////////////////////////////
/// TAB 1 — PRESET TOPICS
////////////////////////////////////////////////////////////

class _PresetTopicsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.05,
      ),
      itemCount: kPresetTopics.length,
      itemBuilder: (context, i) {
        final preset = kPresetTopics[i];
        return _PresetTopicCard(
          preset: preset,
          onTap: () => _openPreset(context, preset),
        );
      },
    );
  }

  // Khi tap: tạo topic trong Firestore nếu chưa có, rồi seed từ vựng
  Future<void> _openPreset(
      BuildContext context, PresetTopic preset) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Hiện loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _LoadingDialog(),
    );

    try {
      // Kiểm tra topic đã tồn tại chưa
      final existing = await FirebaseFirestore.instance
          .collection("topics")
          .where("uid", isEqualTo: user.uid)
          .where("name", isEqualTo: preset.name)
          .where("isPreset", isEqualTo: true)
          .get();

      String topicId;

      if (existing.docs.isNotEmpty) {
        // Đã có → dùng luôn
        topicId = existing.docs.first.id;
      } else {
        // Chưa có → tạo mới + seed từ vựng
        final colorHex =
            "#${preset.color.value.toRadixString(16).substring(2)}";

        final docRef =
        await FirebaseFirestore.instance.collection("topics").add({
          "uid":       user.uid,
          "name":      preset.name,
          "nameVi":    preset.nameVi,
          "emoji":     preset.emoji,
          "color":     colorHex,
          "wordCount": 0,
          "isPreset":  true,
          "createdAt": FieldValue.serverTimestamp(),
        });

        topicId = docRef.id;

        // Seed từ vựng từ API
        await _seedWords(topicId, preset.words);

        // Cập nhật wordCount
        final actualCount = await FirebaseFirestore.instance
            .collection("topics")
            .doc(topicId)
            .collection("words")
            .get()
            .then((s) => s.docs.length);

        await FirebaseFirestore.instance
            .collection("topics")
            .doc(topicId)
            .update({"wordCount": actualCount});
      }

      if (context.mounted) Navigator.pop(context); // đóng loading

      final topic = VocabTopic(
        id:        topicId,
        name:      preset.name,
        nameVi:    preset.nameVi,
        emoji:     preset.emoji,
        color:     preset.color,
        wordCount: preset.words.length,
        isPreset:  true,
      );

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => LearnFlashcardScreen(topic: topic)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: $e")),
        );
      }
    }
  }

  // Seed từ vựng: gọi dictionaryapi.dev + MyMemory dịch tiếng Việt
  Future<void> _seedWords(String topicId, List<String> words) async {
    final ref = FirebaseFirestore.instance
        .collection("topics")
        .doc(topicId)
        .collection("words");

    // Xử lý song song theo batch 5 từ để tránh rate limit
    for (int i = 0; i < words.length; i += 5) {
      final batch = words.sublist(
          i, i + 5 > words.length ? words.length : i + 5);
      await Future.wait(batch.map((w) => _fetchAndSaveWord(ref, w)));
    }
  }

  Future<void> _fetchAndSaveWord(
      CollectionReference ref, String word) async {
    try {
      // 1. Dictionary API — lấy phonetic + example
      final dictRes = await http
          .get(Uri.parse(
          "https://api.dictionaryapi.dev/api/v2/entries/en/$word"))
          .timeout(const Duration(seconds: 8));

      String phonetic = "";
      String example  = "";
      String defEn    = "";

      if (dictRes.statusCode == 200) {
        final data = jsonDecode(dictRes.body) as List;
        if (data.isNotEmpty) {
          final entry = data[0] as Map<String, dynamic>;

          // Phonetic
          phonetic = entry["phonetic"] as String? ?? "";
          if (phonetic.isEmpty) {
            final phonetics = entry["phonetics"] as List? ?? [];
            for (final p in phonetics) {
              final t = (p as Map)["text"] as String? ?? "";
              if (t.isNotEmpty) { phonetic = t; break; }
            }
          }

          // Definition + Example
          final meanings = entry["meanings"] as List? ?? [];
          for (final m in meanings) {
            final defs = (m as Map)["definitions"] as List? ?? [];
            for (final d in defs) {
              defEn   = (d as Map)["definition"] as String? ?? "";
              example = d["example"]   as String? ?? "";
              if (defEn.isNotEmpty) break;
            }
            if (defEn.isNotEmpty) break;
          }
        }
      }

      // 2. MyMemory API — dịch nghĩa sang tiếng Việt (miễn phí, no key)
      String meaningVi  = "";
      String exampleVi  = "";

      if (defEn.isNotEmpty) {
        meaningVi = await _translate(word);
        if (example.isNotEmpty) {
          exampleVi = await _translate(example);
        }
      } else {
        // Fallback: chỉ dịch từ đơn
        meaningVi = await _translate(word);
      }

      // 3. Lưu vào Firestore
      await ref.add({
        "word":      word,
        "meaning":   meaningVi.isNotEmpty ? meaningVi : word,
        "phonetic":  phonetic,
        "example":   example,
        "exampleVi": exampleVi,
        "imageUrl":  "",
        "createdAt": FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Nếu lỗi → lưu từ với dữ liệu tối thiểu
      try {
        await ref.add({
          "word":      word,
          "meaning":   word,
          "phonetic":  "",
          "example":   "",
          "exampleVi": "",
          "imageUrl":  "",
          "createdAt": FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
  }

  // MyMemory translate — free, 5000 ký tự/ngày, no API key
  Future<String> _translate(String text) async {
    try {
      final uri = Uri.parse(
        "https://api.mymemory.translated.net/get"
            "?q=${Uri.encodeComponent(text)}&langpair=en|vi",
      );
      final res =
      await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        return json["responseData"]?["translatedText"] as String? ?? "";
      }
    } catch (_) {}
    return "";
  }
}

////////////////////////////////////////////////////////////
/// PRESET TOPIC CARD
////////////////////////////////////////////////////////////

class _PresetTopicCard extends StatelessWidget {
  final PresetTopic preset;
  final VoidCallback onTap;
  const _PresetTopicCard({required this.preset, required this.onTap});

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
              preset.color.withOpacity(0.9),
              preset.color.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: preset.color.withOpacity(0.3),
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
                  "${preset.words.length} từ",
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
                  Text(preset.emoji,
                      style: const TextStyle(fontSize: 34)),
                  const SizedBox(height: 8),
                  Text(
                    preset.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    preset.nameVi,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
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

////////////////////////////////////////////////////////////
/// TAB 2 — MY TOPICS (người dùng tự tạo)
////////////////////////////////////////////////////////////

class _MyTopicsTab extends StatelessWidget {
  final VoidCallback onAddTopic;
  const _MyTopicsTab({required this.onAddTopic});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("Vui lòng đăng nhập"));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("topics")
          .where("uid", isEqualTo: user.uid)
          .where("isPreset", isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child:
              CircularProgressIndicator(color: Color(0xFF667eea)));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _EmptyMyTopics(onAdd: onAddTopic);
        }

        final topics =
        docs.map((d) => VocabTopic.fromDoc(d)).toList();

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.05,
          ),
          itemCount: topics.length,
          itemBuilder: (context, i) => _MyTopicCard(
            topic: topics[i],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      LearnFlashcardScreen(topic: topics[i])),
            ),
            onDelete: () => _deleteTopic(context, topics[i].id),
          ),
        );
      },
    );
  }

  Future<void> _deleteTopic(
      BuildContext context, String topicId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xoá chủ đề?"),
        content: const Text(
            "Tất cả từ vựng trong chủ đề này sẽ bị xoá vĩnh viễn."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Huỷ")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Xoá",
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    final words = await FirebaseFirestore.instance
        .collection("topics")
        .doc(topicId)
        .collection("words")
        .get();
    for (var w in words.docs) {
      await w.reference.delete();
    }
    await FirebaseFirestore.instance
        .collection("topics")
        .doc(topicId)
        .delete();
  }
}

////////////////////////////////////////////////////////////
/// MY TOPIC CARD
////////////////////////////////////////////////////////////

class _MyTopicCard extends StatelessWidget {
  final VocabTopic topic;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _MyTopicCard({
    required this.topic,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              topic.color.withOpacity(0.85),
              topic.color.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: topic.color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(topic.emoji,
                      style: const TextStyle(fontSize: 34)),
                  const SizedBox(height: 8),
                  Text(
                    topic.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    topic.nameVi,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12),
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

////////////////////////////////////////////////////////////
/// EMPTY STATE
////////////////////////////////////////////////////////////

class _EmptyMyTopics extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyMyTopics({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("📚", style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          const Text(
            "Chưa có chủ đề nào",
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF444444)),
          ),
          const SizedBox(height: 8),
          const Text(
            "Nhấn + để tạo chủ đề từ vựng của riêng bạn",
            style: TextStyle(color: Colors.grey, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text("Tạo chủ đề"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// LOADING DIALOG
////////////////////////////////////////////////////////////

class _LoadingDialog extends StatelessWidget {
  const _LoadingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: const Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF667eea)),
            SizedBox(height: 20),
            Text(
              "Đang tải từ vựng...",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 6),
            Text(
              "Lần đầu mất khoảng 10-20 giây",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// ADD TOPIC SHEET (tạo chủ đề thủ công)
////////////////////////////////////////////////////////////

class _AddTopicSheet extends StatefulWidget {
  const _AddTopicSheet();

  @override
  State<_AddTopicSheet> createState() => _AddTopicSheetState();
}

class _AddTopicSheetState extends State<_AddTopicSheet> {
  final _nameEn = TextEditingController();
  final _nameVi = TextEditingController();
  String _emoji = "📚";
  Color _color  = const Color(0xFF667eea);
  bool _loading = false;

  static const _emojis = [
    "📚","🐾","🍎","🏠","✈️","💼","🎵","⚽","🌿","🔬",
    "🎨","🍜","🌍","💻","❤️","🧠","🏔️","🌊","🎓","🛒",
  ];
  static const _colors = [
    Color(0xFF667eea), Color(0xFFFF6B6B), Color(0xFF4ECDC4),
    Color(0xFFFFBE0B), Color(0xFF06D6A0), Color(0xFFFF9F1C),
    Color(0xFF8338EC), Color(0xFF3A86FF), Color(0xFFFF006E),
    Color(0xFF2EC4B6),
  ];

  Future<void> _save() async {
    if (_nameEn.text.trim().isEmpty) return;
    setState(() => _loading = true);

    final user = FirebaseAuth.instance.currentUser!;
    await FirebaseFirestore.instance.collection("topics").add({
      "uid":       user.uid,
      "name":      _nameEn.text.trim(),
      "nameVi":    _nameVi.text.trim(),
      "emoji":     _emoji,
      "color":     "#${_color.value.toRadixString(16).substring(2)}",
      "wordCount": 0,
      "isPreset":  false,
      "createdAt": FieldValue.serverTimestamp(),
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Tạo chủ đề mới",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _buildField(_nameEn, "Tên tiếng Anh *", "My Topic"),
            const SizedBox(height: 10),
            _buildField(_nameVi, "Tên tiếng Việt", "Chủ đề của tôi"),
            const SizedBox(height: 16),
            const Text("Biểu tượng",
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _emojis.map((e) {
                final sel = e == _emoji;
                return GestureDetector(
                  onTap: () => setState(() => _emoji = e),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: sel
                          ? _color.withOpacity(0.15)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: sel
                          ? Border.all(color: _color, width: 2)
                          : null,
                    ),
                    child: Center(
                        child: Text(e,
                            style: const TextStyle(fontSize: 22))),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text("Màu sắc",
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: _colors.map((c) {
                final sel = c == _color;
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: sel
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                      boxShadow: sel
                          ? [BoxShadow(
                          color: c.withOpacity(0.5),
                          blurRadius: 6)]
                          : null,
                    ),
                    child: sel
                        ? const Icon(Icons.check,
                        color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _loading
                    ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : const Text("Tạo chủ đề",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
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
          borderSide:
          const BorderSide(color: Color(0xFF667eea), width: 1.5),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameEn.dispose();
    _nameVi.dispose();
    super.dispose();
  }
}