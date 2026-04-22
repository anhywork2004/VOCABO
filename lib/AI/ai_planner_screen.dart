import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/services/meow_ai_service.dart';
import '../views/calendar/CalendarScreen.dart';

// ─── Screen ───────────────────────────────────────────────────────────────────

class AIPlannerScreen extends StatefulWidget {
  const AIPlannerScreen({super.key});

  @override
  State<AIPlannerScreen> createState() => _AIPlannerScreenState();
}

class _AIPlannerScreenState extends State<AIPlannerScreen> {
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();
  final _focus  = FocusNode();

  List<_Msg> _msgs    = [];
  bool       _loading = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final h = await MeowAIService.loadHistory();
    setState(() {
      _msgs = h
          .map((m) => _Msg(
                isUser: m['role'] != 'ai',
                text:   m['content']!,
              ))
          .toList();
    });
    _jump();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _ctrl.text).trim();
    if (text.isEmpty || _loading) return;

    setState(() {
      _msgs.add(_Msg(isUser: true, text: text));
      _loading = true;
    });
    _ctrl.clear();
    _focus.requestFocus();
    _jump();

    final res = await MeowAIService.askMeow(text);

    setState(() {
      _msgs.add(_Msg(isUser: false, text: res.text));
      _loading = false;
    });

    if (res.calendarEvent != null) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (mounted) _confirmCalendar(res.calendarEvent!);
    }
    _jump();
  }

  void _jump() {
    Future.delayed(const Duration(milliseconds: 280), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Calendar confirm ───────────────────────────────────

  void _confirmCalendar(CalendarEventData ev) {
    final date = DateFormat('dd/MM/yyyy').format(ev.date);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _CalendarSheet(
        event: ev,
        dateStr: date,
        onConfirm: () async {
          final ok = await MeowAIService.saveEventToCalendar(ev);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(ok
                  ? '✅ Đã thêm "${ev.title}" vào lịch'
                  : '❌ Không thể lưu sự kiện'),
              backgroundColor: ok ? const Color(0xFF06D6A0) : Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ));
          }
        },
      ),
    );
  }

  // ── Clear ──────────────────────────────────────────────

  void _askClear() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Xóa cuộc trò chuyện?'),
        content: const Text('Lịch sử chat sẽ bị xóa vĩnh viễn.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await MeowAIService.clearHistory();
              setState(() => _msgs.clear());
            },
            child: const Text('Xóa',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF0F2F8),
      appBar: _AppBar(
        onCalendar: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CalendarScreen())),
        onClear: _msgs.isEmpty ? null : _askClear,
      ),
      body: Column(
        children: [
          Expanded(
            child: _msgs.isEmpty
                ? _Welcome(onChip: _send)
                : _ChatList(
                    msgs:    _msgs,
                    loading: _loading,
                    scroll:  _scroll,
                  ),
          ),
          _InputBar(
            ctrl:    _ctrl,
            focus:   _focus,
            loading: _loading,
            onSend:  _send,
          ),
        ],
      ),
    );
  }
}

// ─── AppBar ───────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onCalendar;
  final VoidCallback? onClear;
  const _AppBar({required this.onCalendar, this.onClear});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: Theme.of(context).colorScheme.onSurface, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('😺', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Meow AI',
                style: TextStyle(
                  color: Color(0xFF1A1A2E),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF06D6A0),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Online',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_month_rounded,
              color: Color(0xFF667eea), size: 22),
          onPressed: onCalendar,
          tooltip: 'Xem lịch',
        ),
        if (onClear != null)
          IconButton(
            icon: Icon(Icons.delete_outline_rounded,
                color: Colors.grey.shade400, size: 22),
            onPressed: onClear,
            tooltip: 'Xóa lịch sử',
          ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: Colors.grey.shade100,
        ),
      ),
    );
  }
}

// ─── Chat list ────────────────────────────────────────────────────────────────

class _ChatList extends StatelessWidget {
  final List<_Msg>   msgs;
  final bool         loading;
  final ScrollController scroll;
  const _ChatList({
    required this.msgs,
    required this.loading,
    required this.scroll,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      itemCount: msgs.length + (loading ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == msgs.length) return const _TypingIndicator();
        return _BubbleRow(msg: msgs[i]);
      },
    );
  }
}

// ─── Bubble ───────────────────────────────────────────────────────────────────

class _BubbleRow extends StatelessWidget {
  final _Msg msg;
  const _BubbleRow({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar AI
          if (!isUser) ...[
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('😺', style: TextStyle(fontSize: 15)),
              ),
            ),
          ],

          // Bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.70,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF667eea)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(18),
                  topRight:    const Radius.circular(18),
                  bottomLeft:  Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? const Color(0xFF667eea).withOpacity(0.25)
                        : Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  color: isUser
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          ),

          // Spacer user side
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ─── Typing indicator ─────────────────────────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('😺', style: TextStyle(fontSize: 15)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft:     Radius.circular(18),
                topRight:    Radius.circular(18),
                bottomLeft:  Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(delay: 0),
                const SizedBox(width: 5),
                _Dot(delay: 180),
                const SizedBox(width: 5),
                _Dot(delay: 360),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double>   _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _a = Tween(begin: 0.0, end: -5.0).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay),
        () { if (mounted) _c.repeat(reverse: true); });
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _a.value),
        child: Container(
          width: 7, height: 7,
          decoration: BoxDecoration(
            color: Colors.grey.shade400,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ─── Input bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final FocusNode             focus;
  final bool                  loading;
  final void Function([String?]) onSend;
  const _InputBar({
    required this.ctrl,
    required this.focus,
    required this.loading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: EdgeInsets.only(
        left: 16, right: 12, top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Text field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: ctrl,
                focusNode: focus,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Nhắn tin với Meow...',
                  hintStyle: TextStyle(
                      color: Colors.grey.shade400, fontSize: 15),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Send button
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: ctrl,
            builder: (_, val, __) {
              final active = val.text.trim().isNotEmpty && !loading;
              return GestureDetector(
                onTap: active ? () => onSend() : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF667eea)
                        : Colors.grey.shade200,
                    shape: BoxShape.circle,
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: const Color(0xFF667eea)
                                  .withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : [],
                  ),
                  child: loading
                      ? const Padding(
                          padding: EdgeInsets.all(11),
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white),
                        )
                      : Icon(
                          Icons.send_rounded,
                          color: active
                              ? Colors.white
                              : Colors.grey.shade400,
                          size: 20,
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Welcome screen ───────────────────────────────────────────────────────────

class _Welcome extends StatelessWidget {
  final void Function([String?]) onChip;
  const _Welcome({required this.onChip});

  static const _chips = [
    ('📅', 'Lập kế hoạch học hôm nay'),
    ('🗓️', 'Thêm lịch ôn tập từ vựng'),
    ('💡', 'Gợi ý cách học từ vựng hiệu quả'),
    ('🎯', 'Lộ trình đạt IELTS 7.0'),
    ('📝', 'Tạo bài tập từ vựng cho tôi'),
    ('⏰', 'Nhắc nhở học mỗi ngày lúc 8h'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Text('😺', style: TextStyle(fontSize: 44)),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Xin chào! Mình là Meow',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Trợ lý AI học tiếng Anh của bạn.\nHỏi mình bất cứ điều gì nhé!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 32),

          // Divider
          Row(children: [
            Expanded(child: Divider(color: Colors.grey.shade200)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('Gợi ý',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade400)),
            ),
            Expanded(child: Divider(color: Colors.grey.shade200)),
          ]),

          const SizedBox(height: 16),

          // Suggestion chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _chips
                .map((c) => _Chip(
                      emoji: c.$1,
                      label: c.$2,
                      onTap: () => onChip(c.$2),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;
  const _Chip({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF444444),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Calendar bottom sheet ────────────────────────────────────────────────────

class _CalendarSheet extends StatelessWidget {
  final CalendarEventData event;
  final String            dateStr;
  final VoidCallback      onConfirm;
  const _CalendarSheet({
    required this.event,
    required this.dateStr,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calendar_today_rounded,
                    color: Color(0xFF667eea), size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Thêm vào Lịch',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Event card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5FA),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF1A1A2E)),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.calendar_month_rounded,
                      size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 5),
                  Text(
                    '$dateStr  ${event.time}',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade600),
                  ),
                ]),
                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    event.description,
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: const Text('Bỏ qua',
                    style: TextStyle(color: Colors.grey)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onConfirm();
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Thêm vào lịch'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ─── Models ───────────────────────────────────────────────────────────────────

class _Msg {
  final bool   isUser;
  final String text;
  const _Msg({required this.isUser, required this.text});
}
