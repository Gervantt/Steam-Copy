import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Dark scrim with a transparent square cut-out, accent corner brackets
/// and a scan line that moves up and down inside the cut-out.
class QrScannerOverlay extends StatefulWidget {
  final double cutOutSize;

  const QrScannerOverlay({super.key, this.cutOutSize = 260});

  @override
  State<QrScannerOverlay> createState() => _QrScannerOverlayState();
}

class _QrScannerOverlayState extends State<QrScannerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController scanLine = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    scanLine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double size = widget.cutOutSize;

    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: _ScrimPainter(cutOutSize: size)),
        Center(
          child: SizedBox.square(
            dimension: size,
            child: AnimatedBuilder(
              animation: scanLine,
              builder: (context, _) {
                final double t = Curves.easeInOut.transform(scanLine.value);
                return Stack(
                  children: [
                    Positioned(
                      left: 16,
                      right: 16,
                      top: 12 + t * (size - 24),
                      child: const _ScanLine(),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ScanLine extends StatelessWidget {
  const _ScanLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0),
            AppColors.accent,
            AppColors.accent.withValues(alpha: 0),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.6),
            blurRadius: 12,
          ),
        ],
      ),
    );
  }
}

class _ScrimPainter extends CustomPainter {
  final double cutOutSize;

  static const double radius = 24;
  static const double bracketLength = 40;
  static const double bracketWidth = 4;

  const _ScrimPainter({required this.cutOutSize});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect hole = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: cutOutSize,
      height: cutOutSize,
    );
    final RRect holeRRect = RRect.fromRectAndRadius(
      hole,
      const Radius.circular(radius),
    );

    final Path scrim = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRRect(holeRRect),
    );
    canvas.drawPath(scrim, Paint()..color = const Color(0x99000000));

    final Paint bracket = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = bracketWidth
      ..strokeCap = StrokeCap.round;

    // Each corner: a short horizontal run, the rounded corner, a vertical run.
    final double l = hole.left, t = hole.top, r = hole.right, b = hole.bottom;
    const double len = bracketLength, rad = radius;
    final List<Path> corners = [
      Path()
        ..moveTo(l, t + len)
        ..lineTo(l, t + rad)
        ..arcToPoint(Offset(l + rad, t), radius: const Radius.circular(rad))
        ..lineTo(l + len, t),
      Path()
        ..moveTo(r - len, t)
        ..lineTo(r - rad, t)
        ..arcToPoint(Offset(r, t + rad), radius: const Radius.circular(rad))
        ..lineTo(r, t + len),
      Path()
        ..moveTo(r, b - len)
        ..lineTo(r, b - rad)
        ..arcToPoint(Offset(r - rad, b), radius: const Radius.circular(rad))
        ..lineTo(r - len, b),
      Path()
        ..moveTo(l + len, b)
        ..lineTo(l + rad, b)
        ..arcToPoint(Offset(l, b - rad), radius: const Radius.circular(rad))
        ..lineTo(l, b - len),
    ];
    for (final Path corner in corners) {
      canvas.drawPath(corner, bracket);
    }
  }

  @override
  bool shouldRepaint(_ScrimPainter oldDelegate) =>
      oldDelegate.cutOutSize != cutOutSize;
}
