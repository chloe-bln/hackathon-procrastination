import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AvatarPreview extends StatelessWidget {
  const AvatarPreview({
    super.key,
    required this.hair,
    required this.clothes,
    this.skin = 'skin_peach',
    this.size = 150,
  });

  final String hair;
  final String clothes;
  final String skin;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hairColor = switch (hair) {
      'hair_pink' => CozyColors.blush,
      'hair_bun_pink' => CozyColors.blush,
      'hair_lavender' => CozyColors.lavender,
      'hair_bun_lavender' => CozyColors.lavender,
      'hair_green' => CozyColors.sage,
      'hair_bun_green' => CozyColors.sage,
      'hair_mint' => CozyColors.mint,
      'hair_brown' => CozyColors.cocoa,
      'hair_bun_brown' => CozyColors.cocoa,
      'hair_blonde' => CozyColors.beige,
      'hair_bun_blonde' => CozyColors.beige,
      'hair_white' => CozyColors.white,
      'hair_bun_white' => CozyColors.white,
      'hair_black' => CozyColors.black,
      'hair_bun_black' => CozyColors.black,
      _ => CozyColors.mint,
    };
    final clothesColor = switch (clothes) {
      'clothes_pink' => CozyColors.blush,
      'clothes_green' => CozyColors.sage,
      'clothes_mint' => CozyColors.mint,
      'clothes_brown' => CozyColors.cocoa,
      'clothes_yellow' => CozyColors.beige,
      'clothes_white' => CozyColors.white,
      'clothes_black' => CozyColors.black,
      _ => CozyColors.lavender,
    };
    final skinColor = switch (skin) {
      'skin_porcelain' => const Color(0xFFFFE8DA),
      'skin_peach' => const Color(0xFFFFD2B6),
      'skin_warm_beige' => const Color(0xFFE9B98F),
      'skin_honey' => const Color(0xFFD89B67),
      'skin_bronze' => const Color(0xFFAD7048),
      'skin_deep' => const Color(0xFF6F4632),
      _ => const Color(0xFFFFD2B6),
    };

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: CozyColors.beige.withOpacity(0.55),
              shape: BoxShape.circle,
            ),
          ),
          Positioned(
            bottom: size * 0.16,
            child: Container(
              width: size * 0.62,
              height: size * 0.48,
              decoration: BoxDecoration(
                color: clothesColor,
                borderRadius: BorderRadius.circular(size * 0.22),
              ),
            ),
          ),
          Positioned(
            top: size * 0.23,
            child: Container(
              width: size * 0.48,
              height: size * 0.52,
              decoration: BoxDecoration(
                color: skinColor,
                borderRadius: BorderRadius.circular(size),
              ),
              child: CustomPaint(painter: _FacePainter()),
            ),
          ),
          Positioned(
            top: size * 0.18,
            child: Container(
              width: size * 0.58,
              height: size * 0.24,
              decoration: BoxDecoration(
                color: hairColor,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(size * 0.28),
                  bottom: Radius.circular(size * 0.08),
                ),
              ),
            ),
          ),
          if (hair.contains('bun'))
            Positioned(
              top: size * 0.09,
              child: Container(
                width: size * 0.22,
                height: size * 0.22,
                decoration: BoxDecoration(color: hairColor, shape: BoxShape.circle),
              ),
            ),
          Positioned(
            right: size * 0.19,
            bottom: size * 0.3,
            child: Icon(Icons.local_florist_rounded, color: CozyColors.roseText, size: size * 0.16),
          ),
        ],
      ),
    );
  }
}

class _FacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = CozyColors.black
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.36, size.height * 0.48), 3, paint);
    canvas.drawCircle(Offset(size.width * 0.64, size.height * 0.48), 3, paint);

    final smilePaint = Paint()
      ..color = CozyColors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(size.width * 0.5, size.height * 0.57), width: 24, height: 16),
      0.15,
      2.85,
      false,
      smilePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
