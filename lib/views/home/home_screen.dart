import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocabodemo/views/add/add_screen.dart';
import 'package:vocabodemo/views/calendar/CalendarScreen.dart';
import 'package:vocabodemo/views/notification/notification_screen.dart';
import 'package:vocabodemo/views/settings/setting_screen.dart';
import 'package:vocabodemo/views/review/ReviewScreen.dart';
import 'package:vocabodemo/views/test/TestScreen.dart';
import 'package:vocabodemo/views/flashcard/flashcard_screen.dart';
import 'package:vocabodemo/views/grammar/grammar_screen.dart';
import 'package:vocabodemo/AI/ai_chat_bubble.dart';
import 'package:vocabodemo/views/home/widgets/achievement_card.dart';
import 'package:vocabodemo/data/services/weekly_chart_firestore.dart';
import 'package:vocabodemo/views/home/widgets/search_box.dart';
import 'package:vocabodemo/views/home/widgets/learning_path.dart';

////////////////////////////////////////////////////////////
/// USER STATS
////////////////////////////////////////////////////////////

class UserStats {
  final String level;
  final int streak;
  final int wordsLearned;
  final double progress;
  final int totalWords;
  final int lastTestScore;
  final int totalTests;

  const UserStats({
    required this.level,
    required this.streak,
    required this.wordsLearned,
    required this.progress,
    this.totalWords = 0,
    this.lastTestScore = 0,
    this.totalTests = 0,
  });

  factory UserStats.fromMap(Map<String, dynamic> d) {
    return UserStats(
      level: (d['level'] ?? 'A1').toString(),
      streak: (d['streak'] ?? 0).toInt(),
      wordsLearned: (d['wordsLearned'] ?? 0).toInt(),
      progress: (d['progress'] ?? 0.0).toDouble(),
      totalWords: (d['totalWords'] ?? 0).toInt(),
      lastTestScore: (d['lastTestScore'] ?? 0).toInt(),
      totalTests: (d['totalTests'] ?? 0).toInt(),
    );
  }

  static const empty = UserStats(
    level: 'A1',
    streak: 0,
    wordsLearned: 0,
    progress: 0,
  );
}

////////////////////////////////////////////////////////////
/// HOME SCREEN
////////////////////////////////////////////////////////////

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;

  final screens = const [
    HomePage(),
    CalendarScreen(),
    AddScreen(),
    NotificationScreen(),
    SettingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: index, children: screens),
          const AIChatBubble(),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: _FloatingNavBar(
              currentIndex: index,
              onTap: (i) => setState(() => index = i),
            ),
          ),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// FLOATING NAV BAR
////////////////////////////////////////////////////////////

class _FloatingNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<_FloatingNavBar> createState() => _FloatingNavBarState();
}

class _FloatingNavBarState extends State<_FloatingNavBar> {
  int _adminUnread = 0;

  static const _items = [
    _NavItem(icon: Icons.home_rounded,          label: 'Trang chủ'),
    _NavItem(icon: Icons.calendar_month_rounded, label: 'Lịch'),
    _NavItem(icon: Icons.add_circle_rounded,     label: 'Thêm', isCenter: true),
    _NavItem(icon: Icons.notifications_rounded,  label: 'Thông báo'),
    _NavItem(icon: Icons.settings_rounded,       label: 'Cài đặt'),
  ];

  @override
  void initState() {
    super.initState();
    _listenAdminNotifs();
  }

  void _listenAdminNotifs() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Lắng nghe realtime thông báo admin từ Firestore
    FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snap) async {
      if (!mounted) return;

      // Lấy thời điểm user đã xem lần cuối
      final prefs = await SharedPreferences.getInstance();
      final lastSeenMs = prefs.getInt('last_seen_admin_notif_${user.uid}') ?? 0;
      final lastSeen   = DateTime.fromMillisecondsSinceEpoch(lastSeenMs);

      // Lấy level user để filter
      final userDoc = await FirebaseFirestore.instance
          .collection('users').doc(user.uid).get();
      final userLevel =
          (userDoc.data()?['level'] ?? 'A1').toString();

      int unread = 0;
      for (final doc in snap.docs) {
        final d = doc.data();
        final target = d['target'] ?? 'all';
        if (target != 'all' && target != userLevel) continue;

        final createdAt = d['createdAt'];
        if (createdAt is Timestamp) {
          if (createdAt.toDate().isAfter(lastSeen)) unread++;
        }
      }

      if (mounted) setState(() => _adminUnread = unread);
    });
  }

  // Khi user nhấn vào tab Thông báo → đánh dấu đã xem
  void _markAdminSeen() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'last_seen_admin_notif_${user.uid}',
      DateTime.now().millisecondsSinceEpoch,
    );
    if (mounted) setState(() => _adminUnread = 0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg  = isDark ? const Color(0xFF1E1E2E) : Colors.white;

    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: navBg,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_items.length, (i) {
          final item = _items[i];
          final sel  = widget.currentIndex == i;
          // index 3 = Thông báo
          final showBadge = i == 3 && _adminUnread > 0;

          return Expanded(
            child: Center(
              child: item.isCenter
                  ? _CenterButton(onTap: () => widget.onTap(i))
                  : _NavButton(
                      item:      item,
                      selected:  sel,
                      badge:     showBadge ? _adminUnread : 0,
                      onTap: () {
                        if (i == 3) _markAdminSeen();
                        widget.onTap(i);
                      },
                    ),
            ),
          );
        }),
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// CENTER ADD BUTTON
////////////////////////////////////////////////////////////

class _CenterButton extends StatefulWidget {
  final VoidCallback onTap;
  const _CenterButton({required this.onTap});

  @override
  State<_CenterButton> createState() => _CenterButtonState();
}

class _CenterButtonState extends State<_CenterButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scale = Tween(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _rotation = Tween(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _ctrl.forward();
  void _onTapUp(_) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _ctrl.reverse();
    widget.onTap();
  }
  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Transform.scale(
          scale: _scale.value,
          child: Transform.rotate(
            angle: _rotation.value * 3.14159 * 2,
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x55667eea),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// NAV BUTTON với hiệu ứng bounce + indicator
////////////////////////////////////////////////////////////

class _NavButton extends StatefulWidget {
  final _NavItem item;
  final bool selected;
  final int  badge;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _bounce = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -6.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 2.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 2.0, end: 0.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_NavButton old) {
    super.didUpdateWidget(old);
    if (widget.selected && !old.selected) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF667eea);
    final inactiveColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade500
        : Colors.grey;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, widget.selected ? _bounce.value : 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicator dot
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: widget.selected ? 20 : 0,
                height: 3,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Icon
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: widget.selected
                      ? activeColor.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      widget.item.icon,
                      color: widget.selected ? activeColor : inactiveColor,
                      size: widget.selected ? 24 : 22,
                    ),
                    // Badge đỏ
                    if (widget.badge > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              widget.badge > 9 ? '9+' : '${widget.badge}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 2),

              // Label
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: widget.selected ? 10.5 : 10,
                  fontWeight: widget.selected
                      ? FontWeight.w600
                      : FontWeight.normal,
                  color: widget.selected ? activeColor : inactiveColor,
                ),
                child: Text(widget.item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// NAV ITEM MODEL
////////////////////////////////////////////////////////////

class _NavItem {
  final IconData icon;
  final String label;
  final bool isCenter;

  const _NavItem({
    required this.icon,
    required this.label,
    this.isCenter = false,
  });
}

////////////////////////////////////////////////////////////
/// HOME PAGE STREAM
////////////////////////////////////////////////////////////

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const _HomeContent(stats: UserStats.empty);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final stats = UserStats.fromMap(data);
        return _HomeContent(stats: stats);
      },
    );
  }
}

////////////////////////////////////////////////////////////
/// HOME CONTENT
////////////////////////////////////////////////////////////

class _HomeContent extends StatelessWidget {
  final UserStats stats;

  const _HomeContent({required this.stats});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: HeaderSection(stats: stats)),
        SliverToBoxAdapter(child: const MenuSection()),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 16),
              const WeeklyChartFirestore(),
              const SizedBox(height: 16),
              AchievementCard(
                streak: stats.streak,
                words: stats.wordsLearned,
                progress: stats.progress,
              ),
              const SizedBox(height: 16),
              const LearningPath(),
              const SizedBox(height: 110),
            ]),
          ),
        ),
      ],
    );
  }
}

////////////////////////////////////////////////////////////
/// HEADER
////////////////////////////////////////////////////////////

class HeaderSection extends StatelessWidget {
  final UserStats stats;

  const HeaderSection({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    final progressPct = (stats.progress * 100).toInt();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(
                      user.photoURL ?? 'https://i.pravatar.cc/300',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName ?? 'User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _LevelBadge(level: stats.level),
                            const SizedBox(width: 10),
                            _StreakBadge(streak: stats.streak),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const SearchBox(),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      icon: Icons.menu_book_rounded,
                      value: '${stats.wordsLearned}',
                      label: 'Words',
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.auto_graph,
                      value: '$progressPct%',
                      label: 'Progress',
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.local_fire_department,
                      value: '${stats.streak}',
                      label: 'Streak',
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// MENU SECTION
////////////////////////////////////////////////////////////

enum _MenuRoute { words, review, test, grammar }

class MenuSection extends StatelessWidget {
  const MenuSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: const [
          MenuItem(
            icon: Icons.menu_book,
            title: 'Words',
            iconSize: 34,
            routeType: _MenuRoute.words,
          ),
          MenuItem(
            icon: Icons.sync,
            title: 'Review',
            iconSize: 34,
            routeType: _MenuRoute.review,
          ),
          MenuItem(
            icon: Icons.quiz,
            title: 'Test',
            iconSize: 34,
            routeType: _MenuRoute.test,
          ),
          MenuItem(
            icon: Icons.menu_book_outlined,
            title: 'Grammar',
            iconSize: 34,
            routeType: _MenuRoute.grammar,
          ),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// MENU ITEM
////////////////////////////////////////////////////////////

class MenuItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final _MenuRoute routeType;
  final double iconSize;
  final Color iconColor;

  const MenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.routeType,
    this.iconSize = 34,
    this.iconColor = const Color(0xff2651ff),
  });

  @override
  State<MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<MenuItem>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _down(TapDownDetails _) => setState(() => _scale = 0.92);
  void _up(TapUpDetails _) => setState(() => _scale = 1.0);
  void _cancel() => setState(() => _scale = 1.0);

  void _navigate(BuildContext ctx) {
    switch (widget.routeType) {
      case _MenuRoute.words:
        Navigator.push(ctx,
            MaterialPageRoute(builder: (_) => const FlashcardScreen()));
        break;
      case _MenuRoute.review:
        Navigator.push(ctx,
            MaterialPageRoute(builder: (_) => const ReviewScreen()));
        break;
      case _MenuRoute.test:
        Navigator.push(ctx,
            MaterialPageRoute(builder: (_) => const TestScreen()));
        break;
      case _MenuRoute.grammar:
        Navigator.push(ctx,
            MaterialPageRoute(builder: (_) => const GrammarScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigate(context),
      onTapDown: _down,
      onTapUp: _up,
      onTapCancel: _cancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: widget.iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.icon,
                size: widget.iconSize,
                color: widget.iconColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// STAT TILE
////////////////////////////////////////////////////////////

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: const Offset(2, 3),
                child: Icon(icon, size: 34,
                    color: cs.onSurface.withOpacity(0.12)),
              ),
              Icon(icon, size: 34, color: color),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// BADGES
////////////////////////////////////////////////////////////

class _LevelBadge extends StatelessWidget {
  final String level;
  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white24,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      'Lv.$level',
      style: const TextStyle(color: Colors.white, fontSize: 12),
    ),
  );
}

class _StreakBadge extends StatelessWidget {
  final int streak;
  const _StreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.orange,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      '🔥 $streak',
      style: const TextStyle(color: Colors.white, fontSize: 12),
    ),
  );
}