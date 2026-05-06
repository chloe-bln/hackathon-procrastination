import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FlowerDecoration extends StatelessWidget {
  const FlowerDecoration({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < 6; i++)
            Transform.rotate(
              angle: i * 0.95,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: size * 0.22,
                  height: size * 0.38,
                  decoration: BoxDecoration(
                    color: i.isEven ? CozyColors.blush : CozyColors.lavender,
                    borderRadius: BorderRadius.circular(size),
                  ),
                ),
              ),
            ),
          Container(
            width: size * 0.24,
            height: size * 0.24,
            decoration: const BoxDecoration(color: CozyColors.beige, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}
