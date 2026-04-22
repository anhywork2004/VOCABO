import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:vocabodemo/views/home/widgets/weekly_chart.dart';

class WeeklyChartFirestore extends StatelessWidget {
  const WeeklyChartFirestore({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("study_sessions")
          .where("uid", isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final List<int> weeklyData = List.filled(7, 0);

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;

            final date = (data["date"] as Timestamp).toDate();
            final words = (data["wordsLearned"] as num? ?? 0).toInt();

            weeklyData[date.weekday - 1] += words;
          }
        }

        return SizedBox(
          height: 180,
          child: WeeklyChart(data: weeklyData),
        );
      },
    );
  }
}