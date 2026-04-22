import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  State<AdminNotificationScreen> createState() =>
      _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _target = 'all';
  String _type = 'info';
  bool _loading = false;

  static const _targets = {
    'all': 'Tất cả người dùng',
    'A1': 'Cấp độ A1',
    'A2': 'Cấp độ A2',
    'B1': 'Cấp độ B1',
    'B2': 'Cấp độ B2',
    'C1': 'Cấp độ C1',
    'C2': 'Cấp độ C2',
  };

  static const _types = {
    'info': ('📢 Thông báo', Colors.blue),
    'success': ('🎉 Chúc mừng', Colors.green),
    'warning': ('⚠️ Cảnh báo', Colors.orange),
    'error': ('🚨 Khẩn cấp', Colors.red),
  };

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ tiêu đề và nội dung')),
      );
      return;
    }

    setState(() => _loading = true);

    await FirebaseFirestore.instance.collection('notifications').add({
      'title': title,
      'body': body,
      'target': _target,
      'type': _type,
      'createdAt': FieldValue.serverTimestamp(),
      'sentBy': FirebaseAuth.instance.currentUser?.uid,
    });

    setState(() {
      _loading = false;
      _titleCtrl.clear();
      _bodyCtrl.clear();
      _target = 'all';
      _type = 'info';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã gửi thông báo'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 700;
      if (wide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildForm()),
            const SizedBox(width: 16),
            Expanded(child: _buildHistory()),
          ],
        );
      }
      return SingleChildScrollView(
        child: Column(
          children: [
            _buildForm(),
            const SizedBox(height: 16),
            SizedBox(height: 400, child: _buildHistory()),
          ],
        ),
      );
    });
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gửi thông báo mới',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Title
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(
              labelText: 'Tiêu đề *',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 12),

          // Body
          TextField(
            controller: _bodyCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Nội dung *',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.message_outlined),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),

          // Target
          DropdownButtonFormField<String>(
            value: _target,
            decoration: InputDecoration(
              labelText: 'Đối tượng nhận',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.people_outline),
            ),
            items: _targets.entries
                .map((e) =>
                    DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) => setState(() => _target = v!),
          ),
          const SizedBox(height: 12),

          // Type
          const Text('Loại thông báo',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _types.entries.map((e) {
              final selected = _type == e.key;
              return ChoiceChip(
                label: Text(e.value.$1),
                selected: selected,
                selectedColor: e.value.$2.withOpacity(0.2),
                onSelected: (_) => setState(() => _type = e.key),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Preview
          if (_titleCtrl.text.isNotEmpty || _bodyCtrl.text.isNotEmpty)
            _NotifPreview(
              title: _titleCtrl.text,
              body: _bodyCtrl.text,
              type: _type,
              target: _targets[_target] ?? '',
            ),

          const SizedBox(height: 16),

          // Send button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(_loading ? 'Đang gửi...' : 'Gửi thông báo'),
              onPressed: _loading ? null : _send,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Lịch sử thông báo',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              // Delete all button
              TextButton.icon(
                icon: const Icon(Icons.delete_sweep, color: Colors.red),
                label: const Text('Xóa tất cả',
                    style: TextStyle(color: Colors.red)),
                onPressed: _confirmDeleteAll,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                      child: Text('Chưa có thông báo nào'));
                }
                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final d =
                        docs[i].data() as Map<String, dynamic>;
                    return _NotifHistoryTile(
                      data: d,
                      onDelete: () => docs[i].reference.delete(),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAll() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa tất cả thông báo?'),
        content: const Text('Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final snap = await FirebaseFirestore.instance
                  .collection('notifications')
                  .get();
              final batch = FirebaseFirestore.instance.batch();
              for (final doc in snap.docs) {
                batch.delete(doc.reference);
              }
              await batch.commit();
            },
            child: const Text('Xóa tất cả',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Notification preview ──────────────────────────────────────────────────────
class _NotifPreview extends StatelessWidget {
  const _NotifPreview({
    required this.title,
    required this.body,
    required this.type,
    required this.target,
  });

  final String title;
  final String body;
  final String type;
  final String target;

  static const _typeColors = {
    'info': Colors.blue,
    'success': Colors.green,
    'warning': Colors.orange,
    'error': Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    final color = _typeColors[type] ?? Colors.blue;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.preview, size: 14, color: color),
              const SizedBox(width: 4),
              Text('Xem trước',
                  style: TextStyle(
                      fontSize: 11, color: color, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('→ $target',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 8),
          if (title.isNotEmpty)
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          if (body.isNotEmpty)
            Text(body,
                style: TextStyle(color: Colors.grey[700], fontSize: 13)),
        ],
      ),
    );
  }
}

// ── Notification history tile ─────────────────────────────────────────────────
class _NotifHistoryTile extends StatelessWidget {
  const _NotifHistoryTile({required this.data, required this.onDelete});
  final Map<String, dynamic> data;
  final VoidCallback onDelete;

  static const _typeIcons = {
    'info': (Icons.info_outline, Colors.blue),
    'success': (Icons.check_circle_outline, Colors.green),
    'warning': (Icons.warning_amber_outlined, Colors.orange),
    'error': (Icons.error_outline, Colors.red),
  };

  @override
  Widget build(BuildContext context) {
    final type = data['type'] ?? 'info';
    final iconData = _typeIcons[type] ?? (Icons.notifications_outlined, Colors.blue);
    final createdAt = data['createdAt'];
    String dateStr = '';
    if (createdAt is Timestamp) {
      dateStr = DateFormat('dd/MM HH:mm').format(createdAt.toDate());
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconData.$2.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(iconData.$1, color: iconData.$2, size: 20),
        ),
        title: Text(data['title'] ?? '',
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['body'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.people_outline, size: 12, color: Colors.grey),
                const SizedBox(width: 2),
                Text(data['target'] ?? 'all',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
                const Spacer(),
                Text(dateStr,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
