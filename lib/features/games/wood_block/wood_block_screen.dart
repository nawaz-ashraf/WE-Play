import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'wood_block_engine.dart';
import 'wood_block_provider.dart';
import 'wood_block_styles.dart';
import 'package:we_play/core/providers/coin_provider.dart';
import 'package:we_play/core/providers/user_stats_provider.dart';

// ─────────────────────────────────────────────
//  WOOD BLOCK SCREEN
// ─────────────────────────────────────────────

class WoodBlockScreen extends ConsumerStatefulWidget {
  const WoodBlockScreen({super.key});
  @override
  ConsumerState<WoodBlockScreen> createState() => _WoodBlockScreenState();
}

class _WoodBlockScreenState extends ConsumerState<WoodBlockScreen> {
  bool _started = false;
  bool _showingGameOver = false;
  int? _draggingIndex;
  Offset? _hoverCell;

  void _startGame() {
    ref.read(woodBlockProvider.notifier).startGame();
    setState(() {
      _started = true;
      _showingGameOver = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(woodBlockProvider);

    if (state.status == WoodStatus.over && _started && !_showingGameOver) {
      _showingGameOver = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showGameOver(context, state);
      });
    }

    return Scaffold(
      backgroundColor: WoodColors.background,
      body: SafeArea(
        child: !_started
            ? _buildStartOverlay()
            : Column(
                children: [
                  _buildHeader(state),
                  const Spacer(),
                  _buildGrid(state),
                  const SizedBox(height: 24),
                  _buildPieceTray(state),
                  const Spacer(),
                ],
              ),
      ),
    );
  }

  Widget _buildStartOverlay() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_rounded,
                color: WoodColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Text('🪵', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'WOOD BLOCK',
            style: GoogleFonts.orbitron(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: WoodColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'fit the wooden pieces on the board',
            style: GoogleFonts.nunito(
                fontSize: 14, color: WoodColors.textSecondary),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _startGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: WoodColors.primary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50)),
            ),
            child: Text('START',
                style: GoogleFonts.orbitron(
                    fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(WoodState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_rounded,
                color: WoodColors.textSecondary, size: 22),
          ),
          const Spacer(),
          Column(
            children: [
              Text(
                '${state.score}',
                style: GoogleFonts.orbitron(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: WoodColors.accent,
                ),
              ),
              Text(
                'best: ${state.bestScore}',
                style: GoogleFonts.nunito(
                    fontSize: 11, color: WoodColors.textSecondary),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: WoodColors.accent.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: WoodColors.accent.withAlpha(50)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on_rounded,
                    color: WoodColors.accent, size: 16),
                const SizedBox(width: 4),
                Text('${state.coins}',
                    style: GoogleFonts.orbitron(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: WoodColors.accent)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(WoodState state) {
    final gridPixels =
        WoodConst.gridSize * (WoodConst.cellSize + WoodConst.cellGap) +
            WoodConst.cellGap;

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        if (_hoverCell != null) {
          final row = _hoverCell!.dx.toInt();
          final col = _hoverCell!.dy.toInt();
          ref
              .read(woodBlockProvider.notifier)
              .placePiece(details.data, row, col);
          HapticFeedback.mediumImpact();
        }
        setState(() {
          _draggingIndex = null;
          _hoverCell = null;
        });
      },
      onLeave: (_) => setState(() => _hoverCell = null),
      onMove: (details) {
        final gridLeft =
            (MediaQuery.of(context).size.width - gridPixels) / 2;
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final local = box.globalToLocal(details.offset);
        final relX = local.dx - gridLeft;
        final col =
            (relX / (WoodConst.cellSize + WoodConst.cellGap)).floor();
        final row =
            ((details.offset.dy - _gridTopOffset(context)) /
                    (WoodConst.cellSize + WoodConst.cellGap))
                .floor();
        if (row >= 0 &&
            row < WoodConst.gridSize &&
            col >= 0 &&
            col < WoodConst.gridSize) {
          setState(() => _hoverCell = Offset(row.toDouble(), col.toDouble()));
        } else {
          setState(() => _hoverCell = null);
        }
      },
      builder: (context, accepted, rejected) {
        return Container(
          padding: EdgeInsets.all(WoodConst.cellGap + 4),
          decoration: BoxDecoration(
            color: WoodColors.boardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: WoodColors.boardFrame, width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(WoodConst.gridSize, (r) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(WoodConst.gridSize, (c) {
                  final filled = state.grid[r][c];
                  final color = state.colorGrid[r][c];

                  bool isHover = false;
                  bool isValid = false;
                  if (_hoverCell != null && _draggingIndex != null) {
                    final piece = state.pieces[_draggingIndex!];
                    if (!piece.placed) {
                      final hr = _hoverCell!.dx.toInt();
                      final hc = _hoverCell!.dy.toInt();
                      for (final cell in piece.cells) {
                        if (hr + cell[0] == r && hc + cell[1] == c) {
                          isHover = true;
                          isValid = ref
                              .read(woodBlockProvider.notifier)
                              .canPlaceAt(_draggingIndex!, hr, hc);
                          break;
                        }
                      }
                    }
                  }

                  return Container(
                    width: WoodConst.cellSize,
                    height: WoodConst.cellSize,
                    margin: EdgeInsets.all(WoodConst.cellGap / 2),
                    decoration: BoxDecoration(
                      gradient: filled
                          ? LinearGradient(
                              colors: [
                                (color ?? WoodColors.primary).withAlpha(230),
                                (color ?? WoodColors.primary),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            )
                          : null,
                      color: filled
                          ? null
                          : isHover
                              ? (isValid
                                  ? WoodColors.accent.withAlpha(50)
                                  : WoodColors.energy.withAlpha(50))
                              : WoodColors.cellEmpty,
                      borderRadius:
                          BorderRadius.circular(WoodConst.cellRadius),
                      border: Border.all(
                        color: filled
                            ? (color ?? WoodColors.primary).withAlpha(180)
                            : WoodColors.cellBorder,
                        width: filled ? 1.5 : 0.5,
                      ),
                    ),
                  );
                }),
              );
            }),
          ),
        );
      },
    );
  }

  double _gridTopOffset(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final gridPixels =
        WoodConst.gridSize * (WoodConst.cellSize + WoodConst.cellGap) +
            WoodConst.cellGap;
    return (screenH - gridPixels) / 2 - 20;
  }

  Widget _buildPieceTray(WoodState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(state.pieces.length, (i) {
          final piece = state.pieces[i];
          if (piece.placed) {
            return SizedBox(
              width: 80,
              height: 80,
              child: Center(
                child: Icon(Icons.check_circle_rounded,
                    color: WoodColors.primary.withAlpha(60), size: 28),
              ),
            );
          }
          return Draggable<int>(
            data: i,
            onDragStarted: () {
              setState(() => _draggingIndex = i);
              HapticFeedback.lightImpact();
            },
            onDragEnd: (_) {
              setState(() {
                _draggingIndex = null;
                _hoverCell = null;
              });
            },
            feedback: _buildPieceMini(piece, scale: 1.0, opacity: 0.8),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: _buildPieceMini(piece, scale: 0.55),
            ),
            child: _buildPieceMini(piece, scale: 0.55),
          );
        }),
      ),
    );
  }

  Widget _buildPieceMini(WoodPiece piece,
      {double scale = 1.0, double opacity = 1.0}) {
    final cellSz = WoodConst.cellSize * scale;
    final gap = WoodConst.cellGap * scale;

    return Opacity(
      opacity: opacity,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(gap),
          decoration: BoxDecoration(
            color: WoodColors.boardBg.withAlpha(220),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: WoodColors.boardFrame.withAlpha(100)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(piece.rows, (r) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(piece.cols, (c) {
                  final has =
                      piece.cells.any((cell) => cell[0] == r && cell[1] == c);
                  return Container(
                    width: cellSz,
                    height: cellSz,
                    margin: EdgeInsets.all(gap / 2),
                    decoration: BoxDecoration(
                      gradient: has
                          ? LinearGradient(
                              colors: [
                                piece.color.withAlpha(230),
                                piece.color,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            )
                          : null,
                      color: has ? null : Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(WoodConst.cellRadius * scale),
                      border: has
                          ? Border.all(
                              color: piece.color.withAlpha(200), width: 1)
                          : null,
                    ),
                  );
                }),
              );
            }),
          ),
        ),
      ),
    );
  }

  void _showGameOver(BuildContext ctx, WoodState state) {
    if (!mounted) return;
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: WoodColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: WoodColors.textSecondary.withAlpha(60),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('GAME OVER',
                style: GoogleFonts.orbitron(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: WoodColors.energy)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statCol('Score', '${state.score}', WoodColors.primary),
                _statCol('Best', '${state.bestScore}', WoodColors.accent),
                _statCol('Coins', '+${state.coins}', WoodColors.accent),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.maybePop(ctx);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: WoodColors.textSecondary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50)),
                    ),
                    child: Text('HOME',
                        style: GoogleFonts.orbitron(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: WoodColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _startGame();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WoodColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50)),
                    ),
                    child: Text('RETRY',
                        style: GoogleFonts.orbitron(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (state.coins > 0) {
      ref.read(coinNotifierProvider.notifier).earnCoins(state.coins);
    }
    ref.read(userStatsProvider.notifier).incrementGamesPlayed();
  }

  Widget _statCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.orbitron(
                fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 4),
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 11, color: WoodColors.textSecondary)),
      ],
    );
  }
}
