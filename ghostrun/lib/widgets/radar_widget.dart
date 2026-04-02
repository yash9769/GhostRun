import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RadarWidget extends StatefulWidget {
  final double size;
  final bool isScanning;
  final bool isSafe;
  final bool showScanText;

  const RadarWidget({
    super.key,
    this.size = 220,
    this.isScanning = false,
    this.isSafe = false,
    this.showScanText = false,
  });

  @override
  State<RadarWidget> createState() => _RadarWidgetState();
}

class _RadarWidgetState extends State<RadarWidget>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isSafe ? AppTheme.accentGreen : AppTheme.accentBlue;
    final size = widget.size;

    return ScaleTransition(
      scale: _pulseAnim,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withOpacity(0.15),
                  width: 1.5,
                ),
              ),
            ),
            // Middle ring
            Container(
              width: size * 0.78,
              height: size * 0.78,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.bgCard.withOpacity(0.8),
                border: Border.all(
                  color: color.withOpacity(0.25),
                  width: 1.5,
                ),
              ),
            ),
            // Inner dark circle
            Container(
              width: size * 0.6,
              height: size * 0.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.bgSecondary,
              ),
            ),
            // Inner ring accent
            Container(
              width: size * 0.5,
              height: size * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            // Rotating sweep (only when scanning)
            if (widget.isScanning)
              AnimatedBuilder(
                animation: _rotationController,
                builder: (_, __) => Transform.rotate(
                  angle: _rotationController.value * 2 * pi,
                  child: CustomPaint(
                    size: Size(size * 0.6, size * 0.6),
                    painter: _SweepPainter(color: color),
                  ),
                ),
              ),
            // Center icon
            if (widget.isSafe)
              Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentGreen.withOpacity(0.2),
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: AppTheme.accentGreen,
                  size: size * 0.14,
                ),
              )
            else
              Icon(
                Icons.track_changes_rounded,
                color: color.withOpacity(0.6),
                size: size * 0.18,
              ),
            // "SCAN" label
            if (widget.showScanText)
              Positioned(
                bottom: size * 0.18,
                child: Column(
                  children: [
                    Text(
                      'SCAN',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 28,
                      height: 2,
                      color: AppTheme.accentBlue,
                    ),
                  ],
                ),
              ),
            // Small glowing dot
            if (widget.isScanning)
              AnimatedBuilder(
                animation: _rotationController,
                builder: (_, __) {
                  final angle = _rotationController.value * 2 * pi;
                  final r = (size * 0.6) / 2;
                  return Positioned(
                    left: size / 2 + r * cos(angle) - 4,
                    top: size / 2 + r * sin(angle) - 4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.8),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _SweepPainter extends CustomPainter {
  final Color color;
  _SweepPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..shader = SweepGradient(
        colors: [Colors.transparent, color.withOpacity(0.3)],
        stops: const [0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
