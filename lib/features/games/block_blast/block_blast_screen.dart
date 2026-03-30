import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'block_blast_engine.dart';
import 'block_blast_provider.dart';
import 'block_blast_styles.dart';
import 'package:we_play/core/providers/coin_provider.dart';
import 'package:we_play/core/providers/user_stats_provider.dart';
import 'package:we_play/core/providers/ad_provider.dart';

// ─────────────────────────────────────────────
//  BLOCK BLAST SCREEN
// ─────────────────────────────────────────────

class BlockBlastScreen extends ConsumerStatefulWidget {
  const BlockBlastScreen({super.key});
  @override
  ConsumerState<BlockBlastScreen> createState() => _BlockBlastScreenState();
}

class _BlockBlastScreenState extends ConsumerState<BlockBlastScreen> {
  bool _started = false;
  bool _showingGameOver = false;
  int? _draggingIndex;
  Offset? _hoverCell; // row, col being hovered

  void _startGame() {
    ref.read(blockBlastProvider.notifier).startGame();
    setState(() {
      _started = true;
      _showingGameOver = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(blockBlastProvider);

    // Game over trigger
    if (state.status == BlockStatus.over && _started && !_showingGameOver) {
      _showingGameOver = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showGameOver(context, state);
      });
    }

    return Scaffold(
      backgroundColor: BlockColors.background,
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

  // ── Start Overlay ───────────────────────────
  Widget _buildStartOverlay() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_rounded,
                color: BlockColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Text('🧱', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'BLOCK BLAST',
            style: GoogleFonts.orbitron(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: BlockColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'drag blocks to fill rows & columns',
            style: GoogleFonts.nunito(
                fontSize: 14, color: BlockColors.textSecondary),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _startGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: BlockColors.primary,
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

  // ── Header ──────────────────────────────────
  Widget _buildHeader(BlockState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_rounded,
                color: BlockColors.textSecondary, size: 22),
          ),
          const Spacer(),
          Column(
            children: [
              Text(
                '${state.score}',
                style: GoogleFonts.orbitron(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: BlockColors.textPrimary,
                ),
              ),
              Text(
                'best: ${state.bestScore}',
                style: GoogleFonts.nunito(
                    fontSize: 11, color: BlockColors.textSecondary),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: BlockColors.warn.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: BlockColors.warn.withAlpha(50)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on_rounded,
                    color: BlockColors.warn, size: 16),
                const SizedBox(width: 4),
                Text('${state.coins}',
                    style: GoogleFonts.orbitron(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: BlockColors.warn)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 8×8 Grid ────────────────────────────────
  Widget _buildGrid(BlockState state) {
    final gridPixels =
        BlockConst.gridSize * (BlockConst.cellSize + BlockConst.cellGap) +
            BlockConst.cellGap;

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        if (_hoverCell != null) {
          final row = _hoverCell!.dx.toInt();
          final col = _hoverCell!.dy.toInt();
          ref
              .read(blockBlastProvider.notifier)
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
        // Calculate which cell the drag is over
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final local = box.globalToLocal(details.offset);
        final gridLeft =
            (MediaQuery.of(context).size.width - gridPixels) / 2;
        final gridTop = local.dy;

        // We need the grid's actual top position
        // Use a key approach — simplified: use the offset directly
        final relX = local.dx - gridLeft;
        final relY = gridTop;

        // Approximate — the grid is centered
        if (relX >= 0 && relX < gridPixels) {
          final col =
              (relX / (BlockConst.cellSize + BlockConst.cellGap)).floor();
          final row =
              ((details.offset.dy - _gridTopOffset(context)) /
                      (BlockConst.cellSize + BlockConst.cellGap))
                  .floor();
          if (row >= 0 &&
              row < BlockConst.gridSize &&
              col >= 0 &&
              col < BlockConst.gridSize) {
            setState(() => _hoverCell = Offset(row.toDouble(), col.toDouble()));
            return;
          }
        }
        setState(() => _hoverCell = null);
      },
      builder: (context, accepted, rejected) {
        return Container(
          padding: EdgeInsets.all(BlockConst.cellGap),
          decoration: BoxDecoration(
            color: BlockColors.gridBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: BlockColors.cellBorder, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(BlockConst.gridSize, (r) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(BlockConst.gridSize, (c) {
                  final filled = state.grid[r][c];
                  final color = state.colorGrid[r][c];

                  // Highlight hover cells
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
                              .read(blockBlastProvider.notifier)
                              .canPlaceAt(_draggingIndex!, hr, hc);
                          break;
                        }
                      }
                    }
                  }

                  return Container(
                    width: BlockConst.cellSize,
                    height: BlockConst.cellSize,
                    margin: EdgeInsets.all(BlockConst.cellGap / 2),
                    decoration: BoxDecoration(
                      color: filled
                          ? color ?? BlockColors.primary
                          : isHover
                              ? (isValid
                                  ? BlockColors.accent.withAlpha(60)
                                  : BlockColors.energy.withAlpha(60))
                              : BlockColors.cellEmpty,
                      borderRadius:
                          BorderRadius.circular(BlockConst.cellRadius),
                      border: Border.all(
                        color: filled
                            ? (color ?? BlockColors.primary).withAlpha(180)
                            : BlockColors.cellBorder,
                        width: filled ? 1.5 : 0.5,
                      ),
                      boxShadow: filled
                          ? [
                              BoxShadow(
                                color:
                                    (color ?? BlockColors.primary).withAlpha(40),
                                blurRadius: 6,
                              )
                            ]
                          : null,
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
    // Approximate: header ~70px + spacer takes us to roughly center
    final screenH = MediaQuery.of(context).size.height;
    final gridPixels =
        BlockConst.gridSize * (BlockConst.cellSize + BlockConst.cellGap) +
            BlockConst.cellGap;
    // The grid is between header and tray
    return (screenH - gridPixels) / 2 - 20;
  }

  // ── Piece Tray ──────────────────────────────
  Widget _buildPieceTray(BlockState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    color: BlockColors.accent.withAlpha(60), size: 28),
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
              child: _buildPieceMini(piece, scale: 0.6),
            ),
            child: _buildPieceMini(piece, scale: 0.6),
          );
        }),
      ),
    );
  }

  Widget _buildPieceMini(BlockPiece piece,
      {double scale = 1.0, double opacity = 1.0}) {
    final cellSz = BlockConst.cellSize * scale;
    final gap = BlockConst.cellGap * scale;

    return Opacity(
      opacity: opacity,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(gap),
          decoration: BoxDecoration(
            color: BlockColors.surface.withAlpha(200),
            borderRadius: BorderRadius.circular(10),
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
                      color: has ? piece.color : Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(BlockConst.cellRadius * scale),
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

  // ── Game Over ───────────────────────────────
  void _showGameOver(BuildContext ctx, BlockState state) {
    if (!mounted) return;
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: BlockColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: BlockColors.textSecondary.withAlpha(60),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('GAME OVER',
                style: GoogleFonts.orbitron(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: BlockColors.energy)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statCol('Score', '${state.score}', BlockColors.primary),
                _statCol('Best', '${state.bestScore}', BlockColors.accent),
                _statCol('Coins', '+${state.coins}', BlockColors.warn),
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
                      side: const BorderSide(color: BlockColors.textSecondary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50)),
                    ),
                    child: Text('HOME',
                        style: GoogleFonts.orbitron(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: BlockColors.textSecondary)),
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
                      backgroundColor: BlockColors.primary,
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

    // Award coins and track games played
    if (state.coins > 0) {
      ref.read(coinNotifierProvider.notifier).earnCoins(state.coins);
    }
    ref.read(userStatsProvider.notifier).incrementGamesPlayed();
    ref.read(adServiceProvider).showInterstitialIfReady();
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
                fontSize: 11, color: BlockColors.textSecondary)),
      ],
    );
  }
}
