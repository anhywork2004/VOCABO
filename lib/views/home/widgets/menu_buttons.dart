import 'package:flutter/material.dart';

////////////////////////////////////////////////////////////
/// MENU ITEM
////////////////////////////////////////////////////////////

class MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap; // ← thêm onTap tuỳ chọn

  const MenuItem({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 28,
              color: const Color(0xFF667eea),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF555555),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// BOTTOM BAR
////////////////////////////////////////////////////////////

class BottomBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTab;

  const BottomBar({
    super.key,
    required this.currentIndex,
    required this.onTab,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BarItem(
                icon: Icons.home_rounded,
                label: "Trang chủ",
                active: currentIndex == 0,
                onTap: () => onTab(0),
              ),
              _BarItem(
                icon: Icons.calendar_month_rounded,
                label: "Lịch",
                active: currentIndex == 1,
                onTap: () => onTab(1),
              ),
              _BarItem(
                icon: Icons.add_circle_rounded,
                label: "Thêm",
                active: currentIndex == 2,
                onTap: () => onTab(2),
                featured: true,
              ),
              _BarItem(
                icon: Icons.notifications_rounded,
                label: "Thông báo",
                active: currentIndex == 3,
                onTap: () => onTab(3),
              ),
              _BarItem(
                icon: Icons.settings_rounded,
                label: "Cài đặt",
                active: currentIndex == 4,
                onTap: () => onTab(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool featured;
  final VoidCallback onTap;

  const _BarItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.featured = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? const Color(0xFF667eea)
        : Colors.grey.shade400;

    if (featured) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667eea).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded,
              color: Colors.white, size: 28),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight:
                active ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}