import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DailyStreakCard extends StatelessWidget {
  const DailyStreakCard({super.key});

  @override
  Widget build(BuildContext context) {

    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .snapshots(),

      builder: (context, snapshot) {

        if(!snapshot.hasData){
          return const SizedBox();
        }

        final data = snapshot.data!.data() as Map<String,dynamic>? ?? {};
        int streak = data["streak"] ?? 0;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),

          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xffFF7043), Color(0xffFF5722)],
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 8)
            ],
          ),

          child: Row(
            children: [

              const Icon(
                Icons.local_fire_department,
                color: Colors.white,
                size: 40,
              ),

              const SizedBox(width: 15),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Daily Streak",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),

                  Text(
                    "$streak ngày liên tiếp",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                ],
              )
            ],
          ),
        );
      },
    );
  }
}