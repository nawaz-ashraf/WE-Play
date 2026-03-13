import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  BLOB VISUAL CONFIG
//  Maps blob value (1–13+) to neon color data
// ─────────────────────────────────────────────
class BlobStyle {
  final Color bg;
  final Color border;
  final Color text;
  final String label;

  const BlobStyle({
    required this.bg,
    required this.border,
    required this.text,
    required this.label,
  });
}

const Map<int, BlobStyle> kBlobStyles = {
  1:  BlobStyle(bg: Color(0xFF2A1F5C), border: Color(0xFF7B61FF), text: Color(0xFFD4CCFF), label: '2'),
  2:  BlobStyle(bg: Color(0xFF063528), border: Color(0xFF00F5A0), text: Color(0xFFB3FFE5), label: '4'),
  3:  BlobStyle(bg: Color(0xFF4A0A28), border: Color(0xFFFF6EB4), text: Color(0xFFFFCCE8), label: '8'),
  4:  BlobStyle(bg: Color(0xFF3D1F00), border: Color(0xFFFFB347), text: Color(0xFFFFE4B3), label: '16'),
  5:  BlobStyle(bg: Color(0xFF3D0A15), border: Color(0xFFFF3E6C), text: Color(0xFFFFB3C6), label: '32'),
  6:  BlobStyle(bg: Color(0xFF0A2A4A), border: Color(0xFF4FC3F7), text: Color(0xFFB3E5FF), label: '64'),
  7:  BlobStyle(bg: Color(0xFF1A3300), border: Color(0xFF8BC34A), text: Color(0xFFD4FFAD), label: '128'),
  8:  BlobStyle(bg: Color(0xFF2D1A00), border: Color(0xFFFFD740), text: Color(0xFFFFF3B3), label: '256'),
  9:  BlobStyle(bg: Color(0xFF1F0F4A), border: Color(0xFFAB47BC), text: Color(0xFFE8CCFF), label: '512'),
  10: BlobStyle(bg: Color(0xFF004D40), border: Color(0xFF26C6DA), text: Color(0xFFB2EBF2), label: '1K'),
  11: BlobStyle(bg: Color(0xFF4A0020), border: Color(0xFFFF4081), text: Color(0xFFFFB3CC), label: '2K'),
  12: BlobStyle(bg: Color(0xFF1A0040), border: Color(0xFF7C4DFF), text: Color(0xFFD4B3FF), label: '4K'),
  13: BlobStyle(bg: Color(0xFF004D1A), border: Color(0xFF69F0AE), text: Color(0xFFB9FFD9), label: '8K'),
};

BlobStyle getBlobStyle(int value) {
  return kBlobStyles[value] ??
      const BlobStyle(
        bg: Color(0xFF1A1A1A),
        border: Color(0xFFFFFFFF),
        text: Color(0xFFFFFFFF),
        label: '??',
      );
}

// ─────────────────────────────────────────────
//  APP COLORS
// ─────────────────────────────────────────────
class GlowColors {
  static const background = Color(0xFF0A0A12);
  static const surface    = Color(0xFF13131F);
  static const gridBg     = Color(0xFF0D0D1A);
  static const cellEmpty  = Color(0xFF1A1A2E);
  static const primary    = Color(0xFF7B61FF);
  static const accent     = Color(0xFF00F5A0);
  static const energy     = Color(0xFFFF3E6C);
  static const textPrimary   = Color(0xFFF2F2FF);
  static const textSecondary = Color(0xFF9090B0);
}
