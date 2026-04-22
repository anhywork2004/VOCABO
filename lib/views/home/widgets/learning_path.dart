import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vocabodemo/views/flashcard/flashcard_screen.dart';

class LearningPath extends StatelessWidget {
  const LearningPath({super.key});

  static const _levels = ["A1", "A2", "B1", "B2", "C1", "C2"];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: user == null
          ? const Stream.empty()
          : FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
      builder: (context, snapshot) {
        final data =
            snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final currentLevel = (data['level'] ?? 'A1').toString();
        final dailyGoal   = (data['dailyGoal'] ?? 10).toInt();
        final wordsLearned = (data['wordsLearned'] ?? 0).toInt();

        // Tiến độ hôm nay so với mục tiêu
        final todayProgress =
            (wordsLearned % dailyGoal.clamp(1, 999)) / dailyGoal.clamp(1, 999);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Lộ trình học",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const FlashcardScreen()),
                    ),
                    child: const Text(
                      "Tiếp tục học →",
                      style: TextStyle(
                        color: Color(0xFF667eea),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Level badges ────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _levels.map((lvl) {
                  final isActive = lvl == currentLevel;
                  final isDone   = _levelIndex(lvl) < _levelIndex(currentLevel);

                  return _LevelBadge(
                    text:     lvl,
                    isActive: isActive,
                    isDone:   isDone,
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // ── Mục tiêu hôm nay ────────────────────────────
              Row(
                children: [
                  const Icon(Icons.flag_rounded,
                      size: 16, color: Color(0xFF667eea)),
                  const SizedBox(width: 6),
                  Text(
                    "Mục tiêu hôm nay: $dailyGoal từ",
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ── Progress bar ────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: todayProgress.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF667eea)),
                ),
              ),

              const SizedBox(height: 6),

              Text(
                "${(todayProgress * dailyGoal).toInt()} / $dailyGoal từ hôm nay",
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  int _levelIndex(String level) {
    return _levels.indexOf(level).clamp(0, _levels.length - 1);
  }
}

class _LevelBadge extends StatelessWidget {
  final String text;
  final bool isActive;
  final bool isDone;

  const _LevelBadge({
    required this.text,
    required this.isActive,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    if (isActive) {
      bgColor   = const Color(0xFF667eea);
      textColor = Colors.white;
    } else if (isDone) {
      bgColor   = const Color(0xFF06D6A0);
      textColor = Colors.white;
    } else {
      bgColor   = Theme.of(context).colorScheme.onSurface.withOpacity(0.12);
      textColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
    }

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF667eea).withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (isActive) ...[
          const SizedBox(height: 4),
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF667eea),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }
}
