import 'dart:math';

// ─────────────────────────────────────────────
//  BLOB MODEL
// ─────────────────────────────────────────────
class Blob {
  final int value;
  final String id;

  const Blob({required this.value, required this.id});

  Blob copyWith({int? value}) => Blob(value: value ?? this.value, id: id);

  @override
  bool operator ==(Object other) => other is Blob && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

// ─────────────────────────────────────────────
//  MERGE RESULT  (returned after every swipe)
// ─────────────────────────────────────────────
class MoveResult {
  final List<List<Blob?>> grid;
  final int scoreGained;
  final int coinsGained;
  final List<MergeEvent> merges;
  final bool moved;

  const MoveResult({
    required this.grid,
    required this.scoreGained,
    required this.coinsGained,
    required this.merges,
    required this.moved,
  });
}

class MergeEvent {
  final int row;
  final int col;
  final int resultValue;
  const MergeEvent(
      {required this.row, required this.col, required this.resultValue});
}

// ─────────────────────────────────────────────
//  GAME ENGINE  (pure logic, no Flutter deps)
// ─────────────────────────────────────────────
class GlowMergeEngine {
  static const int size = 4;
  final _rng = Random();
  int _idCounter = 0;

  String _newId() => 'blob_${_idCounter++}';

  // ── Initial board ──────────────────────────
  List<List<Blob?>> newGame() {
    final grid = _emptyGrid();
    _addRandomBlob(grid);
    _addRandomBlob(grid);
    return grid;
  }

  List<List<Blob?>> _emptyGrid() => List.generate(
      size, (_) => List<Blob?>.filled(size, null, growable: false));

  void _addRandomBlob(List<List<Blob?>> grid) {
    final empty = <List<int>>[];
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (grid[r][c] == null) empty.add([r, c]);
      }
    }
    if (empty.isEmpty) return;
    final pos = empty[_rng.nextInt(empty.length)];
    grid[pos[0]][pos[1]] =
        Blob(value: _rng.nextDouble() < 0.9 ? 1 : 2, id: _newId());
  }

  // ── Swipe processing ──────────────────────
  MoveResult swipe(List<List<Blob?>> grid, SwipeDirection dir) {
    final copy = _deepCopy(grid);
    int score = 0;
    final merges = <MergeEvent>[];

    switch (dir) {
      case SwipeDirection.left:
        for (int r = 0; r < size; r++) {
          final res = _mergeLine([for (int c = 0; c < size; c++) copy[r][c]]);
          for (int c = 0; c < size; c++) copy[r][c] = res.line[c];
          score += res.score;
          for (final m in res.mergePositions) {
            merges.add(MergeEvent(row: r, col: m.index, resultValue: m.value));
          }
        }
        break;
      case SwipeDirection.right:
        for (int r = 0; r < size; r++) {
          final rev = [for (int c = size - 1; c >= 0; c--) copy[r][c]];
          final res = _mergeLine(rev);
          for (int c = 0; c < size; c++) copy[r][size - 1 - c] = res.line[c];
          score += res.score;
          for (final m in res.mergePositions) {
            merges.add(MergeEvent(
                row: r, col: size - 1 - m.index, resultValue: m.value));
          }
        }
        break;
      case SwipeDirection.up:
        for (int c = 0; c < size; c++) {
          final res = _mergeLine([for (int r = 0; r < size; r++) copy[r][c]]);
          for (int r = 0; r < size; r++) copy[r][c] = res.line[r];
          score += res.score;
          for (final m in res.mergePositions) {
            merges.add(MergeEvent(row: m.index, col: c, resultValue: m.value));
          }
        }
        break;
      case SwipeDirection.down:
        for (int c = 0; c < size; c++) {
          final rev = [for (int r = size - 1; r >= 0; r--) copy[r][c]];
          final res = _mergeLine(rev);
          for (int r = 0; r < size; r++) copy[size - 1 - r][c] = res.line[r];
          score += res.score;
          for (final m in res.mergePositions) {
            merges.add(MergeEvent(
                row: size - 1 - m.index, col: c, resultValue: m.value));
          }
        }
        break;
    }

    final moved = !_gridsEqual(grid, copy);
    if (moved) _addRandomBlob(copy);

    final coins = merges.where((m) => m.resultValue >= 32).length;

    return MoveResult(
      grid: copy,
      scoreGained: score,
      coinsGained: coins,
      merges: merges,
      moved: moved,
    );
  }

  // ── Line merge (left-compress) ─────────────
  _LineResult _mergeLine(List<Blob?> line) {
    // Compact non-null
    final blobs = line.whereType<Blob>().toList();
    int score = 0;
    final mergePositions = <_MergePos>[];

    // Merge adjacent equal
    for (int i = 0; i < blobs.length - 1; i++) {
      if (blobs[i].value == blobs[i + 1].value) {
        final merged = blobs[i].copyWith(value: blobs[i].value + 1);
        score += pow(2, merged.value).toInt();
        blobs[i] = merged;
        blobs.removeAt(i + 1);
        mergePositions.add(_MergePos(i, merged.value));
      }
    }

    // Build padded nullable list
    final List<Blob?> padded = List<Blob?>.filled(size, null);
    for (int i = 0; i < blobs.length; i++) {
      padded[i] = blobs[i];
    }
    return _LineResult(
        line: padded, score: score, mergePositions: mergePositions);
  }

  bool hasValidMoves(List<List<Blob?>> grid) {
    // Any empty cell
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (grid[r][c] == null) return true;
      }
    }
    // Any adjacent equal
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        final v = grid[r][c]?.value;
        if (v == null) continue;
        if (c + 1 < size && grid[r][c + 1]?.value == v) return true;
        if (r + 1 < size && grid[r + 1][c]?.value == v) return true;
      }
    }
    return false;
  }

  List<List<Blob?>> _deepCopy(List<List<Blob?>> grid) => [
        for (final row in grid) [...row]
      ];

  bool _gridsEqual(List<List<Blob?>> a, List<List<Blob?>> b) {
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (a[r][c]?.id != b[r][c]?.id) return false;
      }
    }
    return true;
  }
}

class _LineResult {
  final List<Blob?> line;
  final int score;
  final List<_MergePos> mergePositions;
  const _LineResult(
      {required this.line, required this.score, required this.mergePositions});
}

class _MergePos {
  final int index;
  final int value;
  const _MergePos(this.index, this.value);
}

enum SwipeDirection { left, right, up, down }
