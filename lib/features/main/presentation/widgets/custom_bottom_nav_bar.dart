import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final int unreadChatsCount;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.unreadChatsCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    const navItems = [
      {
        'icon': Icons.local_fire_department,
        'label': 'Анкеты',
        'activeColor': Color(0xFFFF6B6B),
      },
      {
        'icon': Icons.favorite,
        'label': 'Матчи',
        'activeColor': Color(0xFFFF1744),
      },
      {
        'icon': Icons.message,
        'label': 'Чаты',
        'activeColor': Color(0xFFFFFFFF),
      },
      {
        'icon': Icons.person,
        'label': 'Профиль',
        'activeColor': Color(0xFFFFD700),
      },
    ];

    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(
          top: BorderSide(
            color: Color(0xFF222E3A),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          navItems.length,
          (index) {
            final item = navItems[index];
            final isActive = index == currentIndex;
            final color = isActive
                ? item['activeColor'] as Color
                : const Color(0xFF666666);

            Widget iconWidget = Icon(
              item['icon'] as IconData,
              color: color,
              size: 28,
            );

            // Добавляем счетчик для вкладки Чаты
            if (index == 2 && unreadChatsCount > 0) {
              iconWidget = Stack(
                children: [
                  iconWidget,
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.pink,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadChatsCount.toString(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              );
            }

            return GestureDetector(
              onTap: () => onTap(index),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  iconWidget,
                  const SizedBox(height: 4),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
