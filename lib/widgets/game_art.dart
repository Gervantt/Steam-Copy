import 'dart:math';

import 'package:flutter/material.dart';

import '../models/game.dart';

/// Cover art drawn from the game's palette, so covers need no network
/// images (which Flutter web can't load from most hosts without CORS).
class GameArt extends StatelessWidget {
  final Game game;

  const GameArt({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _ArtPainter(game.palette, game.artStyle, game.id.hashCode),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ArtPainter extends CustomPainter {
  final List<Color> palette;
  final ArtStyle style;
  final int seed;

  _ArtPainter(this.palette, this.style, this.seed);

  Color get sky => palette[0];
  Color get ground => palette[1];
  Color get light => palette[2];

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [sky, ground],
        ).createShader(rect),
    );

    switch (style) {
      case ArtStyle.sun:
        _glow(canvas, Offset(size.width * 0.62, size.height * 0.38),
            size.shortestSide * 0.5);
        _ridge(canvas, size, 0.62, darken(ground, 0.45), peak: 0.4);
      case ArtStyle.mountains:
        _glow(canvas, Offset(size.width * 0.3, size.height * 0.2),
            size.shortestSide * 0.35);
        _ridge(canvas, size, 0.55, darken(sky, 0.15), peak: 0.7);
        _ridge(canvas, size, 0.7, darken(ground, 0.25), peak: 0.3);
      case ArtStyle.lanterns:
        _ridge(canvas, size, 0.72, darken(ground, 0.4), peak: 0.2);
        final Random r = Random(seed);
        for (int i = 0; i < 5; i++) {
          final Offset c = Offset(
            size.width * (0.1 + 0.8 * r.nextDouble()),
            size.height * (0.15 + 0.5 * r.nextDouble()),
          );
          _glow(canvas, c, size.shortestSide * 0.12);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: c, width: 6, height: 9),
              const Radius.circular(2),
            ),
            Paint()..color = light,
          );
        }
      case ArtStyle.streaks:
        final Paint p = Paint()
          ..strokeWidth = size.shortestSide * 0.02
          ..strokeCap = StrokeCap.round;
        final Random r = Random(seed);
        for (int i = 0; i < 7; i++) {
          final double x = size.width * r.nextDouble();
          p.color = light.withValues(alpha: 0.25 + 0.5 * r.nextDouble());
          canvas.drawLine(
            Offset(x, size.height),
            Offset(x + size.width * 0.5, 0),
            p,
          );
        }
      case ArtStyle.glow:
        _glow(canvas, Offset(size.width * 0.5, size.height * 0.45),
            size.shortestSide * 0.6);
        final Paint lines = Paint()
          ..color = light.withValues(alpha: 0.12)
          ..strokeWidth = 1;
        for (double y = size.height * 0.1; y < size.height; y += 6) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), lines);
        }
      case ArtStyle.waves:
        _glow(canvas, Offset(size.width * 0.3, size.height * 0.3),
            size.shortestSide * 0.4);
        for (int i = 0; i < 3; i++) {
          _wave(canvas, size, 0.6 + i * 0.12, darken(ground, 0.15 + i * 0.15));
        }
    }
  }

  void _glow(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [light, light.withValues(alpha: 0.35), light.withValues(alpha: 0)],
          stops: const [0, 0.25, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  void _ridge(Canvas canvas, Size size, double base, Color color,
      {required double peak}) {
    final double h = size.height;
    final Path path = Path()
      ..moveTo(0, h * base)
      ..lineTo(size.width * peak, h * (base - 0.28))
      ..lineTo(size.width, h * (base - 0.05))
      ..lineTo(size.width, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _wave(Canvas canvas, Size size, double base, Color color) {
    final double h = size.height;
    final Path path = Path()..moveTo(0, h * base);
    for (double x = 0; x <= size.width; x += 4) {
      path.lineTo(x, h * base + sin(x / size.width * pi * 3 + base * 10) * h * 0.04);
    }
    path
      ..lineTo(size.width, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  static Color darken(Color c, double amount) =>
      Color.lerp(c, const Color(0xFF000000), amount)!;

  @override
  bool shouldRepaint(_ArtPainter old) =>
      old.style != style || old.palette != palette;
}
