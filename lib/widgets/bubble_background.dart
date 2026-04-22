import 'package:flutter/material.dart';

class BubbleBackground extends StatelessWidget {
  const BubbleBackground({super.key});

  @override
  Widget build(BuildContext context) {

    return Stack(
      children: [

        Container(color: Colors.white),

        bubble(50,100,80,Colors.blue.shade200),
        bubble(200,50,120,Colors.blue.shade100),
        bubble(-40,250,200,Colors.blue.shade600),
        bubble(220,350,180,Colors.blue.shade300),
        bubble(80,500,150,Colors.blue.shade200),
        bubble(140,650,50,Colors.blue.shade500),
      ],
    );
  }

  Widget bubble(double left,double top,double size,Color color){

    return Positioned(
      left: left,
      top: top,

      child: Container(
        width: size,
        height: size,

        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,

          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: color.withValues(alpha:0.3),
            )
          ],
        ),
      ),
    );
  }
}