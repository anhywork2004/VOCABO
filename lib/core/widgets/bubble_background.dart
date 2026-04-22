import 'package:flutter/material.dart';

class BubbleBackground extends StatelessWidget {
  final Widget child;

  const BubbleBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [

        Container(color: Colors.white),

        Positioned(
          top: -40,
          left: -40,
          child: circle(150, Colors.blue.shade100),
        ),

        Positioned(
          bottom: -60,
          right: -20,
          child: circle(200, Colors.blue.shade200),
        ),

        Positioned(
          top: 200,
          right: -50,
          child: circle(120, Colors.blue.shade100),
        ),

        child
      ],
    );
  }

  Widget circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle
      ),
    );
  }
}