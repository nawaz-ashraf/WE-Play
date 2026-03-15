import 'package:flame/components.dart' show Anchor;
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:flutter/services.dart' show HapticFeedback;
import 'flick_ai.dart';
import 'flick_components.dart';
import 'flick_provider.dart';
import 'flick_styles.dart';

// ─────────────────────────────────────────────
//  FLICK ROYALE GAME  (Forge2DGame)
// ─────────────────────────────────────────────
class FlickGame extends Forge2DGame with DragCallbacks {
  final FlickNotifier notifier;

  FlickGame({required this.notifier})
      : super(gravity: Vector2.zero()); // top-down = no gravity

  // ── Layout ────────────────────────────────
  late double _screenW, _screenH;
  late double _arenaL, _arenaR, _arenaT, _arenaB;
  late double _centreY;

  // ── Components ────────────────────────────
  late ArenaRenderer _arenaRenderer;
  late AimLine       _aimLine;
  final List<PuckBody> _playerPucks = [];
  final List<PuckBody> _aiPucks     = [];
  int _puckIdCounter = 0;

  // ── Drag state ────────────────────────────
  PuckBody? _dragPuck;
  Vector2?  _dragStart;

  // ── AI ────────────────────────────────────
  late AiController _ai;

  bool _started = false;

  /// Defers a notifier call to after the current frame's
  /// build / layout phase is complete.
  void _post(void Function() fn) {
    SchedulerBinding.instance.addPostFrameCallback((_) => fn());
  }

  // ─────────────────────────────────────────
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _screenW = size.x;
    _screenH = size.y;

    final margin = _screenW * FlickConst.arenaMargin;
    _arenaL  = margin;
    _arenaR  = _screenW - margin;
    _arenaT  = _screenH * 0.14;
    _arenaB  = _screenH * 0.86;
    _centreY = (_arenaT + _arenaB) / 2;

    camera.viewfinder.anchor = Anchor.center;
    camera.viewfinder.zoom = FlickConst.worldScale;
    camera.viewfinder.position = size / (2 * FlickConst.worldScale);

    add(FlickBackground(screenW: _screenW, screenH: _screenH));

    _arenaRenderer = ArenaRenderer(
      arenaL: _arenaL, arenaR: _arenaR,
      arenaT: _arenaT, arenaB: _arenaB,
      centreY: _centreY,
    );
    add(_arenaRenderer);

    _aimLine = AimLine();
    add(_aimLine);
  }

  void startMatch() {
    _started = true;
    _ai = AiController(difficulty: notifier.state.aiDifficulty);
    _post(() => notifier.startMatch());
    _spawnRound();
  }

  void startNextRound() {
    _clearPucks();
    _ai.reset();
    _post(() => notifier.startNextRound());
    _spawnRound();
  }

  // ── Spawn pucks for one round ─────────────
  void _spawnRound() {
    _playerPucks.clear();
    _aiPucks.clear();

    final arenaW = _arenaR - _arenaL;
    final spacing = arenaW / (FlickConst.pucksPerSide + 1);

    for (int i = 0; i < FlickConst.pucksPerSide; i++) {
      final x = _arenaL + spacing * (i + 1);

      // Player pucks — bottom quarter
      final py = _arenaB - (_arenaB - _centreY) * 0.35;
      final pp = PuckBody(
        owner:    PuckOwner.player,
        spawnPos: Vector2(x, py),
        id:       'p${_puckIdCounter++}',
      );
      _playerPucks.add(pp);
      add(pp);

      // AI pucks — top quarter
      final ay = _arenaT + (_centreY - _arenaT) * 0.35;
      final ap = PuckBody(
        owner:    PuckOwner.ai,
        spawnPos: Vector2(x, ay),
        id:       'a${_puckIdCounter++}',
      );
      _aiPucks.add(ap);
      add(ap);
    }

    // Add walls after pucks so they're loaded
    add(ArenaWalls(
      arenaL: _arenaL, arenaR: _arenaR,
      arenaT: _arenaT, arenaB: _arenaB,
    ));
  }

  void _clearPucks() {
    for (final p in [..._playerPucks, ..._aiPucks]) {
      p.removeFromParent();
    }
    _playerPucks.clear();
    _aiPucks.clear();
    removeWhere((c) => c is ArenaWalls);
  }

  // ─────────────────────────────────────────
  @override
  void update(double dt) {
    super.update(dt);
    if (!_started) return;
    if (notifier.state.status != FlickStatus.roundActive) return;

    _post(() => notifier.tick(dt));
    _checkKnockoffs();
    _runAi(dt);
  }

  // ── Knock-off detection ───────────────────
  void _checkKnockoffs() {
    // Player pucks knocked off (went too far above AI zone or outside arena)
    for (final p in List<PuckBody>.from(_playerPucks)) {
      if (p.knockedOff) continue;
      final px = p.worldPx;
      if (_isOutsideArena(px) || px.y < _arenaT - 10) {
        _knockOff(p, isPlayer: true);
      }
    }

    // AI pucks knocked off (went too far below Player zone or outside arena)
    for (final p in List<PuckBody>.from(_aiPucks)) {
      if (p.knockedOff) continue;
      final px = p.worldPx;
      if (_isOutsideArena(px) || px.y > _arenaB + 10) {
        _knockOff(p, isPlayer: false);
      }
    }
  }

  bool _isOutsideArena(Vector2 pos) =>
      pos.x < _arenaL - 30 ||
      pos.x > _arenaR + 30 ||
      pos.y < _arenaT - 30 ||
      pos.y > _arenaB + 30;

  void _knockOff(PuckBody puck, {required bool isPlayer}) {
    puck.knockedOff = true;

    // Burst
    add(KnockOffBurst(
      position: puck.worldPx,
      color: isPlayer ? FlickColors.playerPuck : FlickColors.aiPuck,
    ));

    // Flash
    add(FlickScreenFlash(
      screenW: _screenW,
      screenH: _screenH,
      color: isPlayer ? FlickColors.energy : FlickColors.accent,
    ));

    HapticFeedback.mediumImpact();
    puck.removeFromParent();

    if (isPlayer) {
      _playerPucks.remove(puck);
      _post(() => notifier.playerPuckKnockedOff());
    } else {
      _aiPucks.remove(puck);
      _post(() => notifier.aiPuckKnockedOff());
    }
  }

  // ── AI ────────────────────────────────────
  void _runAi(double dt) {
    final shot = _ai.update(dt, _aiPucks, _playerPucks);
    if (shot != null && !shot.puck.knockedOff) {
      shot.puck.applyFlickImpulse(shot.impulse);
    }
  }

  // ── Drag to flick ─────────────────────────
  @override
  void onDragStart(DragStartEvent event) {
    if (!_started) return;
    if (notifier.state.status != FlickStatus.roundActive) return;

    final pos = event.localPosition;

    // Find the closest player puck within touch radius
    PuckBody? closest;
    double    closestDist = double.infinity;

    for (final p in _playerPucks) {
      if (p.knockedOff) continue;
      final d = (p.worldPx - pos).length;
      if (d < FlickConst.puckRadius * 2.5 && d < closestDist) {
        closestDist = d;
        closest = p;
      }
    }

    if (closest != null) {
      _dragPuck  = closest;
      _dragStart = pos;
      _aimLine.fromPx  = closest.worldPx.clone();
      _aimLine.visible = true;
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (_dragPuck == null || _dragStart == null) return;
    _aimLine.toPx = event.localEndPosition;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    if (_dragPuck == null || _dragStart == null) return;

    final endPos = _aimLine.toPx ?? _dragStart!;
    final delta  = _dragStart! - endPos; // flick opposite to drag direction
    final dist   = delta.length;

    if (dist > 10) {
      final power   = (dist / 120.0).clamp(0.0, 1.0);
      final impulse = delta.normalized() * FlickConst.maxFlickImpulse * power;
      _dragPuck!.applyFlickImpulse(impulse);
      HapticFeedback.lightImpact();
    }

    _dragPuck  = null;
    _dragStart = null;
    _aimLine.visible = false;
    _aimLine.fromPx  = null;
    _aimLine.toPx    = null;
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    _dragPuck  = null;
    _dragStart = null;
    _aimLine.visible = false;
  }
}
