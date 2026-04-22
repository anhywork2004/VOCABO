import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ManageUserScreen extends StatefulWidget {
  const ManageUserScreen({super.key});

  @override
  State<ManageUserScreen> createState() => _ManageUserScreenState();
}

class _ManageUserScreenState extends State<ManageUserScreen> {
  String _search = '';
  String _filterLevel = 'Tất cả';

  static const _levels = ['Tất cả', 'A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Toolbar ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              // Search
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên hoặc email...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _search = v.toLowerCase()),
                ),
              ),
              const SizedBox(width: 12),
              // Level filter
              DropdownButton<String>(
                value: _filterLevel,
                borderRadius: BorderRadius.circular(12),
                items: _levels
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (v) => setState(() => _filterLevel = v!),
              ),
            ],
          ),
        ),

        // ── List ───────────────────────────────────────────────────────────
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var docs = snap.data!.docs;

              // Filter
              docs = docs.where((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final name =
                    (d['displayName'] ?? d['name'] ?? '').toString().toLowerCase();
                final email = (d['email'] ?? '').toString().toLowerCase();
                final level = (d['level'] ?? 'A1').toString();

                final matchSearch =
                    _search.isEmpty || name.contains(_search) || email.contains(_search);
                final matchLevel =
                    _filterLevel == 'Tất cả' || level == _filterLevel;

                return matchSearch && matchLevel;
              }).toList();

              if (docs.isEmpty) {
                return const Center(child: Text('Không tìm thấy người dùng'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final doc = docs[i];
                  final d = doc.data() as Map<String, dynamic>;
                  return _UserTile(
                    docId: doc.id,
                    data: d,
                    onDelete: () => _confirmDelete(doc.id, d),
                    onViewDetail: () => _showUserDetail(doc.id, d),
                    onToggleBan: () => _toggleBan(doc.id, d),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _confirmDelete(String docId, Map<String, dynamic> d) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa người dùng?'),
        content: Text(
            'Bạn có chắc muốn xóa "${d['displayName'] ?? d['name'] ?? d['email']}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(docId)
                  .delete();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa người dùng')),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBan(String docId, Map<String, dynamic> d) async {
    final isBanned = d['banned'] == true;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(docId)
        .update({'banned': !isBanned});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(isBanned ? 'Đã mở khóa tài khoản' : 'Đã khóa tài khoản')),
      );
    }
  }

  void _showUserDetail(String docId, Map<String, dynamic> d) {
    showDialog(
      context: context,
      builder: (_) => _UserDetailDialog(docId: docId, data: d),
    );
  }
}

// ── User tile ─────────────────────────────────────────────────────────────────
class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.docId,
    required this.data,
    required this.onDelete,
    required this.onViewDetail,
    required this.onToggleBan,
  });

  final String docId;
  final Map<String, dynamic> data;
  final VoidCallback onDelete;
  final VoidCallback onViewDetail;
  final VoidCallback onToggleBan;

  @override
  Widget build(BuildContext context) {
    final name = data['displayName'] ?? data['name'] ?? 'Ẩn danh';
    final email = data['email'] ?? '';
    final level = data['level'] ?? 'A1';
    final streak = data['streak'] ?? 0;
    final wordsLearned = data['wordsLearned'] ?? 0;
    final isBanned = data['banned'] == true;
    final avatar = data['avatar'] ?? '';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
              child: avatar.isEmpty
                  ? Text(name.toString().substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold))
                  : null,
            ),
            if (isBanned)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.block, size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(name.toString(),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            _LevelBadge(level.toString()),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(email.toString(),
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.local_fire_department,
                    size: 14, color: Colors.orange),
                Text(' $streak ngày  ',
                    style: const TextStyle(fontSize: 12)),
                const Icon(Icons.translate, size: 14, color: Colors.blue),
                Text(' $wordsLearned từ',
                    style: const TextStyle(fontSize: 12)),
                if (isBanned) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Bị khóa',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.red,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (v) {
            if (v == 'detail') onViewDetail();
            if (v == 'ban') onToggleBan();
            if (v == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'detail',
              child: Row(children: [
                Icon(Icons.info_outline),
                SizedBox(width: 8),
                Text('Chi tiết'),
              ]),
            ),
            PopupMenuItem(
              value: 'ban',
              child: Row(children: [
                Icon(isBanned ? Icons.lock_open : Icons.block,
                    color: isBanned ? Colors.green : Colors.orange),
                const SizedBox(width: 8),
                Text(isBanned ? 'Mở khóa' : 'Khóa tài khoản'),
              ]),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(children: [
                Icon(Icons.delete_outline, color: Colors.red),
                SizedBox(width: 8),
                Text('Xóa', style: TextStyle(color: Colors.red)),
              ]),
            ),
          ],
        ),
        onTap: onViewDetail,
      ),
    );
  }
}

// ── User detail dialog ────────────────────────────────────────────────────────
class _UserDetailDialog extends StatelessWidget {
  const _UserDetailDialog({required this.docId, required this.data});

  final String docId;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final name = data['displayName'] ?? data['name'] ?? 'Ẩn danh';
    final email = data['email'] ?? '';
    final level = data['level'] ?? 'A1';
    final streak = data['streak'] ?? 0;
    final wordsLearned = data['wordsLearned'] ?? 0;
    final totalTests = data['totalTests'] ?? 0;
    final lastTestScore = data['lastTestScore'] ?? 0;
    final progress = ((data['progress'] ?? 0.0) as num).toDouble();
    final avatar = data['avatar'] ?? '';
    final createdAt = data['createdAt'];
    String dateStr = '';
    if (createdAt is Timestamp) {
      dateStr = DateFormat('dd/MM/yyyy HH:mm').format(createdAt.toDate());
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              CircleAvatar(
                radius: 40,
                backgroundImage:
                    avatar.isNotEmpty ? NetworkImage(avatar) : null,
                child: avatar.isEmpty
                    ? Text(
                        name.toString().substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              Text(name.toString(),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              Text(email.toString(),
                  style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 4),
              _LevelBadge(level.toString()),
              const SizedBox(height: 16),
              const Divider(),
              // Stats grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.5,
                children: [
                  _StatItem(Icons.local_fire_department, 'Streak',
                      '$streak ngày', Colors.orange),
                  _StatItem(Icons.translate, 'Từ đã học',
                      '$wordsLearned từ', Colors.blue),
                  _StatItem(Icons.quiz, 'Bài kiểm tra',
                      '$totalTests bài', Colors.purple),
                  _StatItem(Icons.star, 'Điểm gần nhất',
                      '$lastTestScore điểm', Colors.amber),
                ],
              ),
              const SizedBox(height: 8),
              // Progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tiến độ: ${(progress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                    ),
                  ),
                ],
              ),
              if (dateStr.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Tham gia: $dateStr',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem(this.icon, this.label, this.value, this.color);
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge(this.level);
  final String level;

  static const _colors = {
    'A1': Colors.blue,
    'A2': Colors.green,
    'B1': Colors.orange,
    'B2': Colors.purple,
    'C1': Colors.red,
    'C2': Colors.teal,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[level] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        level,
        style: TextStyle(
            fontSize: 11, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
