import 'dart:ui' show Rect, Offset;
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:flutter/services.dart'
    show HapticFeedback, LogicalKeyboardKey, KeyEvent, KeyDownEvent;
import 'package:flutter/widgets.dart' show KeyEventResult;
import 'heist_components.dart';
import 'heist_provider.dart';
import 'heist_styles.dart';

// ─────────────────────────────────────────────
//  MICRO HEIST GAME  (FlameGame)
// ─────────────────────────────────────────────
class MicroHeistGame extends FlameGame
    with TapCallbacks, KeyboardEvents {
  final HeistNotifier notifier;

  MicroHeistGame({required this.notifier});

  // ── Layout ────────────────────────────────
  late double _screenW;
  late double _screenH;
  late Vector2 _gridOffset;   // top-left pixel of the grid

  // ── Grid state ────────────────────────────
  late List<List<CellType>> _cells;
  int _thiefRow = 1;
  int _thiefCol = 1;
  bool _moving  = false;      // debounce grid movement

  // ── Components ────────────────────────────
  late GridMap      _gridMap;
  late ThiefSprite  _thief;
  LootItem?         _loot;
  ExitDoor?         _exit;
  final List<LaserBeam> _lasers = [];

  bool _started = false;
  bool _busted  = false;

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

    // Centre grid on screen
    final gridW = HeistConst.cols * HeistConst.cellSize;
    final gridH = HeistConst.rows * HeistConst.cellSize;
    _gridOffset = Vector2(
      (_screenW - gridW) / 2,
      (_screenH - gridH) / 2 + 16,
    );

    add(HeistBackground(screenW: _screenW, screenH: _screenH));
  }

  void startGame() {
    _started = true;
    _busted  = false;
    _loadLevel(notifier.currentLevel);
    _post(() => notifier.startGame());
  }

  void loadNextLevel() {
    _busted = false;
    _loadLevel(notifier.currentLevel);
  }

  // ─────────────────────────────────────────
  void _loadLevel(int levelIdx) {
    // Remove previous level components
    removeWhere((c) =>
        c is GridMap ||
        c is ThiefSprite ||
        c is LootItem ||
        c is ExitDoor ||
        c is LaserBeam);
    _lasers.clear();
    _loot = null;
    _exit = null;
    _moving = false;

    final levelDef = kLevels[levelIdx.clamp(0, kLevels.length - 1)];
    _cells = GridParser.parse(levelDef.grid);

    // ── Grid map ──────────────────────────
    _gridMap = GridMap(
      cells: _cells,
      cs: HeistConst.cellSize,
      offset: _gridOffset,
    );
    add(_gridMap);

    // ── Thief ─────────────────────────────
    final thiefPos = GridParser.findThief(levelDef.grid);
    _thiefRow = thiefPos.row;
    _thiefCol = thiefPos.col;

    _thief = ThiefSprite(
      cs: HeistConst.cellSize,
      row: _thiefRow,
      col: _thiefCol,
      gridOffset: _gridOffset,
    );
    add(_thief);

    // ── Loot ──────────────────────────────
    final lootPos = GridParser.findLoot(levelDef.grid);
    if (lootPos != null) {
      _loot = LootItem(
        cs: HeistConst.cellSize,
        row: lootPos.row,
        col: lootPos.col,
        gridOffset: _gridOffset,
      );
      add(_loot!);
    }

    // ── Exit ──────────────────────────────
    final exitPos = GridParser.findExit(levelDef.grid);
    if (exitPos != null) {
      _exit = ExitDoor(
        cs: HeistConst.cellSize,
        row: exitPos.row,
        col: exitPos.col,
        gridOffset: _gridOffset,
      );
      add(_exit!);
    }

    // ── Lasers ────────────────────────────
    final difficulty = (levelIdx / (kLevels.length - 1) * (HeistConst.laserSpeeds.length - 1)).round();
    final laserSpeed = HeistConst.laserSpeeds[difficulty.clamp(0, HeistConst.laserSpeeds.length - 1)];

    for (final laserDef in levelDef.lasers) {
      final laser = LaserBeam(
        def:        laserDef,
        cs:         HeistConst.cellSize,
        gridOffset: _gridOffset,
        speed:      laserSpeed,
      );
      _lasers.add(laser);
      add(laser);
    }
  }

  // ─────────────────────────────────────────
  @override
  void update(double dt) {
    super.update(dt);
    if (!_started || _busted) return;
    if (notifier.currentStatus == HeistStatus.busted ||
        notifier.currentStatus == HeistStatus.gameComplete) return;
    if (notifier.currentStatus == HeistStatus.levelComplete) return;

    _post(() => notifier.tick(dt));
    _checkLaserCollision();
    _syncExitState();
  }

  // ── Laser hit detection ───────────────────
  void _checkLaserCollision() {
    final thiefRect = _thiefWorldRect();
    for (final laser in _lasers) {
      if (laser.worldRect.overlaps(thiefRect)) {
        _triggerBusted();
        return;
      }
    }
  }

  Rect _thiefWorldRect() {
    final cx = _gridOffset.x + _thiefCol * HeistConst.cellSize + HeistConst.cellSize / 2;
    final cy = _gridOffset.y + _thiefRow * HeistConst.cellSize + HeistConst.cellSize / 2;
    const r  = HeistConst.thiefSize / 2 - 4; // slightly smaller for fairness
    return Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 2);
  }

  void _triggerBusted() {
    if (_busted) return;
    _busted = true;
    HapticFeedback.heavyImpact();
    add(BustedFlash(screenW: _screenW, screenH: _screenH));
    _post(() => notifier.busted());
  }

  // ── Sync exit active state ────────────────
  void _syncExitState() {
    if (_exit != null) {
      _exit!.active = notifier.hasLoot;
    }
    if (_thief.hasLoot != notifier.hasLoot) {
      _thief.hasLoot = notifier.hasLoot;
    }
  }

  // ── Movement: tap ─────────────────────────
  @override
  void onTapDown(TapDownEvent event) {
    if (!_started || _busted) return;
    if (notifier.currentStatus != HeistStatus.playing) return;

    final tapX = event.localPosition.x;
    final tapY = event.localPosition.y;

    // Determine direction from thief centre
    final thiefCX = _gridOffset.x + _thiefCol * HeistConst.cellSize + HeistConst.cellSize / 2;
    final thiefCY = _gridOffset.y + _thiefRow * HeistConst.cellSize + HeistConst.cellSize / 2;

    final dx = tapX - thiefCX;
    final dy = tapY - thiefCY;

    if (dx.abs() > dy.abs()) {
      _tryMove(0, dx > 0 ? 1 : -1);
    } else {
      _tryMove(dy > 0 ? 1 : -1, 0);
    }
  }

  // ── Movement: keyboard (debug / tablet) ──
  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (!_started || _busted) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowUp)    _tryMove(-1, 0);
    if (event.logicalKey == LogicalKeyboardKey.arrowDown)  _tryMove(1, 0);
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft)  _tryMove(0, -1);
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) _tryMove(0, 1);
    return KeyEventResult.handled;
  }

  void _tryMove(int dr, int dc) {
    if (_moving) return;
    final nr = _thiefRow + dr;
    final nc = _thiefCol + dc;

    // Bounds check
    if (nr < 0 || nr >= HeistConst.rows) return;
    if (nc < 0 || nc >= HeistConst.cols) return;

    // Pad short rows
    if (nc >= _cells[nr].length) return;

    // Wall check
    if (_cells[nr][nc] == CellType.wall) return;

    _thiefRow = nr;
    _thiefCol = nc;
    _moving = true;
    HapticFeedback.selectionClick();

    _thief.moveTo(nr, nc, _gridOffset);

    Future.delayed(const Duration(milliseconds: 130), () => _moving = false);

    _checkCellInteraction();
  }

  // ── Public swipe API (called by screen D-pad) ─
  void onSwipeUp()    => _tryMove(-1,  0);
  void onSwipeDown()  => _tryMove( 1,  0);
  void onSwipeLeft()  => _tryMove( 0, -1);
  void onSwipeRight() => _tryMove( 0,  1);

  void _checkCellInteraction() {
    final cell = _cells[_thiefRow][_thiefCol];

    // Pick up loot
    if (cell == CellType.loot && !notifier.hasLoot) {
      _cells[_thiefRow][_thiefCol] = CellType.floor;
      _loot?.collect();
      _post(() => notifier.pickupLoot());
      HapticFeedback.mediumImpact();
    }

    // Reach exit with loot
    if (cell == CellType.exit && notifier.hasLoot) {
      HapticFeedback.heavyImpact();
      _post(() => notifier.completeLevel());
      // Auto-load next level after brief pause
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (_started && !_busted) {
          if (notifier.currentStatus == HeistStatus.levelComplete) {
            _post(() => notifier.resumeNextLevel());
            loadNextLevel();
          }
        }
      });
    }
  }
}
