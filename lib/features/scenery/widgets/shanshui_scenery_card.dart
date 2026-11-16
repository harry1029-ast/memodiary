import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../../../core/utils/ambient_animation_utils.dart';
import '../models/shanshui_atmosphere.dart';
import '../services/scenery_settings_service.dart';
import 'bamboo_blind_collapsed_bar.dart';
import 'bamboo_blind_pull_cord.dart';
import 'scenery_realm_switcher.dart';
import 'scenery_window_frame.dart';
import 'shanshui_scenery_painting.dart';
import 'xiangfei_bamboo_blind.dart';

enum _BlindTransitionMode { idle, closing, opening }

/// Primary composite timeline header card framed as an unobstructed 16:9
/// recessed Jiangnan wooden study window (`轩窗`).
///
/// Features the hanging braided-silk **Bamboo Blind Pull-Cord** (`竹帘流苏拉绳`)
/// at the top-left, which unrolls the slatted **Xiangfei Bamboo Blind (`湘妃竹帘`)**
/// and collapses into a `44dp` bamboo-slat bar (`竹帘低垂`) with reversed
/// two-stage expand choreography.
class ShanshuiSceneryCard extends StatefulWidget {
  final ShanshuiAtmosphereState atmosphere;
  final ShanshuiAtmosphereState? realTimeAtmosphere;
  final VoidCallback onOpenContemplation;
  final ScenerySettingsService? settingsService;
  final bool? enableAmbientAnimation;
  final bool isVisible;
  final ValueChanged<SceneryRealmPreference>? onRealmPreferenceChanged;

  const ShanshuiSceneryCard({
    super.key,
    required this.atmosphere,
    this.realTimeAtmosphere,
    required this.onOpenContemplation,
    this.settingsService,
    this.enableAmbientAnimation,
    this.isVisible = true,
    this.onRealmPreferenceChanged,
  });

  @override
  State<ShanshuiSceneryCard> createState() => _ShanshuiSceneryCardState();
}

class _ShanshuiSceneryCardState extends State<ShanshuiSceneryCard>
    with TickerProviderStateMixin {
  late final ScenerySettingsService _settingsService;
  late final AnimationController _transitionController;
  late final AnimationController _springBackController;

  bool _isCollapsed = false;
  _BlindTransitionMode _transitionMode = _BlindTransitionMode.idle;
  ShanshuiAtmosphereState? _localAtmosphere;

  bool _isDragging = false;
  double? _dragStartGlobalY;
  double _dragDelta = 0.0;
  double _springStartDelta = 0.0;
  double _blindStartProgress = 0.0;
  double _cordStartLength = BambooBlindPullCord.restingCordLength;

  ShanshuiAtmosphereState get _effectiveAtmosphere =>
      _localAtmosphere ?? widget.atmosphere;

  bool get _effectiveAnimate =>
      shouldRunAmbientAnimation(widget.enableAmbientAnimation);

  @override
  void initState() {
    super.initState();
    _settingsService = widget.settingsService ?? ScenerySettingsService();
    _transitionController = AnimationController(
      vsync: this,
      duration: BambooBlindChoreography.closeDuration,
    )..addStatusListener(_onTransitionStatusChanged);
    _springBackController = AnimationController(
      vsync: this,
      duration: BambooBlindChoreography.springBackDuration,
    )
      ..addListener(_onSpringBackTick)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _dragDelta = 0.0);
        }
      });
    _loadCollapsedPreference();
  }

  @override
  void didUpdateWidget(ShanshuiSceneryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.atmosphere != oldWidget.atmosphere ||
        widget.realTimeAtmosphere != oldWidget.realTimeAtmosphere) {
      _localAtmosphere = null;
    }
  }

  @override
  void dispose() {
    _transitionController.dispose();
    _springBackController.dispose();
    super.dispose();
  }

  Future<void> _loadCollapsedPreference() async {
    final collapsed = await _settingsService.getIsCollapsed();
    if (mounted && collapsed != _isCollapsed) {
      setState(() {
        _isCollapsed = collapsed;
        _transitionMode = _BlindTransitionMode.idle;
      });
    }
  }

  void _onSpringBackTick() {
    if (!mounted) return;
    final eased = BambooBlindChoreography.curve.transform(
      _springBackController.value,
    );
    setState(() => _dragDelta = _springStartDelta * (1.0 - eased));
  }

  void _onTransitionStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    setState(() {
      if (_transitionMode == _BlindTransitionMode.closing) {
        _isCollapsed = true;
      } else if (_transitionMode == _BlindTransitionMode.opening) {
        _isCollapsed = false;
      }
      _transitionMode = _BlindTransitionMode.idle;
      _dragDelta = 0.0;
      _blindStartProgress = 0.0;
    });
  }

  void _triggerCloseChoreography() {
    if (_transitionMode != _BlindTransitionMode.idle || _isCollapsed) return;
    _springBackController.stop();
    unawaited(_settingsService.setIsCollapsed(true));

    if (MediaQuery.maybeDisableAnimationsOf(context) == true) {
      setState(() {
        _isCollapsed = true;
        _isDragging = false;
        _dragDelta = 0.0;
        _transitionMode = _BlindTransitionMode.idle;
      });
      return;
    }

    setState(() {
      _isDragging = false;
      _blindStartProgress =
          (_dragDelta / BambooBlindPullCord.maxDragDelta).clamp(0.0, 1.0);
      _cordStartLength = BambooBlindPullCord.restingCordLength + _dragDelta;
      _transitionMode = _BlindTransitionMode.closing;
      _transitionController.duration = BambooBlindChoreography.closeDuration;
    });
    _transitionController.forward(from: 0.0);
  }

  void _triggerOpenChoreography() {
    if (_transitionMode != _BlindTransitionMode.idle || !_isCollapsed) return;
    unawaited(_settingsService.setIsCollapsed(false));

    if (MediaQuery.maybeDisableAnimationsOf(context) == true) {
      setState(() {
        _isCollapsed = false;
        _dragDelta = 0.0;
        _transitionMode = _BlindTransitionMode.idle;
      });
      return;
    }

    setState(() {
      _isCollapsed = false;
      _dragDelta = 0.0;
      _transitionMode = _BlindTransitionMode.opening;
      _transitionController.duration = BambooBlindChoreography.openDuration;
    });
    _transitionController.forward(from: 0.0);
  }

  void _handleCordDragStart(double? initialGlobalY) {
    if (_transitionMode != _BlindTransitionMode.idle || _isCollapsed) return;
    _springBackController.stop();
    setState(() {
      _isDragging = true;
      _dragStartGlobalY = initialGlobalY;
      _dragDelta = 0.0;
    });
  }

  void _handleCordDragUpdate(DragUpdateDetails details) {
    if (!_isDragging || _transitionMode != _BlindTransitionMode.idle) return;
    final startY = _dragStartGlobalY;
    final nextDelta = startY != null
        ? (details.globalPosition.dy - startY)
            .clamp(0.0, BambooBlindPullCord.maxDragDelta)
        : (_dragDelta + details.delta.dy)
            .clamp(0.0, BambooBlindPullCord.maxDragDelta);
    if (nextDelta != _dragDelta) {
      setState(() => _dragDelta = nextDelta);
    }
  }

  void _handleCordDragEnd() {
    if (!_isDragging) return;
    final releaseDelta = _dragDelta;
    _dragStartGlobalY = null;

    if (releaseDelta < BambooBlindPullCord.tapJitterDelta ||
        releaseDelta >= BambooBlindPullCord.triggerDragDelta) {
      _triggerCloseChoreography();
      return;
    }

    setState(() {
      _isDragging = false;
      _springStartDelta = releaseDelta;
    });
    _springBackController.forward(from: 0.0);
  }

  void _openRealmSwitcher(InkDiaryTokens tokens) {
    showSceneryRealmSwitcherSheet(
      context: context,
      tokens: tokens,
      settingsService: _settingsService,
      onSelected: (preference) {
        if (mounted) {
          setState(() {
            if (preference == SceneryRealmPreference.auto) {
              final target = widget.realTimeAtmosphere ?? widget.atmosphere;
              _localAtmosphere = widget.atmosphere.copyWith(
                realm: target.realm,
                isJournalInferred: target.isJournalInferred,
              );
            } else {
              final realm = switch (preference) {
                SceneryRealmPreference.nature => ShanshuiRealm.nature,
                SceneryRealmPreference.indoor => ShanshuiRealm.indoor,
                SceneryRealmPreference.outdoor => ShanshuiRealm.outdoor,
                SceneryRealmPreference.auto => ShanshuiRealm.nature,
              };
              _localAtmosphere = widget.atmosphere.copyWith(
                realm: realm,
                isJournalInferred: false,
              );
            }
          });
        }
        widget.onRealmPreferenceChanged?.call(preference);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<InkDiaryTokens>() ?? InkDiaryTokens.light;

    final Widget child;
    if (_isCollapsed && _transitionMode == _BlindTransitionMode.idle) {
      child = BambooBlindCollapsedBar(
        atmosphere: _effectiveAtmosphere,
        tokens: tokens,
        realmBadge: SceneryRealmBadge(
          atmosphere: _effectiveAtmosphere,
          tokens: tokens,
          isCollapsed: true,
          onTap: () => _openRealmSwitcher(tokens),
        ),
        onExpand: _triggerOpenChoreography,
      );
    } else {
      child = _buildExpandedWindow(tokens);
    }

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: child,
    );
  }

  Widget _buildExpandedWindow(InkDiaryTokens tokens) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 400.0;
        final expandedHeight = maxWidth <= 500
            ? maxWidth * 9.0 / 16.0
            : (maxWidth * 9.0 / 16.0).clamp(180.0, 240.0);

        return AnimatedBuilder(
          animation: _transitionController,
          builder: (context, staticLayer) {
            final isClosing = _transitionMode == _BlindTransitionMode.closing;
            final isOpening = _transitionMode == _BlindTransitionMode.opening;
            final progress = _transitionController.value;

            final currentHeight = BambooBlindChoreography.windowHeight(
              expandedHeight: expandedHeight,
              isClosing: isClosing,
              isOpening: isOpening,
              progress: progress,
            );
            final blindProgress = BambooBlindChoreography.blindProgress(
              isClosing: isClosing,
              isOpening: isOpening,
              progress: progress,
              blindStartProgress: _blindStartProgress,
              dragDelta: _dragDelta,
            );
            final cordLength = BambooBlindChoreography.cordLength(
              isClosing: isClosing,
              progress: progress,
              cordStartLength: _cordStartLength,
              dragDelta: _dragDelta,
            );
            final isTransitioning = _transitionMode != _BlindTransitionMode.idle;

            return SizedBox(
              key: const Key('scenery_card_expanded'),
              width: double.infinity,
              height: currentHeight,
              child: SceneryWindowFrame(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (staticLayer != null) staticLayer,
                    if (currentHeight > 72.0)
                      SceneryWindowOverlayStrip(
                        atmosphere: _effectiveAtmosphere,
                        tokens: tokens,
                        maxWidth: maxWidth,
                        realmBadge: SceneryRealmBadge(
                          atmosphere: _effectiveAtmosphere,
                          tokens: tokens,
                          onTap: () => _openRealmSwitcher(tokens),
                        ),
                      ),
                    if (blindProgress > 0.0)
                      IgnorePointer(
                        child: XiangfeiBambooBlind(progress: blindProgress),
                      ),
                    if (currentHeight > 96.0)
                      Positioned(
                        top: 2,
                        left: 6,
                        child: BambooBlindPullCord(
                          cordLength: cordLength,
                          dragDelta: _dragDelta,
                          isDragging: _isDragging,
                          isTransitioning: isTransitioning,
                          isVisible: widget.isVisible,
                          enableAmbientAnimation: _effectiveAnimate,
                          onTap: _triggerCloseChoreography,
                          onDragStart: _handleCordDragStart,
                          onDragUpdate: _handleCordDragUpdate,
                          onDragEnd: _handleCordDragEnd,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              ShanshuiSceneryPainting(
                atmosphere: _effectiveAtmosphere,
                aspectRatio: maxWidth / expandedHeight,
                fullPoem: false,
                showCalligraphy: false,
                enableAmbientAnimation: widget.enableAmbientAnimation,
                isVisible: widget.isVisible,
              ),
              Positioned.fill(
                child: Semantics(
                  button: true,
                  label: '进入沉浸山水画卷',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: const Key('scenery_canvas_tap_target'),
                      onTap: widget.onOpenContemplation,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
