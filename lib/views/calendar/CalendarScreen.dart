import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'add_event_screen.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay  = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};

  static const _primary = Color(0xFF667eea);

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    FirebaseFirestore.instance
        .collection('events')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .listen((s) {
      final map = <DateTime, List<Map<String, dynamic>>>{};
      for (var d in s.docs) {
        final data = d.data();
        final date = (data['date'] as Timestamp).toDate();
        final key  = DateTime(date.year, date.month, date.day);
        map.putIfAbsent(key, () => []);
        map[key]!.add({...data, 'id': d.id});
      }
      if (mounted) setState(() => _events = map);
    });
  }

  List<Map<String, dynamic>> _getEvents(DateTime day) =>
      _events[DateTime(day.year, day.month, day.day)] ?? [];

  Future<void> _deleteEvent(String id) async =>
      FirebaseFirestore.instance.collection('events').doc(id).delete();

  Future<void> _toggleComplete(String id, bool current) async =>
      FirebaseFirestore.instance
          .collection('events')
          .doc(id)
          .update({'completed': !current});

  @override
  Widget build(BuildContext context) {
    final cs       = Theme.of(context).colorScheme;
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final selected = _selectedDay ?? _focusedDay;
    final events   = _getEvents(selected);

    // Đếm tổng sự kiện hôm nay
    final todayEvents = _getEvents(DateTime.now());

    return Scaffold(
      backgroundColor: cs.surface,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: _primary,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text(
                'Lịch học tập',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20, top: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('📅', style: TextStyle(fontSize: 36)),
                        if (todayEvents.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${todayEvents.length} sự kiện hôm nay',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 26),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AddEventScreen(selectedDate: _selectedDay),
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ],
        body: Column(
          children: [
            // ── Calendar ──────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TableCalendar(
                focusedDay:  _focusedDay,
                firstDay:    DateTime(2020),
                lastDay:     DateTime(2030),
                selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
                onDaySelected: (s, f) => setState(() {
                  _selectedDay = s;
                  _focusedDay  = f;
                }),
                eventLoader: _getEvents,
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  todayDecoration: BoxDecoration(
                    color: _primary.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(
                    color: _primary,
                    fontWeight: FontWeight.bold,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: _primary,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  markerDecoration: const BoxDecoration(
                    color: Color(0xFF06D6A0),
                    shape: BoxShape.circle,
                  ),
                  markerSize: 5,
                  markersMaxCount: 3,
                  defaultTextStyle: TextStyle(color: cs.onSurface),
                  weekendTextStyle:
                      TextStyle(color: cs.onSurface.withOpacity(0.6)),
                  outsideTextStyle:
                      TextStyle(color: cs.onSurface.withOpacity(0.3)),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    color: cs.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  leftChevronIcon:
                      Icon(Icons.chevron_left, color: cs.onSurface),
                  rightChevronIcon:
                      Icon(Icons.chevron_right, color: cs.onSurface),
                  headerPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    color: cs.onSurface.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  weekendStyle: TextStyle(
                    color: _primary.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // ── Selected date header ───────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(selected),
                      style: const TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (events.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06D6A0).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${events.length} sự kiện',
                        style: const TextStyle(
                          color: Color(0xFF06D6A0),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  const Spacer(),
                  // Nút thêm nhanh
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AddEventScreen(selectedDate: _selectedDay),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            // ── Event list ────────────────────────────────
            Expanded(
              child: events.isEmpty
                  ? _EmptyEvents(date: selected)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: events.length,
                      itemBuilder: (_, i) => _EventCard(
                        event:          events[i],
                        onToggle:       () => _toggleComplete(
                            events[i]['id'], events[i]['completed'] == true),
                        onDelete:       () => _deleteEvent(events[i]['id']),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Event Card ───────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  const _EventCard({
    required this.event,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs        = Theme.of(context).colorScheme;
    final completed = event['completed'] == true;
    final isAI      = event['source'] == 'meow_ai';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: completed
              ? const Color(0xFF06D6A0).withOpacity(0.4)
              : cs.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: GestureDetector(
          onTap: onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: completed
                  ? const Color(0xFF06D6A0)
                  : const Color(0xFF667eea).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              completed ? Icons.check_rounded : Icons.event_rounded,
              color: completed ? Colors.white : const Color(0xFF667eea),
              size: 20,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                event['title'] ?? '',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: completed
                      ? cs.onSurface.withOpacity(0.4)
                      : cs.onSurface,
                  decoration:
                      completed ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (isAI)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '😺 AI',
                  style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF667eea),
                      fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
        subtitle: event['time'] != null
            ? Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 13,
                        color: cs.onSurface.withOpacity(0.45)),
                    const SizedBox(width: 4),
                    Text(
                      event['time'],
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
              )
            : null,
        trailing: IconButton(
          icon: Icon(Icons.delete_outline_rounded,
              color: cs.onSurface.withOpacity(0.35), size: 20),
          onPressed: () => _confirmDelete(context),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa sự kiện?'),
        content: Text('Xóa "${event['title']}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: const Text('Xóa',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyEvents extends StatelessWidget {
  final DateTime date;
  const _EmptyEvents({required this.date});

  @override
  Widget build(BuildContext context) {
    final isToday = isSameDay(date, DateTime.now());
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Text('📭', style: TextStyle(fontSize: 40)),
          ),
          const SizedBox(height: 16),
          Text(
            isToday ? 'Hôm nay chưa có sự kiện' : 'Không có sự kiện',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Nhấn + để thêm sự kiện mới',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}
