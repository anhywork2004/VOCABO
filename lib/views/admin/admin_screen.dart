import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dashboard_screen.dart';
import 'manage_users_screen.dart';
import 'manage_words_screen.dart';
import 'notification_screen_admin.dart';

// ─── Admin Screen với Drawer slide-left ───────────────────────────────────────

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _index = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _menu = [
    _MenuItem(Icons.dashboard_rounded,       'Dashboard',    'Tổng quan hệ thống'),
    _MenuItem(Icons.people_alt_rounded,      'Người dùng',   'Quản lý tài khoản'),
    _MenuItem(Icons.menu_book_rounded,       'Chủ đề',       'Quản lý từ vựng'),
    _MenuItem(Icons.campaign_rounded,        'Thông báo',    'Gửi thông báo'),
  ];

  final _pages = const [
    DashboardScreen(),
    ManageUserScreen(),
    ManageWordsScreen(),
    AdminNotificationScreen(),
  ];

  void _navigate(int i) {
    setState(() => _index = i);
    _scaffoldKey.currentState?.closeDrawer();
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đăng xuất?'),
        content: const Text('Bạn có chắc muốn thoát khỏi Admin Panel?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: cs.surface,

      // ── AppBar ──────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _menu[_index].label,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700),
            ),
            Text(
              _menu[_index].subtitle,
              style: const TextStyle(
                  fontSize: 11, color: Colors.white60),
            ),
          ],
        ),
        actions: [
          // Avatar admin
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
              child: _AdminAvatar(),
            ),
          ),
        ],
      ),

      // ── Drawer slide-left ────────────────────────────────
      drawer: _AdminDrawer(
        selectedIndex: _index,
        menu: _menu,
        onSelect: _navigate,
        onLogout: _logout,
      ),

      // ── Body ─────────────────────────────────────────────
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: KeyedSubtree(
          key: ValueKey(_index),
          child: _pages[_index],
        ),
      ),
    );
  }
}

// ─── Drawer ───────────────────────────────────────────────────────────────────

class _AdminDrawer extends StatelessWidget {
  final int              selectedIndex;
  final List<_MenuItem>  menu;
  final ValueChanged<int> onSelect;
  final VoidCallback     onLogout;

  const _AdminDrawer({
    required this.selectedIndex,
    required this.menu,
    required this.onSelect,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      width: 280,
      backgroundColor: const Color(0xFF1A1A2E),
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                children: [
                  // Logo
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667eea).withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Admin Panel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'VOCABO',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),

            // Admin info card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null,
                    backgroundColor: const Color(0xFF667eea),
                    child: user?.photoURL == null
                        ? const Icon(Icons.person,
                            color: Colors.white, size: 20)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'Admin',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Admin',
                      style: TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Menu items ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 8),
                    child: Text(
                      'MENU',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  ...List.generate(menu.length, (i) {
                    final item     = menu[i];
                    final selected = selectedIndex == i;
                    return _DrawerItem(
                      icon:     item.icon,
                      label:    item.label,
                      selected: selected,
                      onTap:    () => onSelect(i),
                    );
                  }),
                ],
              ),
            ),

            const Spacer(),

            // ── Divider ──────────────────────────────────
            Divider(color: Colors.white.withOpacity(0.08),
                indent: 16, endIndent: 16),

            // ── Logout ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
              child: _DrawerItem(
                icon:     Icons.logout_rounded,
                label:    'Đăng xuất',
                selected: false,
                onTap:    onLogout,
                color:    Colors.red.shade300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Drawer Item ──────────────────────────────────────────────────────────────

class _DrawerItem extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final bool         selected;
  final VoidCallback onTap;
  final Color?       color;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fg = color ?? (selected ? Colors.white : Colors.white60);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF667eea).withOpacity(0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: selected
              ? Border.all(
                  color: const Color(0xFF667eea).withOpacity(0.4))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF667eea).withOpacity(0.3)
                    : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: fg, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 14,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
            if (selected) ...[
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF667eea),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Admin Avatar ─────────────────────────────────────────────────────────────

class _AdminAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return CircleAvatar(
      radius: 18,
      backgroundImage:
          user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
      backgroundColor: const Color(0xFF667eea),
      child: user?.photoURL == null
          ? const Icon(Icons.person, color: Colors.white, size: 18)
          : null,
    );
  }
}

// ─── Menu Item Model ──────────────────────────────────────────────────────────

class _MenuItem {
  final IconData icon;
  final String   label;
  final String   subtitle;
  const _MenuItem(this.icon, this.label, this.subtitle);
}
