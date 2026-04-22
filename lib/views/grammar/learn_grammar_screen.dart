import 'package:flutter/material.dart';

import 'grammar_screen.dart';
// ⬆️ sửa lại path nếu file GrammarTopic nằm chỗ khác

class LearnGrammarScreen extends StatelessWidget {
  final GrammarTopic topic;

  const LearnGrammarScreen({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: topic.color,
        title: Text("${topic.emoji} ${topic.title}"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //////////////////////////////////////////////////////
            /// TITLE CARD
            //////////////////////////////////////////////////////
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [topic.color, topic.color.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.emoji,
                    style: const TextStyle(fontSize: 40),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    topic.title,
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    topic.titleVi,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            //////////////////////////////////////////////////////
            /// STRUCTURE CARD
            //////////////////////////////////////////////////////
            _SectionCard(
              title: "Cấu trúc",
              color: topic.color,
              child: Text(
                topic.content,
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 16),

            //////////////////////////////////////////////////////
            /// EXPLANATION (placeholder nâng cấp sau)
            //////////////////////////////////////////////////////
            _SectionCard(
              title: "Giải thích",
              color: topic.color,
              child: Text(
                _getExplanation(topic.title),
                style: const TextStyle(fontSize: 15, height: 1.6),
              ),
            ),

            const SizedBox(height: 16),

            //////////////////////////////////////////////////////
            /// EXAMPLES
            //////////////////////////////////////////////////////
            _SectionCard(
              title: "Ví dụ",
              color: topic.color,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _getExamples(topic.title)
                    .map(
                      (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      "• $e",
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ),
                )
                    .toList(),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  //////////////////////////////////////////////////////
  /// EXPLANATION DATA
  //////////////////////////////////////////////////////
  String _getExplanation(String title) {
    switch (title) {
      case "Present Simple":
        return "Dùng để diễn tả thói quen, sự thật hiển nhiên hoặc lịch trình cố định.";
      case "Past Simple":
        return "Dùng để diễn tả hành động đã xảy ra và kết thúc trong quá khứ.";
      case "Future Simple":
        return "Dùng để diễn tả dự đoán hoặc quyết định trong tương lai.";
      case "Present Continuous":
        return "Dùng cho hành động đang xảy ra tại thời điểm nói.";
      default:
        return "Ngữ pháp này được sử dụng trong nhiều tình huống giao tiếp tiếng Anh.";
    }
  }

  //////////////////////////////////////////////////////
  /// EXAMPLES DATA
  //////////////////////////////////////////////////////
  List<String> _getExamples(String title) {
    switch (title) {
      case "Present Simple":
        return [
          "I go to school every day.",
          "She likes coffee.",
          "The sun rises in the east."
        ];
      case "Past Simple":
        return [
          "I went to school yesterday.",
          "She watched a movie last night.",
          "They played football."
        ];
      case "Future Simple":
        return [
          "I will go to school tomorrow.",
          "She will travel next week.",
          "They will study harder."
        ];
      default:
        return [
          "This is an example sentence.",
          "You can add more examples in Firebase.",
        ];
    }
  }
}

////////////////////////////////////////////////////////////
/// SECTION CARD WIDGET
////////////////////////////////////////////////////////////

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Color color;

  const _SectionCard({
    required this.title,
    required this.child,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}