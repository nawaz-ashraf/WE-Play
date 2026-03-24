import 'dart:math';
import 'memory_styles.dart';

// ─────────────────────────────────────────────
//  MEMORY ENGINE  — pure Dart game logic
// ─────────────────────────────────────────────
class MemoryEngine {
  final _rng = Random();

  // ── Generate shuffled deck ────────────────
  List<MemoryCard> generateDeck(MemoryDifficulty difficulty) {
    final size    = MemoryConst.gridSizes[difficulty]!;
    final total   = size.cols * size.rows;
    final pairs   = total ~/ 2;

    // Pick emojis for this game
    final pool    = List<String>.from(kCardEmojis)..shuffle(_rng);
    final chosen  = pool.take(pairs).toList();

    // Create pairs
    final cards   = <MemoryCard>[];
    int idCounter = 0;
    for (int p = 0; p < pairs; p++) {
      cards.add(MemoryCard(id: idCounter++, pairId: p, emoji: chosen[p]));
      cards.add(MemoryCard(id: idCounter++, pairId: p, emoji: chosen[p]));
    }

    cards.shuffle(_rng);
    return cards;
  }

  // ── Flip result ───────────────────────────
  /// Returns the action to take after flipping card at [index].
  FlipResult flip(List<MemoryCard> cards, int index, List<int> faceUpIndices) {
    final card = cards[index];

    // Already matched or face up → ignore
    if (card.isMatched || card.isFaceUp) return FlipResult.ignore;

    card.isFaceUp = true;
    faceUpIndices.add(index);

    if (faceUpIndices.length == 1) {
      return FlipResult.firstCard;
    }

    if (faceUpIndices.length == 2) {
      final a = cards[faceUpIndices[0]];
      final b = cards[faceUpIndices[1]];

      if (a.pairId == b.pairId) {
        a.isMatched = true;
        b.isMatched = true;
        return FlipResult.matched;
      } else {
        return FlipResult.noMatch;
      }
    }

    return FlipResult.ignore;
  }

  void flipBack(List<MemoryCard> cards, List<int> indices) {
    for (final i in indices) {
      cards[i].isFaceUp = false;
    }
  }

  bool isComplete(List<MemoryCard> cards) =>
      cards.every((c) => c.isMatched);
}

enum FlipResult { firstCard, matched, noMatch, ignore }
