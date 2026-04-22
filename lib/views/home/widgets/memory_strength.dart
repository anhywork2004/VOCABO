import 'package:flutter/material.dart';

class MemoryStrength extends StatelessWidget {

  final double strength;

  const MemoryStrength({super.key, required this.strength});

  @override
  Widget build(BuildContext context) {

    double safe = strength;

    if (safe.isNaN || safe.isInfinite) {
      safe = 0;
    }

    safe = safe.clamp(0.0, 1.0);

    return Container(

      margin: const EdgeInsets.symmetric(horizontal: 20),

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff6EC6FF), Color(0xff1E88E5)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          const Text(
            "Memory Strength",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          LinearProgressIndicator(
            value: safe,
            minHeight: 10,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),

          const SizedBox(height: 8),

          Text(
            "${(safe * 100).toInt()}%",
            style: const TextStyle(color: Colors.white),
          )
        ],
      ),
    );
  }
}