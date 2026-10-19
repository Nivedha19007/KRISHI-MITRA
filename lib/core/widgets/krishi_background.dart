import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Painter that renders subtle, elegant botanical leaf patterns
/// strictly along the edges and corners, keeping the center clean.
class LeafPatternPainter extends CustomPainter {
  const LeafPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Soft botanical leaves with subtle translucent shades
    final leafPaint1 = Paint()
      ..color = const Color(0xFF86EFAC).withValues(alpha: 0.16)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final leafPaint2 = Paint()
      ..color = const Color(0xFF4ADE80).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final leafVeinPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // --- TOP-LEFT CORNER BOTANICAL LEAF CLUSTER ---
    _drawCornerLeafBranch(
      canvas,
      origin: const Offset(-10, -10),
      baseAngle: math.pi / 4,
      scale: math.min(w, h) * 0.0032,
      leafPaint1: leafPaint1,
      leafPaint2: leafPaint2,
      veinPaint: leafVeinPaint,
    );

    // --- TOP-RIGHT CORNER BOTANICAL LEAF CLUSTER ---
    _drawCornerLeafBranch(
      canvas,
      origin: Offset(w + 10, -10),
      baseAngle: 3 * math.pi / 4,
      scale: math.min(w, h) * 0.0030,
      leafPaint1: leafPaint1,
      leafPaint2: leafPaint2,
      veinPaint: leafVeinPaint,
    );

    // --- BOTTOM-LEFT CORNER SUBTLE LEAF SILHOUETTE ---
    _drawCornerLeafBranch(
      canvas,
      origin: Offset(-10, h + 10),
      baseAngle: -math.pi / 4,
      scale: math.min(w, h) * 0.0028,
      leafPaint1: leafPaint1,
      leafPaint2: leafPaint2,
      veinPaint: leafVeinPaint,
    );

    // --- BOTTOM-RIGHT CORNER SUBTLE LEAF SILHOUETTE ---
    _drawCornerLeafBranch(
      canvas,
      origin: Offset(w + 10, h + 10),
      baseAngle: -3 * math.pi / 4,
      scale: math.min(w, h) * 0.0030,
      leafPaint1: leafPaint1,
      leafPaint2: leafPaint2,
      veinPaint: leafVeinPaint,
    );
  }

  void _drawCornerLeafBranch(
    Canvas canvas, {
    required Offset origin,
    required double baseAngle,
    required double scale,
    required Paint leafPaint1,
    required Paint leafPaint2,
    required Paint veinPaint,
  }) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(baseAngle);

    // Main Branch Stem
    final stemPath = Path();
    stemPath.moveTo(0, 0);
    stemPath.quadraticBezierTo(40 * scale, 10 * scale, 90 * scale, 5 * scale);
    canvas.drawPath(stemPath, veinPaint);

    // Leaf 1 (Large main leaf)
    _drawSingleLeaf(
      canvas,
      offset: Offset(80 * scale, 5 * scale),
      angle: 0.1,
      length: 50 * scale,
      width: 22 * scale,
      paint: leafPaint1,
      veinPaint: veinPaint,
    );

    // Leaf 2 (Upper side leaf)
    _drawSingleLeaf(
      canvas,
      offset: Offset(55 * scale, 5 * scale),
      angle: -0.55,
      length: 42 * scale,
      width: 18 * scale,
      paint: leafPaint2,
      veinPaint: veinPaint,
    );

    // Leaf 3 (Lower side leaf)
    _drawSingleLeaf(
      canvas,
      offset: Offset(45 * scale, 5 * scale),
      angle: 0.55,
      length: 40 * scale,
      width: 17 * scale,
      paint: leafPaint1,
      veinPaint: veinPaint,
    );

    // Leaf 4 (Small lower accent)
    _drawSingleLeaf(
      canvas,
      offset: Offset(25 * scale, 2 * scale),
      angle: -0.70,
      length: 32 * scale,
      width: 14 * scale,
      paint: leafPaint2,
      veinPaint: veinPaint,
    );

    // Leaf 5 (Small upper accent)
    _drawSingleLeaf(
      canvas,
      offset: Offset(18 * scale, 2 * scale),
      angle: 0.65,
      length: 30 * scale,
      width: 13 * scale,
      paint: leafPaint1,
      veinPaint: veinPaint,
    );

    canvas.restore();
  }

  void _drawSingleLeaf(
    Canvas canvas, {
    required Offset offset,
    required double angle,
    required double length,
    required double width,
    required Paint paint,
    required Paint veinPaint,
  }) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.rotate(angle);

    final path = Path();
    path.moveTo(0, 0);
    path.cubicTo(
      length * 0.35,
      -width * 0.65,
      length * 0.75,
      -width * 0.50,
      length,
      0,
    );
    path.cubicTo(
      length * 0.75,
      width * 0.50,
      length * 0.35,
      width * 0.65,
      0,
      0,
    );
    path.close();
    canvas.drawPath(path, paint);

    // Central vein line
    final vein = Path();
    vein.moveTo(0, 0);
    vein.quadraticBezierTo(length * 0.5, 0, length * 0.85, 0);
    canvas.drawPath(vein, veinPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A reusable full-screen background featuring a deep forest green
/// gradient with minimal, elegant corner leaf patterns.
class KrishiBackground extends StatelessWidget {
  final Widget child;

  const KrishiBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Dark-green gradient background: Deep forest green + Emerald + Subtle lighter green
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF062312), // Deep Forest Green (Top)
                Color(0xFF0C381B), // Forest Green
                Color(0xFF14532D), // Rich Emerald
                Color(0xFF166534), // Vibrant Agricultural Emerald
                Color(0xFF0F4721), // Deep Foliage
                Color(0xFF062111), // Deep Forest Green Base
              ],
              stops: [0.0, 0.20, 0.45, 0.65, 0.85, 1.0],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        // 2. Subtle, elegant leaf patterns around edges & corners (Center remains clean)
        const Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: LeafPatternPainter(),
            ),
          ),
        ),

        // 3. Child Screen Content (Transparent scaffolds & light cards sit cleanly on top)
        child,
      ],
    );
  }
}
