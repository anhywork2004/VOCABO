  import 'package:flutter/material.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'learn_grammar_screen.dart';


  ////////////////////////////////////////////////////////////
  /// MODEL
  ////////////////////////////////////////////////////////////

  class GrammarPreset {
    final String title;
    final String titleVi;
    final String emoji;
    final Color color;
    final String content;
    final String category;

    const GrammarPreset({
      required this.title,
      required this.titleVi,
      required this.emoji,
      required this.color,
      required this.content,
      required this.category,
    });
  }

  ////////////////////////////////////////////////////////////
  /// TENSES (12)
  ////////////////////////////////////////////////////////////

  final List<GrammarPreset> kTensePresets = [
    GrammarPreset(
      category: "Tenses",
      title: "Present Simple",
      titleVi: "Hiện tại đơn",
      emoji: "📘",
      color: const Color(0xFF667eea),
      content: "S + V(s/es)\nUse: habits, facts",
    ),
    GrammarPreset(
      category: "Tenses",
      title: "Present Continuous",
      titleVi: "HT tiếp diễn",
      emoji: "⏳",
      color: const Color(0xFF4ECDC4),
      content: "S + am/is/are + V-ing\nUse: happening now",
    ),
    GrammarPreset(
      category: "Tenses",
      title: "Present Perfect",
      titleVi: "HT hoàn thành",
      emoji: "✅",
      color: const Color(0xFF06D6A0),
      content: "S + have/has + V3\nUse: experience/result",
    ),
    GrammarPreset(
      category: "Tenses",
      title: "Present Perfect Continuous",
      titleVi: "HTHT tiếp diễn",
      emoji: "🔄",
      color: const Color(0xFF1DB954),
      content: "S + have/has been + V-ing",
    ),
    GrammarPreset(
      category: "Tenses",
      title: "Past Simple",
      titleVi: "Quá khứ đơn",
      emoji: "📕",
      color: const Color(0xFFFF6B6B),
      content: "S + V2/ed",
    ),
    GrammarPreset(
      category: "Tenses",
      title: "Past Continuous",
      titleVi: "QK tiếp diễn",
      emoji: "🎞️",
      color: const Color(0xFFE63946),
      content: "S + was/were + V-ing",
    ),
    GrammarPreset(
      category: "Tenses",
      title: "Past Perfect",
      titleVi: "QK hoàn thành",
      emoji: "⏮️",
      color: const Color(0xFFC77DFF),
      content: "S + had + V3",
    ),
    GrammarPreset(
      category: "Tenses",
      title: "Past Perfect Continuous",
      titleVi: "QKHT tiếp diễn",
      emoji: "⏪",
      color: const Color(0xFF9B5DE5),
      content: "S + had been + V-ing",
    ),
    GrammarPreset(
      category: "Tenses",
      title: "Future Simple",
      titleVi: "Tương lai đơn",
      emoji: "🔮",
      color: const Color(0xFFFFBE0B),
      content: "S + will + V",
    ),
    GrammarPreset(
      category: "Tenses",
      title: "Future Continuous",
      titleVi: "TL tiếp diễn",
      emoji: "🚀",
      color: const Color(0xFFFF9F1C),
      content: "S + will be + V-ing",
    ),
    GrammarPreset(
      category: "Tenses",
      title: "Future Perfect",
      titleVi: "TL hoàn thành",
      emoji: "🏁",
      color: const Color(0xFFEF476F),
      content: "S + will have + V3",
    ),
    GrammarPreset(
      category: "Tenses",
      title: "Future Perfect Continuous",
      titleVi: "TLHT tiếp diễn",
      emoji: "⚡",
      color: const Color(0xFFFF6B35),
      content: "S + will have been + V-ing",
    ),
  ];

  ////////////////////////////////////////////////////////////
  /// CONDITIONALS
  ////////////////////////////////////////////////////////////

  final List<GrammarPreset> kConditionalPresets = [
    GrammarPreset(
      category: "Conditionals",
      title: "Zero Conditional",
      titleVi: "Loại 0",
      emoji: "🌡️",
      color: const Color(0xFF2EC4B6),
      content: "If + V, V (fact)",
    ),
    GrammarPreset(
      category: "Conditionals",
      title: "First Conditional",
      titleVi: "Loại 1",
      emoji: "✨",
      color: const Color(0xFF3D9970),
      content: "If + present, will + V",
    ),
    GrammarPreset(
      category: "Conditionals",
      title: "Second Conditional",
      titleVi: "Loại 2",
      emoji: "🌙",
      color: const Color(0xFF6A4C93),
      content: "If + V2, would + V",
    ),
    GrammarPreset(
      category: "Conditionals",
      title: "Third Conditional",
      titleVi: "Loại 3",
      emoji: "💭",
      color: const Color(0xFF1D3557),
      content: "If + had + V3, would have + V3",
    ),
  ];

  ////////////////////////////////////////////////////////////
  /// OTHER GRAMMAR
  ////////////////////////////////////////////////////////////

  final List<GrammarPreset> kOtherPresets = [
    GrammarPreset(
      category: "Other",
      title: "Modal Verbs",
      titleVi: "Động từ khuyết thiếu",
      emoji: "🎛️",
      color: const Color(0xFF457B9D),
      content: "can, could, must, should",
    ),
    GrammarPreset(
      category: "Other",
      title: "Passive Voice",
      titleVi: "Bị động",
      emoji: "🔁",
      color: const Color(0xFF118AB2),
      content: "be + V3",
    ),
    GrammarPreset(
      category: "Other",
      title: "Reported Speech",
      titleVi: "Tường thuật",
      emoji: "🗣️",
      color: const Color(0xFFE76F51),
      content: "He said that...",
    ),
    GrammarPreset(
      category: "Other",
      title: "Relative Clauses",
      titleVi: "Mệnh đề quan hệ",
      emoji: "🔗",
      color: const Color(0xFF2A9D8F),
      content: "who, which, that",
    ),
    GrammarPreset(
      category: "Other",
      title: "Gerund & Infinitive",
      titleVi: "V-ing & to V",
      emoji: "⚖️",
      color: const Color(0xFFF4A261),
      content: "enjoy doing / want to do",
    ),
    GrammarPreset(
      category: "Other",
      title: "Comparison",
      titleVi: "So sánh",
      emoji: "📊",
      color: const Color(0xFF8338EC),
      content: "bigger / more / most",
    ),
    GrammarPreset(
      category: "Other",
      title: "Articles",
      titleVi: "Mạo từ",
      emoji: "🔤",
      color: const Color(0xFF5C4033),
      content: "a / an / the",
    ),
    GrammarPreset(
      category: "Other",
      title: "Conjunctions",
      titleVi: "Liên từ",
      emoji: "🔧",
      color: const Color(0xFF6D6875),
      content: "and, but, because",
    ),
    GrammarPreset(
      category: "Other",
      title: "Prepositions",
      titleVi: "Giới từ",
      emoji: "📍",
      color: const Color(0xFF219EBC),
      content: "in, on, at",
    ),
    GrammarPreset(
      category: "Other",
      title: "Question Tags",
      titleVi: "Câu hỏi đuôi",
      emoji: "❓",
      color: const Color(0xFF780000),
      content: "isn't it?",
    ),
  ];

  ////////////////////////////////////////////////////////////
  /// SCREEN
  ////////////////////////////////////////////////////////////

  class GrammarScreen extends StatefulWidget {
    const GrammarScreen({super.key});

    @override
    State<GrammarScreen> createState() => _GrammarScreenState();
  }

  class _GrammarScreenState extends State<GrammarScreen>
      with SingleTickerProviderStateMixin {
    late TabController _tabController;

    final tabs = const [
      _TabInfo("Tenses", "🕐"),
      _TabInfo("Conditionals", "💡"),
      _TabInfo("Other", "📚"),
    ];

    @override
    void initState() {
      super.initState();
      _tabController = TabController(length: tabs.length, vsync: this);
    }

    List<GrammarPreset> _get(String c) {
      switch (c) {
        case "Tenses":
          return kTensePresets;
        case "Conditionals":
          return kConditionalPresets;
        default:
          return kOtherPresets;
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          title: const Text("Grammar"),
          backgroundColor: const Color(0xFF667eea),
          bottom: TabBar(
            controller: _tabController,
            tabs: tabs.map((t) => Tab(text: "${t.icon} ${t.label}")).toList(),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: tabs.map((t) {
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _get(t.label).length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemBuilder: (_, i) {
                final g = _get(t.label)[i];

                return GestureDetector(
                  onTap: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) return;

                    final topic = GrammarTopic(
                      id: g.title,
                      title: g.title,
                      titleVi: g.titleVi,
                      emoji: g.emoji,
                      color: g.color,
                      content: g.content,
                      category: g.category,
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LearnGrammarScreen(topic: topic),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [g.color, g.color.withOpacity(0.6)],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(g.emoji, style: const TextStyle(fontSize: 30)),
                          const SizedBox(height: 10),
                          Text(
                            g.title,
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            g.titleVi,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
      );
    }
  }

  ////////////////////////////////////////////////////////////
  /// TAB MODEL
  ////////////////////////////////////////////////////////////

  class _TabInfo {
    final String label;
    final String icon;
    const _TabInfo(this.label, this.icon);
  }

  ////////////////////////////////////////////////////////////
  /// TOPIC MODEL
  ////////////////////////////////////////////////////////////

  class GrammarTopic {
    final String id;
    final String title;
    final String titleVi;
    final String emoji;
    final Color color;
    final String content;
    final String category;

    GrammarTopic({
      required this.id,
      required this.title,
      required this.titleVi,
      required this.emoji,
      required this.color,
      required this.content,
      required this.category,
    });
  }