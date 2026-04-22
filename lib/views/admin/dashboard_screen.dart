import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Stat cards ──────────────────────────────────────────────────
          _StatCardsRow(),
          const SizedBox(height: 24),
          // ── Charts row ──────────────────────────────────────────────────
          LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth >= 700;
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _LevelPieChart()),
                  const SizedBox(width: 16),
                  Expanded(child: _RecentUsersCard()),
                ],
              );
            }
            return Column(
              children: [
                _LevelPieChart(),
                const SizedBox(height: 16),
                _RecentUsersCard(),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ── Stat cards ────────────────────────────────────────────────────────────────
class _StatCardsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, userSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('topics').snapshots(),
          builder: (context, topicSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .snapshots(),
              builder: (context, notifSnap) {
                final userCount = userSnap.data?.docs.length ?? 0;
                final topicCount = topicSnap.data?.docs.length ?? 0;
                final notifCount = notifSnap.data?.docs.length ?? 0;

                // Count total words across all topics
                int wordCount = 0;
                if (topicSnap.hasData) {
                  for (final doc in topicSnap.data!.docs) {
                    final d = doc.data() as Map<String, dynamic>;
                    wordCount += (d['wordCount'] ?? 0) as int;
                  }
                }

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _StatCard(
                      label: 'Người dùng',
                      value: userCount,
                      icon: Icons.people_alt_rounded,
                      color: Colors.blue,
                    ),
                    _StatCard(
                      label: 'Chủ đề',
                      value: topicCount,
                      icon: Icons.menu_book_rounded,
                      color: Colors.green,
                    ),
                    _StatCard(
                      label: 'Từ vựng',
                      value: wordCount,
                      icon: Icons.translate_rounded,
                      color: Colors.orange,
                    ),
                    _StatCard(
                      label: 'Thông báo',
                      value: notifCount,
                      icon: Icons.campaign_rounded,
                      color: Colors.purple,
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ],
      ),
    );
  }
}

// ── Level pie chart ───────────────────────────────────────────────────────────
class _LevelPieChart extends StatelessWidget {
  static const _levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
  static const _colors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snap) {
        final Map<String, int> counts = {for (final l in _levels) l: 0};
        if (snap.hasData) {
          for (final doc in snap.data!.docs) {
            final d = doc.data() as Map<String, dynamic>;
            final level = (d['level'] ?? 'A1').toString();
            counts[level] = (counts[level] ?? 0) + 1;
          }
        }

        final total = counts.values.fold(0, (a, b) => a + b);

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Phân bố cấp độ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: total == 0
                      ? const Center(child: Text('Chưa có dữ liệu'))
                      : PieChart(
                          PieChartData(
                            sections: List.generate(_levels.length, (i) {
                              final count = counts[_levels[i]] ?? 0;
                              if (count == 0) return null;
                              return PieChartSectionData(
                                value: count.toDouble(),
                                title: '${_levels[i]}\n$count',
                                color: _colors[i],
                                radius: 70,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }).whereType<PieChartSectionData>().toList(),
                            sectionsSpace: 2,
                            centerSpaceRadius: 30,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                // Legend
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: List.generate(_levels.length, (i) {
                    final count = counts[_levels[i]] ?? 0;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _colors[i],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('${_levels[i]}: $count',
                            style: const TextStyle(fontSize: 12)),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Recent users ──────────────────────────────────────────────────────────────
class _RecentUsersCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Người dùng mới nhất',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('createdAt', descending: true)
                  .limit(8)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return const Text('Chưa có người dùng');
                }
                return Column(
                  children: docs.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    final createdAt = d['createdAt'];
                    String dateStr = '';
                    if (createdAt is Timestamp) {
                      dateStr = DateFormat('dd/MM/yyyy')
                          .format(createdAt.toDate());
                    }
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundImage: (d['avatar'] ?? '').isNotEmpty
                            ? NetworkImage(d['avatar'])
                            : null,
                        child: (d['avatar'] ?? '').isEmpty
                            ? Text(
                                (d['displayName'] ?? d['name'] ?? '?')
                                    .toString()
                                    .substring(0, 1)
                                    .toUpperCase(),
                              )
                            : null,
                      ),
                      title: Text(
                        d['displayName'] ?? d['name'] ?? 'Ẩn danh',
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(d['email'] ?? '',
                          style: const TextStyle(fontSize: 12)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _LevelBadge(d['level'] ?? 'A1'),
                          if (dateStr.isNotEmpty)
                            Text(dateStr,
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
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
