import 'package:flutter/material.dart';
import '../../../../core/theme/luxury_theme.dart';

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
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: LuxuryPanel(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        radius: 28,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(4, (index) {
            final isActive = index == currentIndex;
            final color = isActive ? LuxuryColors.gold : const Color(0xFFB7B7B7);
            final icon = _buildIcon(index, color);

            return GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 54,
                height: 42,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isActive)
                      Container(
                        width: 48,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [LuxuryColors.gold.withOpacity(0.28), Colors.transparent],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    index == 2 && unreadChatsCount > 0
                        ? Stack(
                            clipBehavior: Clip.none,
                            children: [
                              icon,
                              Positioned(
                                right: -8,
                                top: -7,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: LuxuryColors.gold, shape: BoxShape.circle),
                                  child: Text(
                                    unreadChatsCount.toString(),
                                    style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : icon,
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildIcon(int index, Color color) {
    switch (index) {
      case 0:
        return Image.asset(
          'assets/icons/fire.png',
          color: color,
          width: 30,
          height: 30,
        );
      case 1:
        return Icon(Icons.favorite_border, color: color, size: 30);
      case 2:
        return Image.asset(
          'assets/icons/chat.png',
          color: color,
          width: 30,
          height: 30,
        );
      case 3:
        return Image.asset(
          'assets/icons/person.png',
          color: color,
          width: 30,
          height: 30,
        );
      default:
        return const SizedBox();
    }
  }
}
