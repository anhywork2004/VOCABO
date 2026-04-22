import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'user_info_screen.dart';
import '../home/home_screen.dart';
import '../admin/admin_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<Widget> _resolveScreen(User user) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      // ❌ chưa có user data → tạo document cơ bản rồi vào onboarding
      if (!doc.exists) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .set({
          "email": user.email ?? '',
          "displayName": user.displayName ?? '',
          "photoUrl": user.photoURL ?? '',
          "role": "user",
          "isNewUser": true,
          "createdAt": FieldValue.serverTimestamp(),
        });
        return const UserInfoScreen();
      }

      final data = doc.data();

      // 🔑 Admin → AdminScreen
      if (data?['role'] == 'admin') {
        return const AdminScreen();
      }

      // ❌ chưa hoàn tất onboarding
      final isNewUser = data?["isNewUser"] ?? false;

      if (isNewUser == true) {
        return const UserInfoScreen();
      }

      // ✅ đã setup xong → HOME
      return const HomeScreen();
    } catch (e) {
      return const LoginScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ❌ chưa login
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        final user = snapshot.data!;

        return FutureBuilder<Widget>(
          future: _resolveScreen(user),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            return snap.data!;
          },
        );
      },
    );
  }
}