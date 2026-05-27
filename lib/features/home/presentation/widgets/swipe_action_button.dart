import 'package:flutter/material.dart';

class SwipeActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const SwipeActionButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: const CircleBorder(),
      color: Colors.grey.shade900,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 68,
          height: 68,
          child: Icon(
            icon,
            size: 34,
          ),
        ),
      ),
    );
  }
}
