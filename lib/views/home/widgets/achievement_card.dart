import 'package:flutter/material.dart';

class AchievementCard extends StatelessWidget {
  final int streak;
  final int words;
  final double progress;

  const AchievementCard({
    super.key,
    required this.streak,
    required this.words,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Thành tích",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              /// STREAK
              Column(
                children: [
                  const Icon(Icons.emoji_events,
                      color: Colors.orange, size: 40),
                  const SizedBox(height: 6),
                  Text(
                    "$streak",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  Text("Streak",
                      style: TextStyle(color: cs.onSurface.withOpacity(0.6))),
                ],
              ),
              /// WORDS
              Column(
                children: [
                  const Icon(Icons.bookmark,
                      color: Colors.blue, size: 40),
                  const SizedBox(height: 6),
                  Text(
                    "$words",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  Text("Số từ đã nhớ",
                      style: TextStyle(color: cs.onSurface.withOpacity(0.6))),
                ],
              ),
              /// PROGRESS CIRCLE
              Column(
                children: [
                  SizedBox(
                    height: 60,
                    width: 60,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 6,
                          backgroundColor: cs.onSurface.withOpacity(0.1),
                          valueColor:
                              const AlwaysStoppedAnimation(Colors.blue),
                        ),
                        Text(
                          "${(progress * 100).toInt()}%",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text("Tiến bộ",
                      style: TextStyle(color: cs.onSurface.withOpacity(0.6))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}