import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

////////////////////////////////////////////////////////////
/// MODEL
////////////////////////////////////////////////////////////

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String time;
  final bool isRead;
  final String type;
  final bool isLocal; // true = local (SharedPrefs), false = Firestore

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    this.isRead = false,
    required this.type,
    this.isLocal = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'time': time,
    'isRead': isRead,
    'type': type,
  };

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      time: json['time'] ?? '',
      isRead: json['isRead'] ?? false,
      type: json['type'] ?? 'info',
      isLocal: true,
    );
  }

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    final createdAt = d['createdAt'];
    String timeStr = '';
    if (createdAt is Timestamp) {
      timeStr = DateFormat('HH:mm dd/MM').format(createdAt.toDate());
    }
    return NotificationModel(
      id: doc.id,
      title: d['title'] ?? '',
      message: d['body'] ?? d['message'] ?? '',
      time: timeStr,
      isRead: false,
      type: d['type'] ?? 'info',
      isLocal: false,
    );
  }
}

////////////////////////////////////////////////////////////
/// SCREEN
////////////////////////////////////////////////////////////

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<NotificationModel> _localNotifs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadLocal();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── Local (SharedPrefs) ───────────────────────────────────────────────────

  Future<void> _loadLocal() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('notifications') ?? [];
    _localNotifs = data
        .map((e) => NotificationModel.fromJson(jsonDecode(e)))
        .toList()
        .reversed
        .toList();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _markLocalRead(NotificationModel n) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('notifications') ?? [];
    final updated = data.map((e) {
      final json = jsonDecode(e) as Map<String, dynamic>;
      if (json['id'] == n.id) json['isRead'] = true;
      return jsonEncode(json);
    }).toList();
    await prefs.setStringList('notifications', updated);
    _loadLocal();
  }

  Future<void> _deleteLocal(NotificationModel n) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('notifications') ?? [];
    final filtered =
        data.where((e) => jsonDecode(e)['id'] != n.id).toList();
    await prefs.setStringList('notifications', filtered);
    _loadLocal();
  }

  Future<void> _clearLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notifications');
    if (mounted) setState(() => _localNotifs.clear());
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final unreadLocal = _localNotifs.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Của tôi'),
                  if (unreadLocal > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$unreadLocal',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Từ Admin'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Xóa tất cả',
            onPressed: _tabCtrl.index == 0 && _localNotifs.isNotEmpty
                ? _clearLocal
                : null,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // Tab 1: Thông báo local (từ app)
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _localNotifs.isEmpty
                  ? _emptyState('Chưa có thông báo nào')
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _localNotifs.length,
                      itemBuilder: (_, i) =>
                          _notifCard(_localNotifs[i]),
                    ),

          // Tab 2: Thông báo từ Admin (Firestore)
          _AdminNotifTab(),
        ],
      ),
    );
  }

  Widget _notifCard(NotificationModel n) {
    final color = _typeColor(n.type);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: n.isRead ? null : () => _markLocalRead(n),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(_typeIcon(n.type), color: color, size: 20),
        ),
        title: Text(
          n.title,
          style: TextStyle(
            fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(n.message, maxLines: 2, overflow: TextOverflow.ellipsis),
            if (n.time.isNotEmpty)
              Text(n.time,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'delete') _deleteLocal(n);
            if (v == 'read') _markLocalRead(n);
          },
          itemBuilder: (_) => [
            if (!n.isRead)
              const PopupMenuItem(
                  value: 'read', child: Text('Đánh dấu đã đọc')),
            const PopupMenuItem(
                value: 'delete', child: Text('Xóa')),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_none, size: 72, color: Colors.grey),
          const SizedBox(height: 12),
          Text(msg, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'success': return Colors.green;
      case 'warning': return Colors.orange;
      case 'error':   return Colors.red;
      default:        return Colors.blue;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'success': return Icons.check_circle_outline;
      case 'warning': return Icons.warning_amber_outlined;
      case 'error':   return Icons.error_outline;
      default:        return Icons.info_outline;
    }
  }
}

////////////////////////////////////////////////////////////
/// ADMIN NOTIFICATIONS TAB — đọc từ Firestore
////////////////////////////////////////////////////////////

class _AdminNotifTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Vui lòng đăng nhập'));
    }

    // Lấy level của user để filter thông báo theo target
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, userSnap) {
        final userLevel =
            (userSnap.data?.data() as Map<String, dynamic>?)?['level'] ?? 'A1';

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .orderBy('createdAt', descending: true)
              .limit(50)
              .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.campaign_outlined,
                        size: 72, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('Chưa có thông báo từ Admin',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }

            // Filter: target == 'all' hoặc target == level của user
            final docs = snap.data!.docs.where((doc) {
              final target =
                  (doc.data() as Map<String, dynamic>)['target'] ?? 'all';
              return target == 'all' || target == userLevel;
            }).toList();

            if (docs.isEmpty) {
              return const Center(
                child: Text('Không có thông báo dành cho bạn',
                    style: TextStyle(color: Colors.grey)),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: docs.length,
              itemBuilder: (_, i) {
                final n = NotificationModel.fromFirestore(docs[i]);
                return _AdminNotifCard(n: n);
              },
            );
          },
        );
      },
    );
  }
}

class _AdminNotifCard extends StatelessWidget {
  final NotificationModel n;
  const _AdminNotifCard({required this.n});

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(n.type);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(_typeIcon(n.type), color: color, size: 20),
        ),
        title: Text(n.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(n.message, maxLines: 3, overflow: TextOverflow.ellipsis),
            if (n.time.isNotEmpty)
              Text(n.time,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'success': return Colors.green;
      case 'warning': return Colors.orange;
      case 'error':   return Colors.red;
      default:        return Colors.blue;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'success': return Icons.check_circle_outline;
      case 'warning': return Icons.warning_amber_outlined;
      case 'error':   return Icons.error_outline;
      default:        return Icons.info_outline;
    }
  }
}

////////////////////////////////////////////////////////////
/// SEND LOCAL NOTIFICATION (dùng trong app)
////////////////////////////////////////////////////////////

Future<void> sendNotification({
  required String title,
  required String message,
  required String type,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final data = prefs.getStringList('notifications') ?? [];

  final newNoti = NotificationModel(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    title: title,
    message: message,
    time: DateFormat('HH:mm dd/MM').format(DateTime.now()),
    type: type,
  );

  data.add(jsonEncode(newNoti.toJson()));
  await prefs.setStringList('notifications', data);
}
