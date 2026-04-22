import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;

  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  /// Gọi khi app khởi động — load từ Firestore
  Future<void> loadFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      _isDark = doc.data()?["darkMode"] ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint("ThemeProvider load error: $e");
    }
  }

  /// Gọi khi user toggle switch
  Future<void> setDark(bool value) async {
    _isDark = value;
    notifyListeners();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .set({"darkMode": value}, SetOptions(merge: true));
  }
}