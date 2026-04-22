import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AddEventScreen extends StatefulWidget {
  final DateTime? selectedDate;

  const AddEventScreen({super.key, this.selectedDate});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  static const primary = Color(0xFF1E88E5);

  @override
  void initState() {
    super.initState();
    if (widget.selectedDate != null) {
      _selectedDate = widget.selectedDate!;
    }
  }

  Future<void> _saveEvent() async {
    if (_titleController.text.trim().isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('events').add({
      'uid': uid,                                    // ✅ filter theo user
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'date': Timestamp.fromDate(_selectedDate),
      'time': _selectedTime.format(context),
      'createdAt': FieldValue.serverTimestamp(),
      'completed': false,
    });

    if (mounted) Navigator.pop(context, true);
  }

  String? _getCurrentUid() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      appBar: AppBar(
        title: const Text('➕ Thêm sự kiện'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.calendar_month, color: primary),
                title: const Text("Ngày"),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                onTap: _pickDate,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.access_time, color: primary),
                title: const Text("Giờ"),
                subtitle: Text(_selectedTime.format(context)),
                onTap: _pickTime,
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: "Tiêu đề",
                labelStyle: const TextStyle(color: primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Mô tả",
                labelStyle: const TextStyle(color: primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 25),

            ElevatedButton.icon(
              onPressed: _saveEvent,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text("Lưu sự kiện",
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}