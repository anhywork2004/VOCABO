import 'package:flutter/material.dart';
import 'package:vocabodemo/views/flashcard/flashcard_screen.dart';
import 'package:vocabodemo/views/grammar/grammar_screen.dart';

class MenuSection extends StatelessWidget {
  const MenuSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: const [
          MenuItem(
            icon: Icons.menu_book,
            title: "Words",
            iconSize: 34,
            routeType: _MenuRoute.words,
          ),
          MenuItem(
            icon: Icons.sync,
            title: "Review",
            iconSize: 34,
            routeType: _MenuRoute.review,
          ),
          MenuItem(
            icon: Icons.quiz,
            title: "Test",
            iconSize: 34,
            routeType: _MenuRoute.test,
          ),
          MenuItem(
            icon: Icons.menu_book_outlined,
            title: "Grammar",
            iconSize: 34,
            routeType: _MenuRoute.grammar,
          ),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// MENU ITEM
////////////////////////////////////////////////////////////

class MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final double iconSize;
  final _MenuRoute routeType;

  const MenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.iconSize,
    required this.routeType,
  });

  void _handleTap(BuildContext context) {
    switch (routeType) {
      case _MenuRoute.words:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FlashcardScreen()),
        );
        break;

      case _MenuRoute.grammar:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GrammarScreen()),
        );
        break;

      case _MenuRoute.review:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Review coming soon")),
        );
        break;

      case _MenuRoute.test:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Test coming soon")),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                )
              ],
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// ROUTE TYPE
////////////////////////////////////////////////////////////

enum _MenuRoute {
  words,
  review,
  test,
  grammar,
}