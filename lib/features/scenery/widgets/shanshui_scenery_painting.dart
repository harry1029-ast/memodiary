import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/shanshui_atmosphere.dart';
import '../models/shanshui_palette.dart';
import '../models/shanshui_scenery_geometry.dart';
import 'shanshui_canvas_painter.dart';

/// Interactive stateful painting widget managing the 60 FPS animation ticker,
/// particle physics, crane flocking, lake touch ripples, and lifecycle pause.
class ShanshuiSceneryPainting extends StatefulWidget {
  final ShanshuiAtmosphereState atmosphere;
  final double aspectRatio;
  final bool fullPoem;
  final bool showCalligraphy;
  final bool? enableAmbientAnimation;
  final VoidCallback? onSceneryTap;
  final bool isVisible;

  const ShanshuiSceneryPainting({
    super.key,
    required this.atmosphere,
    this.aspectRatio = 3.0 / 2.0,
    this.fullPoem = true,
    this.showCalligraphy = true,
    this.enableAmbientAnimation,
    this.onSceneryTap,
    this.isVisible = true,
  });

  @override
  State<ShanshuiSceneryPainting> createState() => ShanshuiSceneryPaintingState();
}

class ShanshuiSceneryPaintingState extends State<ShanshuiSceneryPainting>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;
  bool get isAnimating => _controller.isAnimating;
  final List<ShanshuiParticle> _particles = [];
  final List<ShanshuiWeatherDrop> _weatherDrops = [];
  final List<ShanshuiCrane> _cranes = [];
  final List<ShanshuiRipple> _ripples = [];
  double _elapsedSeconds = 0.0;
  double _lightningAlpha = 0.0;
  double _nextLightningTime = 2.5;

  bool get _effectiveAnimate {
    if (widget.enableAmbientAnimation != null) {
      return widget.enableAmbientAnimation!;
    }
    try {
      return Platform.environment['FLUTTER_TEST'] != 'true';
    } catch (_) {
      return true;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _initParticlePools();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    );

    if (_effectiveAnimate && widget.isVisible) {
      _controller.addListener(_onTick);
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant ShanshuiSceneryPainting oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (!widget.isVisible) {
        if (_controller.isAnimating) _controller.stop();
      } else {
        if (_effectiveAnimate && !_controller.isAnimating) {
          _controller.repeat();
        }
      }
    }
  }

  void _initParticlePools() {
    final random = math.Random(42);

    // Particles (petals, fireflies, snow)
    for (int i = 0; i < 36; i++) {
      _particles.add(
        ShanshuiParticle(
          x: random.nextDouble() * 1500,
          y: random.nextDouble() * 1000,
          vx: (random.nextDouble() - 0.3) * 0.9,
          vy: 0.45 + random.nextDouble() * 0.85,
          size: 3 + random.nextDouble() * 5.5,
          angle: random.nextDouble() * math.pi * 2,
          vAngle: (random.nextDouble() - 0.5) * 0.04,
          phase: random.nextDouble() * math.pi * 2,
          colorToggle: random.nextBool(),
        ),
      );
    }

    // Weather drops (rain, snow)
    for (int i = 0; i < 80; i++) {
      _weatherDrops.add(
        ShanshuiWeatherDrop(
          x: random.nextDouble() * 1600 - 50,
          y: random.nextDouble() * 1000,
          len: 18 + random.nextDouble() * 24,
          speed: 11 + random.nextDouble() * 8,
          size: 2 + random.nextDouble() * 4.5,
          phase: random.nextDouble() * math.pi * 2,
        ),
      );
    }

    // Cranes flock
    _cranes.addAll([
      ShanshuiCrane(x: 520, y: 290, scale: 1.05, speed: 0.55, phase: 0.0, yAmp: 8, isHero: true),
      ShanshuiCrane(x: 465, y: 320, scale: 0.85, speed: 0.52, phase: 1.2, yAmp: 7, isHero: true),
      ShanshuiCrane(x: 585, y: 265, scale: 0.72, speed: 0.58, phase: 2.4, yAmp: 6, isHero: true),
      ShanshuiCrane(x: 380, y: 250, scale: 0.48, speed: 0.42, phase: 0.5, yAmp: 4, isHero: false),
      ShanshuiCrane(x: 405, y: 232, scale: 0.44, speed: 0.44, phase: 1.5, yAmp: 4, isHero: false),
      ShanshuiCrane(x: 430, y: 218, scale: 0.40, speed: 0.43, phase: 2.1, yAmp: 4, isHero: false),
      ShanshuiCrane(x: 460, y: 885, scale: 0.78, speed: 0.65, phase: 0.8, yAmp: 4, isHero: true),
      ShanshuiCrane(x: 565, y: 855, scale: 0.68, speed: 0.62, phase: 2.6, yAmp: 4, isHero: false),
    ]);
  }

  void _onTick() {
    setState(() {
      _elapsedSeconds += 0.016;
      final wind = widget.atmosphere.weather.windFactor;

      // Update cranes
      for (final crane in _cranes) {
        crane.x += crane.speed * (widget.atmosphere.weather == ShanshuiWeather.stormy ? 1.35 : 1.0);
        if (crane.x > 1560) crane.x = -60;
      }

      // Update particles
      for (final pt in _particles) {
        pt.x += (pt.vx + math.sin(_elapsedSeconds * 1.4 + pt.phase) * 0.55) * wind;
        pt.y += pt.vy * (widget.atmosphere.weather == ShanshuiWeather.stormy ? 1.8 : 1.0);
        pt.angle += pt.vAngle * wind;
        if (pt.y > 1020) {
          pt.y = -20;
          pt.x = math.Random().nextDouble() * 1500;
        }
        if (pt.x > 1520) pt.x = -20;
        if (pt.x < -20) pt.x = 1520;
      }

      // Update rain/snow drops
      final isRainy = widget.atmosphere.weather == ShanshuiWeather.rainy ||
          widget.atmosphere.weather == ShanshuiWeather.stormy;
      final isStormy = widget.atmosphere.weather == ShanshuiWeather.stormy;

      if (isRainy) {
        final slantX = isStormy ? -6.5 : -2.6;
        for (final drop in _weatherDrops) {
          drop.y += drop.speed * (isStormy ? 1.45 : 1.0);
          drop.x += slantX;
          if (drop.y > 1000) {
            drop.y = -30;
            drop.x = math.Random().nextDouble() * 1650 - 50;
          }
          if (drop.x < -50) drop.x = 1550;
        }
      } else if (widget.atmosphere.weather == ShanshuiWeather.snowy) {
        for (final drop in _weatherDrops) {
          drop.y += drop.speed * 0.14;
          drop.x += math.sin(_elapsedSeconds * 1.5 + drop.phase) * 1.1 - 0.5;
          if (drop.y > 1010) {
            drop.y = -15;
            drop.x = math.Random().nextDouble() * 1500;
          }
        }
      }

      // Lightning logic
      if (isStormy) {
        if (_elapsedSeconds > _nextLightningTime) {
          _lightningAlpha = 0.85;
          _nextLightningTime = _elapsedSeconds + 3.0 + math.Random().nextDouble() * 4.0;
        }
        if (_lightningAlpha > 0.02) {
          _lightningAlpha *= 0.88;
        }
      }

      // Update ripples
      for (final ripple in _ripples) {
        ripple.radius += 1.8;
        ripple.alpha *= 0.975;
      }
      _ripples.removeWhere((ripple) => ripple.alpha < 0.03);
    });
  }

  /// Adds a tactile water ripple in normalized (0..1500, 0..1000) canvas coordinates.
  void addRippleAtNormalized(double nx, double ny) {
    setState(() {
      _ripples.add(
        ShanshuiRipple(
          x: nx.clamp(0.0, 1500.0),
          y: math.max(615.0, ny.clamp(0.0, 1000.0)),
          radius: 4.0,
          maxRadius: 130.0,
          alpha: 0.75,
        ),
      );
    });
  }

  void _handleTapDown(TapDownDetails details, BoxConstraints constraints) {
    if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) return;
    final scaleX = 1500.0 / constraints.maxWidth;
    final scaleY = 1000.0 / constraints.maxHeight;
    final nx = details.localPosition.dx * scaleX;
    final ny = details.localPosition.dy * scaleY;
    addRippleAtNormalized(nx, ny);

    widget.onSceneryTap?.call();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_controller.isAnimating) _controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      if (_effectiveAnimate && !_controller.isAnimating) _controller.repeat();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = ShanshuiPalette.of(
      widget.atmosphere.season,
      widget.atmosphere.timeOfDay,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapDown: (details) => _handleTapDown(details, constraints),
          child: AspectRatio(
            aspectRatio: widget.aspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomPaint(
                painter: ShanshuiCanvasPainter(
                  atmosphere: widget.atmosphere,
                  palette: palette,
                  animationTime: _elapsedSeconds,
                  particles: _particles,
                  weatherDrops: _weatherDrops,
                  cranes: _cranes,
                  ripples: _ripples,
                  showCalligraphy: widget.showCalligraphy,
                  fullPoem: widget.fullPoem,
                  lightningAlpha: _lightningAlpha,
                ),
                size: Size.infinite,
              ),
            ),
          ),
        );
      },
    );
  }
}

