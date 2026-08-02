import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/constants.dart';

/// ---------- Glassmorphism card ----------
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? borderColor;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final bool glow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
    this.borderColor,
    this.gradient,
    this.onTap,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.glassBgLinear,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? AppColors.glassStroke),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.25),
                  blurRadius: 28,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: child,
    );
    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: card,
        ),
      );
    }
    return card;
  }
}

/// ---------- Progress ring ----------
class ProgressRing extends StatelessWidget {
  final double progress; // 0..1
  final double size;
  final double strokeWidth;
  final Widget child;
  final Color? color;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 120,
    this.strokeWidth = 12,
    required this.child,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final c = color ?? AppColors.zoneColor(clamped);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: clamped),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => CustomPaint(
                painter: _RingPainter(value, c, strokeWidth),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double stroke;
  _RingPainter(this.progress, this.color, this.stroke);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final bg = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bg);
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, fg);
    // glow
    if (progress >= 1.0) {
      final glow = Paint()
        ..color = color.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke + 6
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, glow);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}

/// ---------- Horizontal gradient progress bar ----------
class GradientBar extends StatelessWidget {
  final double progress; // 0..1
  final double height;
  final Color? color;

  const GradientBar({super.key, required this.progress, this.height = 10, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.zoneColor(progress);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => LinearProgressIndicator(
          value: v,
          minHeight: height,
          backgroundColor: Colors.white.withOpacity(0.10),
          valueColor: AlwaysStoppedAnimation<Color>(c),
        ),
      ),
    );
  }
}

/// ---------- Stat chip ----------
class StatChip extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color? color;

  const StatChip({super.key, required this.icon, required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: color ?? AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// ---------- Section header ----------
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const SectionHeader({super.key, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// ---------- Section title in a card ----------
class CardTitle extends StatelessWidget {
  final String text;
  final String? icon;
  const CardTitle(this.text, {this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Text(icon!, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 6),
        ],
        Text(text,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// ---------- Confetti overlay ----------
class ConfettiOverlay extends StatefulWidget {
  final Color color;
  final String? message;
  final int count;
  final VoidCallback? onDone;

  const ConfettiOverlay({super.key, this.color = AppColors.gold, this.message, this.count = 40, this.onDone});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _particles = List.generate(widget.count, (i) => _Particle(seed: i.toDouble()));
    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        widget.onDone?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_particles, _controller.value, widget.color),
        ),
      ),
    );
  }
}

class _Particle {
  final double seed;
  _Particle({required this.seed});
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;
  final Color color;

  _ConfettiPainter(this.particles, this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final palette = [color, AppColors.blue, AppColors.green, AppColors.purple, AppColors.pink];
    for (final p in particles) {
      final rnd = math.Random((p.seed * 7919).toInt());
      final x0 = size.width * rnd.nextDouble();
      final fall = t * (180 + rnd.nextDouble() * 260);
      final sway = math.sin((t * 6 + p.seed) * 2) * 30 * (0.5 + rnd.nextDouble());
      final y = -20 - rnd.nextDouble() * size.height * 0.4 + fall;
      final x = x0 + sway;
      final opacity = (1 - t).clamp(0.0, 1.0);
      final c = palette[p.seed.toInt() % palette.length].withOpacity(opacity);
      final paint = Paint()..color = c;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * 8 + p.seed);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, 8, 14), const Radius.circular(2)),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

/// ---------- Floating XP burst text ----------
class FloatingBurst extends StatefulWidget {
  final String text;
  final Color color;
  final VoidCallback? onDone;

  const FloatingBurst({super.key, required this.text, this.color = AppColors.gold, this.onDone});

  @override
  State<FloatingBurst> createState() => _FloatingBurstState();
}

class _FloatingBurstState extends State<FloatingBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _c.forward();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) widget.onDone?.call();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final v = Curves.easeOut.transform(_c.value);
          return Positioned(
            top: 90 - v * 60,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: (1 - _c.value).clamp(0.0, 1.0),
              child: Text(
                widget.text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: widget.color,
                  fontSize: 22 + v * 4,
                  fontWeight: FontWeight.w800,
                  shadows: [
                    Shadow(color: Colors.black.withOpacity(0.6), blurRadius: 12),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ---------- Animated number ----------
class AnimatedNumber extends StatelessWidget {
  final double value;
  final int decimals;
  final TextStyle style;
  const AnimatedNumber(this.value, {this.decimals = 0, this.style = const TextStyle(color: AppColors.textPrimary)});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(
        v.toStringAsFixed(decimals),
        style: style,
      ),
    );
  }
}

/// ---------- Gradient background ----------
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.bgStart, AppColors.bgEnd],
        ),
      ),
      child: child,
    );
  }
}
