import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../home/home_screen.dart';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final _nameCtrl = TextEditingController();

  File? _image;
  String _level = "A1";
  int _dailyGoal = 10;
  int _step = 0;
  bool _loading = false;

  static const _levels = ["A1", "A2", "B1", "B2", "C1", "C2"];

  static const _levelDesc = {
    "A1": "Mới bắt đầu — biết rất ít từ vựng",
    "A2": "Sơ cấp — giao tiếp đơn giản",
    "B1": "Trung cấp — hiểu nội dung quen thuộc",
    "B2": "Trên trung cấp — giao tiếp tự nhiên",
    "C1": "Nâng cao — sử dụng thành thạo",
    "C2": "Thành thạo — gần như người bản ngữ",
  };

  static const _goals = [5, 10, 15, 20, 30];

  static const _goalDesc = {
    5: "Nhẹ nhàng · ~5 phút/ngày",
    10: "Bình thường · ~10 phút/ngày",
    15: "Tích cực · ~15 phút/ngày",
    20: "Chuyên sâu · ~20 phút/ngày",
    30: "Cường độ cao · ~30 phút/ngày",
  };

  @override
  void initState() {
    super.initState();
    final displayName = FirebaseAuth.instance.currentUser?.displayName ?? "";
    if (displayName.isNotEmpty) {
      _nameCtrl.text = displayName;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showSnack("Vui lòng nhập tên hiển thị");
      setState(() => _step = 0);
      return;
    }

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      String photoUrl = user.photoURL ?? "";

      if (_image != null) {
        final ref =
        FirebaseStorage.instance.ref().child("avatars/${user.uid}.jpg");

        await ref.putFile(_image!);
        photoUrl = await ref.getDownloadURL();
        await user.updatePhotoURL(photoUrl);
      }

      await user.updateDisplayName(name);

      await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
        "displayName": name,
        "photoUrl": photoUrl,
        "level": _level,
        "dailyGoal": _dailyGoal,
        "streak": 0,
        "wordsLearned": 0,
        "progress": 0.0,
        "createdAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on FirebaseException catch (e) {
      if (e.code == "object-not-found") {
        _showSnack("Ảnh đại diện không tồn tại trên Firebase Storage");
      } else {
        _showSnack("Lỗi Firebase: ${e.message ?? e.code}");
      }
    } catch (e) {
      _showSnack("Lỗi: $e");
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  void _next() {
    if (_step == 0 && _nameCtrl.text.trim().isEmpty) {
      _showSnack("Vui lòng nhập tên hiển thị");
      return;
    }

    if (_step < 2) {
      setState(() => _step++);
    } else {
      _save();
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    }
  }

  bool _isValidPhotoUrl(String url) {
    return url.startsWith("http://") || url.startsWith("https://");
  }

  Widget _buildAvatar() {
    if (_image != null) {
      return ClipOval(
        child: Image.file(
          _image!,
          fit: BoxFit.cover,
          width: 110,
          height: 110,
        ),
      );
    }

    final photoUrl = FirebaseAuth.instance.currentUser?.photoURL ?? "";

    if (_isValidPhotoUrl(photoUrl)) {
      return ClipOval(
        child: Image.network(
          photoUrl,
          fit: BoxFit.cover,
          width: 110,
          height: 110,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.person,
              size: 52,
              color: Colors.white,
            );
          },
        ),
      );
    }

    return const Icon(
      Icons.person,
      size: 52,
      color: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Stack(
        children: [
          Container(
            height: 260,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    children: [
                      _StepIndicator(current: _step, total: 3),
                      const SizedBox(height: 20),
                      Text(
                        _stepTitle(_step),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _stepSubtitle(_step),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) => SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.15, 0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: anim,
                              curve: Curves.easeOut,
                            ),
                          ),
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                        child: KeyedSubtree(
                          key: ValueKey(_step),
                          child: _buildStep(_step),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Row(
                    children: [
                      if (_step > 0)
                        GestureDetector(
                          onTap: _back,
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      if (_step > 0) const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _next,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF667eea),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: _loading
                                ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                                : Text(
                              _step < 2
                                  ? "Tiếp theo →"
                                  : "Bắt đầu học!",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int step) {
    switch (step) {
      case 0:
        return _buildStep0();
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep0() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667eea).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _buildAvatar(),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: Color(0xFF667eea),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Nhấn để chọn ảnh",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              labelText: "Tên hiển thị *",
              hintText: "Nhập tên của bạn",
              prefixIcon: const Icon(
                Icons.person_outline,
                color: Color(0xFF667eea),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF667eea),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: _levels.map((lvl) {
          final selected = lvl == _level;
          return GestureDetector(
            onTap: () => setState(() => _level = lvl),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF667eea).withOpacity(0.08)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF667eea)
                      : Colors.grey.shade200,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF667eea)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        lvl,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.grey.shade600,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _levelDesc[lvl] ?? "",
                      style: TextStyle(
                        fontSize: 14,
                        color: selected
                            ? const Color(0xFF667eea)
                            : Colors.grey.shade700,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF667eea),
                      size: 22,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 20,
              horizontal: 24,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("🎯 ", style: TextStyle(fontSize: 28)),
                Text(
                  "$_dailyGoal từ/ngày",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ..._goals.map((g) {
            final selected = g == _dailyGoal;
            return GestureDetector(
              onTap: () => setState(() => _dailyGoal = g),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF667eea).withOpacity(0.08)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF667eea)
                        : Colors.grey.shade200,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF667eea)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          "$g",
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.grey.shade600,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _goalDesc[g] ?? "",
                        style: TextStyle(
                          fontSize: 14,
                          color: selected
                              ? const Color(0xFF667eea)
                              : Colors.grey.shade700,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (selected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF667eea),
                        size: 22,
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _stepTitle(int step) {
    switch (step) {
      case 0:
        return "Xin chào! 👋\nBạn tên là gì?";
      case 1:
        return "Trình độ tiếng Anh\ncủa bạn?";
      case 2:
        return "Mục tiêu học\nmỗi ngày?";
      default:
        return "";
    }
  }

  String _stepSubtitle(int step) {
    switch (step) {
      case 0:
        return "Thêm ảnh và tên để cá nhân hoá trải nghiệm";
      case 1:
        return "Chúng tôi sẽ gợi ý từ vựng phù hợp với bạn";
      case 2:
        return "Bạn có thể thay đổi bất cứ lúc nào trong cài đặt";
      default:
        return "";
    }
  }
}

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;

  const _StepIndicator({
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i == current;
        final done = i < current;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: done || active
                ? Colors.white
                : Colors.white.withOpacity(0.35),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
