import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'ThemeProvider.dart';
import '../../routes/app_routes.dart';
import '../profile/profile_screen.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool   notification = true;
  bool   isLoading    = true;
  final  user = FirebaseAuth.instance.currentUser;
  String _displayName = '';
  String _photoURL    = '';

  bool get _isGoogleUser =>
      user?.providerData.any((p) => p.providerId == 'google.com') ?? false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users').doc(user!.uid).get();
      if (doc.exists) {
        final d = doc.data() ?? {};
        setState(() {
          notification = d['notification'] ?? true;
          _displayName = d['displayName'] ?? d['name'] ?? user?.displayName ?? '';
          _photoURL    = d['photoURL']    ?? d['photoUrl'] ?? user?.photoURL ?? '';
        });
      } else {
        _displayName = user?.displayName ?? '';
        _photoURL    = user?.photoURL    ?? '';
      }
    } catch (_) {
      _displayName = user?.displayName ?? '';
      _photoURL    = user?.photoURL    ?? '';
    }
    setState(() => isLoading = false);
  }

  Future<void> _saveNotification(bool v) async {
    await FirebaseFirestore.instance
        .collection('users').doc(user!.uid)
        .set({'notification': v}, SetOptions(merge: true));
  }

  void _goToProfile() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const ProfileScreen()));

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đăng xuất?'),
        content: const Text('Bạn có chắc muốn đăng xuất không?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Đăng xuất',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final themeProvider = context.watch<ThemeProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text(
          'Cài đặt',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: cs.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: cs.outline.withOpacity(0.1)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [

          // ── USER CARD ──────────────────────────────────
          _UserCard(
            displayName: _displayName,
            email:       user?.email ?? '',
            photoURL:    _photoURL,
            isGoogle:    _isGoogleUser,
            onTap:       _goToProfile,
          ),

          const SizedBox(height: 24),

          // ── GENERAL ────────────────────────────────────
          _SectionLabel(label: 'Chung'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _SwitchTile(
                icon:    Icons.notifications_rounded,
                iconBg:  Colors.orange,
                title:   'Thông báo',
                value:   notification,
                onChanged: (v) async {
                  setState(() => notification = v);
                  await _saveNotification(v);
                },
              ),
              _Divider(),
              _SwitchTile(
                icon:    themeProvider.isDark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                iconBg:  themeProvider.isDark
                    ? const Color(0xFF667eea)
                    : Colors.amber,
                title:   'Chế độ tối',
                value:   themeProvider.isDark,
                onChanged: (v) => context.read<ThemeProvider>().setDark(v),
              ),
              _Divider(),
              _ArrowTile(
                icon:   Icons.language_rounded,
                iconBg: Colors.teal,
                title:  'Ngôn ngữ',
                onTap:  _showLanguageDialog,
              ),
              _Divider(),
              _ArrowTile(
                icon:   Icons.sync_rounded,
                iconBg: const Color(0xFF667eea),
                title:  'Đồng bộ dữ liệu',
                onTap:  () async {
                  await _saveNotification(notification);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Đồng bộ thành công'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── ACCOUNT ────────────────────────────────────
          _SectionLabel(label: 'Tài khoản'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _ArrowTile(
                icon:   Icons.bar_chart_rounded,
                iconBg: Colors.green,
                title:  'Thống kê học tập',
                onTap:  () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Coming soon'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.all(16),
                  ),
                ),
              ),
              if (!_isGoogleUser) ...[
                _Divider(),
                _ArrowTile(
                  icon:   Icons.lock_rounded,
                  iconBg: Colors.purple,
                  title:  'Đổi mật khẩu',
                  onTap:  _goToProfile,
                ),
              ],
              _Divider(),
              _ArrowTile(
                icon:   Icons.help_outline_rounded,
                iconBg: Colors.blue,
                title:  'Trợ giúp & Hỗ trợ',
                onTap:  () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Help page'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.all(16),
                  ),
                ),
              ),
              _Divider(),
              _ArrowTile(
                icon:   Icons.info_outline_rounded,
                iconBg: Colors.grey,
                title:  'Về ứng dụng',
                onTap:  () => showAboutDialog(
                  context: context,
                  applicationName: 'Vocabo',
                  applicationVersion: '1.0.0',
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ── LOGOUT ─────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text(
                'Đăng xuất',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade500,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ngôn ngữ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
                title: const Text('Tiếng Việt'),
                onTap: () => Navigator.pop(context)),
            ListTile(
                title: const Text('English'),
                onTap: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}

// ─── User Card ────────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final String      displayName;
  final String      email;
  final String      photoURL;
  final bool        isGoogle;
  final VoidCallback onTap;
  const _UserCard({
    required this.displayName,
    required this.email,
    required this.photoURL,
    required this.isGoogle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Hero(
              tag: 'user_avatar',
              child: CircleAvatar(
                radius: 28,
                backgroundColor: cs.primary.withOpacity(0.2),
                backgroundImage:
                    photoURL.isNotEmpty ? NetworkImage(photoURL) : null,
                child: photoURL.isEmpty
                    ? Icon(Icons.person_rounded,
                        color: cs.primary, size: 28)
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName.isNotEmpty ? displayName : email,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onPrimaryContainer.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isGoogle
                          ? Colors.blue.withOpacity(0.15)
                          : cs.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isGoogle
                              ? Icons.g_mobiledata
                              : Icons.email_outlined,
                          size: 12,
                          color: isGoogle ? Colors.blue : cs.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isGoogle ? 'Google' : 'Email',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isGoogle ? Colors.blue : cs.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14,
                color: cs.onPrimaryContainer.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── Settings Card ────────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }
}

// ─── Divider ──────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 56,
      endIndent: 0,
      color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
    );
  }
}

// ─── Switch Tile ──────────────────────────────────────────────────────────────

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color    iconBg;
  final String   title;
  final bool     value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _IconBox(icon: icon, color: iconBg),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF667eea),
          ),
        ],
      ),
    );
  }
}

// ─── Arrow Tile ───────────────────────────────────────────────────────────────

class _ArrowTile extends StatelessWidget {
  final IconData     icon;
  final Color        iconBg;
  final String       title;
  final VoidCallback onTap;
  final String?      subtitle;
  const _ArrowTile({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _IconBox(icon: icon, color: iconBg),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14,
                color: cs.onSurface.withOpacity(0.35)),
          ],
        ),
      ),
    );
  }
}

// ─── Icon Box ─────────────────────────────────────────────────────────────────

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color    color;
  const _IconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}
