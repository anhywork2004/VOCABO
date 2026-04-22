import 'package:flutter/material.dart';
import 'package:vocabodemo/AI/ai_planner_screen.dart';

class AIChatBubble extends StatefulWidget {
  const AIChatBubble({super.key});

  @override
  State<AIChatBubble> createState() => _AIChatBubbleState();
}

class _AIChatBubbleState extends State<AIChatBubble> {
  double top = 500;
  double left = 300;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            left += details.delta.dx;
            top += details.delta.dy;
          });
        },
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AIPlannerScreen(),
            ),
          );
        },
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Colors.purple, Colors.pink],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 3,
              )
            ],
          ),
          child: const Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 28,
              ),
              Positioned(
                bottom: -5,
                right: -5,
                child: Icon(
                  Icons.pets,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}