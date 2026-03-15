import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart' hide Route, OverlayRoute;
import 'snack_components.dart';
import 'snack_provider.dart';
import 'snack_styles.dart';

// ─────────────────────────────────────────────
//  SNACK STACKERS GAME  (Forge2DGame)
//
//  Forge2DGame camera defaults: zoom=10, anchor=center.
//  (0,0) in world coords = center of screen.
//
//  We keep the default camera and convert between
//  screen-pixel coords ↔ world (meter) coords using
//  screenToWorld() and worldToScreen().
//
//  All notifier state changes are deferred via
//  Future() macrotasks so they never collide
//  with Flutter's build phase.
// ─────────────────────────────────────────────
class SnackGame extends Forge2DGame with TapCallbacks {
  final SnackNotifier notifier;

  SnackGame({required this.notifier})
      : super(gravity: Vector2(0, 30.0));  // Fast drop speed

  @override
  Color backgroundColor() => const Color(0xFF0A0A12);

  // ── Layout (in screen pixels) ─────────────
  late double _screenW;
  late double _screenH;
  late double _platformScreenY;   // screen Y in pixels

  // ── Components ────────────────────────────
  late Dropper       _dropper;
  late HeightMeter   _meter;
  late StackBackground _bg;
  late StackPlatform   _platform;

  // ── Food bodies ───────────────────────────
  final List<FoodBody> _bodies = [];

  bool _started = false;
  bool _waitingForSettle = false;  // blocks next drop until previous settles
  double _localTimeLeft = StackConst.sessionSeconds;

  /// Defers a notifier call to a macrotask outside
  /// the frame rendering pipeline.
  void _post(void Function() fn) {
    Future(fn);
  }

  /// Convert a screen-pixel position to Forge2D world coords.
  Vector2 _toWorld(double screenX, double screenY) {
    return screenToWorld(Vector2(screenX, screenY));
  }

  // ─────────────────────────────────────────
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _screenW       = size.x;
    _screenH       = size.y;
    _platformScreenY = _screenH * (1 - StackConst.platformFromBot);

    // Grid lines — added to world so they render BEHIND physics bodies
    final zoom = camera.viewfinder.zoom;
    _bg = StackBackground(
      screenW: _screenW,
      screenH: _screenH,
      zoom: zoom,
    );
    world.add(_bg);

    // Platform (world body)
    final platWorldPos = _toWorld(_screenW / 2, _platformScreenY);
    _platform = StackPlatform(
      worldPosition: platWorldPos,
      halfW: (_screenW * StackConst.platformW / 2) / camera.viewfinder.zoom,
      halfH: (StackConst.platformH / 2) / camera.viewfinder.zoom,
      screenW: _screenW,
    );
    world.add(_platform);

    // Height meter (viewport overlay)
    _meter = HeightMeter(screenH: _screenH, platformY: _platformScreenY);
    camera.viewport.add(_meter);
  }

  void startGame() {
    _started       = true;
    _waitingForSettle = false;
    _localTimeLeft = StackConst.sessionSeconds;
    _bodies.clear();
    _post(() => notifier.startGame());
    _post(() => _spawnDropper());
  }

  void _spawnDropper() {
    final cfg = notifier.nextItem;
    if (cfg == null) return;
    _dropper = Dropper(
      screenW: _screenW,
      config:  cfg,
    )..position = Vector2(_screenW / 2, _screenH * StackConst.dropperY);
    // Dropper lives in viewport overlay (screen-pixel coords)
    camera.viewport.add(_dropper);
  }

  // ── Update loop ───────────────────────────
  @override
  void update(double dt) {
    super.update(dt);
    if (!_started) return;

    _localTimeLeft -= dt;
    if (_localTimeLeft <= 0) {
      _started = false;
      _post(() => notifier.towerFell());
      return;
    }

    _post(() => notifier.tick(dt));

    _trackHeight();
    _checkWobble();
    _checkFallen();
    _checkSettle();
  }

  // ── Height tracking (in meters) ───────────
  void _trackHeight() {
    if (_bodies.isEmpty) return;

    final zoom = camera.viewfinder.zoom;
    double topScreenY = _platformScreenY;
    for (final b in _bodies) {
      if (!b.isMounted) continue;
      final bodyWorldY = b.body.position.y;
      final bodyCenterScreenY = _screenH / 2 + bodyWorldY * zoom;
      final bodyTopScreenY = bodyCenterScreenY - (b.config.height / 2);
      if (bodyTopScreenY < topScreenY) topScreenY = bodyTopScreenY;
    }

    final heightPx = (_platformScreenY - topScreenY).clamp(0.0, 9999.0);
    // Convert pixels to meters using the camera zoom
    final heightMeters = heightPx / zoom;
    _meter.currentHeight = heightPx;
    _post(() => notifier.updateHeight(heightMeters));
  }

  // ── Wobble detection ──────────────────────
  void _checkWobble() {
    final anyWobbling = _bodies.any((b) => b.isMounted && b.isDangerouslyTilted);
    _post(() => notifier.setWobbling(anyWobbling));
  }

  // ── Fall / ground-contact detection ────────
  void _checkFallen() {
    int itemsOnPlatform = 0;
    // Platform top edge Y in world coordinates
    final platformTopWorldY = _platform.body.position.y - _platform.halfH;

    for (final b in _bodies) {
      if (!b.isMounted || !b.isSettled) continue;
      
      // Bottom edge of this food item in world coordinates
      final bodyBottomWorldY = b.body.position.y + b.halfH;

      // If the food's bottom edge is touching or below the platform's top edge
      // (Tolerance of 0.2 meters handles floating point physics penetration)
      if (bodyBottomWorldY >= platformTopWorldY - 0.2) {
        b.touchedGround = true;
        itemsOnPlatform++;
      }
    }

    if (itemsOnPlatform >= 2) {
      _started = false;
      _post(() => notifier.towerFell());
    }
  }

  // ── Settle check for one-at-a-time drops ───
  void _checkSettle() {
    if (!_waitingForSettle) return;
    // Check if the most recently dropped item has settled
    if (_bodies.isNotEmpty) {
      final last = _bodies.last;
      if (last.isMounted && last.isSettled) {
        _waitingForSettle = false;
      }
    }
  }

  // ── Tap to drop ───────────────────────────
  @override
  void onTapDown(TapDownEvent event) {
    if (!_started || _waitingForSettle) return;
    _dropItem();
  }

  void _dropItem() {
    if (!_started || _waitingForSettle) return;
    final cfg = notifier.nextItem;
    if (cfg == null) return;

    // Get dropper position in screen pixels, convert to world coords
    final dropScreenPos = _dropper.dropPosition;
    final spawnWorld = _toWorld(dropScreenPos.x, dropScreenPos.y);

    final zoom = camera.viewfinder.zoom;
    final food = FoodBody(
      config: cfg,
      spawnWorldPosition: spawnWorld,
      halfW: (cfg.width / 2) / zoom,
      halfH: (cfg.height / 2) / zoom,
    );
    _bodies.add(food);
    world.add(food);
    _waitingForSettle = true;  // Block next drop until this one settles

    _post(() => notifier.itemDropped());

    // Update dropper to next item
    _post(() {
      final nextCfg = notifier.nextItem;
      if (nextCfg != null) {
        _dropper.updateConfig(nextCfg);
      }
    });
  }
}
