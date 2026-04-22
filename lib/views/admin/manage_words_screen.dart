import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageWordsScreen extends StatefulWidget {
  const ManageWordsScreen({super.key});

  @override
  State<ManageWordsScreen> createState() => _ManageWordsScreenState();
}

class _ManageWordsScreenState extends State<ManageWordsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Toolbar ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm chủ đề...',
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
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Thêm chủ đề'),
                onPressed: () => _showTopicDialog(context),
              ),
            ],
          ),
        ),

        // ── List ───────────────────────────────────────────────────────────
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('topics')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var docs = snap.data!.docs;

              if (_search.isNotEmpty) {
                docs = docs.where((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final name = (d['name'] ?? '').toString().toLowerCase();
                  return name.contains(_search);
                }).toList();
              }

              if (docs.isEmpty) {
                return const Center(child: Text('Chưa có chủ đề nào'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final doc = docs[i];
                  final d = doc.data() as Map<String, dynamic>;
                  return _TopicTile(
                    docId: doc.id,
                    data: d,
                    onEdit: () => _showTopicDialog(context,
                        docId: doc.id, existing: d),
                    onDelete: () => _confirmDelete(doc.id, d),
                    onManageWords: () =>
                        _showWordsSheet(context, doc.id, d),
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
        title: const Text('Xóa chủ đề?'),
        content: Text('Xóa "${d['name']}"? Tất cả từ vựng trong chủ đề cũng sẽ bị xóa.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              // Delete all words in topic first
              final words = await FirebaseFirestore.instance
                  .collection('topics')
                  .doc(docId)
                  .collection('words')
                  .get();
              final batch = FirebaseFirestore.instance.batch();
              for (final w in words.docs) {
                batch.delete(w.reference);
              }
              batch.delete(FirebaseFirestore.instance
                  .collection('topics')
                  .doc(docId));
              await batch.commit();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa chủ đề')),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showTopicDialog(BuildContext context,
      {String? docId, Map<String, dynamic>? existing}) {
    final nameCtrl =
        TextEditingController(text: existing?['name'] ?? '');
    final descCtrl =
        TextEditingController(text: existing?['description'] ?? '');
    String level = existing?['level'] ?? 'A1';
    final levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(docId == null ? 'Thêm chủ đề' : 'Sửa chủ đề'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên chủ đề *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: level,
                decoration: const InputDecoration(
                  labelText: 'Cấp độ',
                  border: OutlineInputBorder(),
                ),
                items: levels
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (v) => setS(() => level = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;

                final data = {
                  'name': name,
                  'description': descCtrl.text.trim(),
                  'level': level,
                  'updatedAt': FieldValue.serverTimestamp(),
                };

                if (docId == null) {
                  data['createdAt'] = FieldValue.serverTimestamp();
                  data['wordCount'] = 0;
                  await FirebaseFirestore.instance
                      .collection('topics')
                      .add(data);
                } else {
                  await FirebaseFirestore.instance
                      .collection('topics')
                      .doc(docId)
                      .update(data);
                }

                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(docId == null ? 'Thêm' : 'Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  void _showWordsSheet(
      BuildContext context, String topicId, Map<String, dynamic> topicData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _WordsSheet(topicId: topicId, topicData: topicData),
    );
  }
}

// ── Topic tile ────────────────────────────────────────────────────────────────
class _TopicTile extends StatelessWidget {
  const _TopicTile({
    required this.docId,
    required this.data,
    required this.onEdit,
    required this.onDelete,
    required this.onManageWords,
  });

  final String docId;
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onManageWords;

  static const _levelColors = {
    'A1': Colors.blue,
    'A2': Colors.green,
    'B1': Colors.orange,
    'B2': Colors.purple,
    'C1': Colors.red,
    'C2': Colors.teal,
  };

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'Không tên';
    final desc = data['description'] ?? '';
    final level = data['level'] ?? '';
    final wordCount = data['wordCount'] ?? 0;
    final color = _levelColors[level] ?? Colors.grey;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.menu_book_rounded, color: color),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(name.toString(),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            if (level.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(level.toString(),
                    style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (desc.toString().isNotEmpty)
              Text(desc.toString(),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text('$wordCount từ vựng',
                style: const TextStyle(fontSize: 12, color: Colors.blue)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (v) {
            if (v == 'words') onManageWords();
            if (v == 'edit') onEdit();
            if (v == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'words',
              child: Row(children: [
                Icon(Icons.list_alt),
                SizedBox(width: 8),
                Text('Quản lý từ'),
              ]),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(children: [
                Icon(Icons.edit_outlined),
                SizedBox(width: 8),
                Text('Sửa'),
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
        onTap: onManageWords,
      ),
    );
  }
}

// ── Words bottom sheet ────────────────────────────────────────────────────────
class _WordsSheet extends StatefulWidget {
  const _WordsSheet({required this.topicId, required this.topicData});
  final String topicId;
  final Map<String, dynamic> topicData;

  @override
  State<_WordsSheet> createState() => _WordsSheetState();
}

class _WordsSheetState extends State<_WordsSheet> {
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Từ vựng: ${widget.topicData['name'] ?? ''}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.blue),
                  onPressed: () => _showWordDialog(context),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('topics')
                  .doc(widget.topicId)
                  .collection('words')
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                      child: Text('Chưa có từ vựng nào'));
                }
                return ListView.separated(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final d = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(d['word'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(d['meaning'] ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                size: 18, color: Colors.blue),
                            onPressed: () => _showWordDialog(context,
                                docId: doc.id, existing: d),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: Colors.red),
                            onPressed: () => _deleteWord(doc.id),
                          ),
                        ],
                      ),
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

  Future<void> _deleteWord(String wordId) async {
    await FirebaseFirestore.instance
        .collection('topics')
        .doc(widget.topicId)
        .collection('words')
        .doc(wordId)
        .delete();
    // Update word count
    final count = await FirebaseFirestore.instance
        .collection('topics')
        .doc(widget.topicId)
        .collection('words')
        .count()
        .get();
    await FirebaseFirestore.instance
        .collection('topics')
        .doc(widget.topicId)
        .update({'wordCount': count.count});
  }

  void _showWordDialog(BuildContext context,
      {String? docId, Map<String, dynamic>? existing}) {
    final wordCtrl =
        TextEditingController(text: existing?['word'] ?? '');
    final meaningCtrl =
        TextEditingController(text: existing?['meaning'] ?? '');
    final exampleCtrl =
        TextEditingController(text: existing?['example'] ?? '');
    final pronunciationCtrl =
        TextEditingController(text: existing?['pronunciation'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(docId == null ? 'Thêm từ vựng' : 'Sửa từ vựng'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: wordCtrl,
                decoration: const InputDecoration(
                  labelText: 'Từ vựng *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: meaningCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nghĩa *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: pronunciationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Phiên âm',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: exampleCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Ví dụ',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              final word = wordCtrl.text.trim();
              final meaning = meaningCtrl.text.trim();
              if (word.isEmpty || meaning.isEmpty) return;

              final data = {
                'word': word,
                'meaning': meaning,
                'pronunciation': pronunciationCtrl.text.trim(),
                'example': exampleCtrl.text.trim(),
                'updatedAt': FieldValue.serverTimestamp(),
              };

              final ref = FirebaseFirestore.instance
                  .collection('topics')
                  .doc(widget.topicId)
                  .collection('words');

              if (docId == null) {
                data['createdAt'] = FieldValue.serverTimestamp();
                await ref.add(data);
                // Update word count
                final count = await ref.count().get();
                await FirebaseFirestore.instance
                    .collection('topics')
                    .doc(widget.topicId)
                    .update({'wordCount': count.count});
              } else {
                await ref.doc(docId).update(data);
              }

              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(docId == null ? 'Thêm' : 'Lưu'),
          ),
        ],
      ),
    );
  }
}
