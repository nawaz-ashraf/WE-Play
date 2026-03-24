import 'package:flutter/material.dart';

class MemoryPuzzleScreen extends StatelessWidget {
  const MemoryPuzzleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🃏', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text(
              'Memory Puzzle',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFF3E6C),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'coming soon',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF9090B0),
              ),
            ),
            const SizedBox(height: 32),
            TextButton(
              onPressed: () => Navigator.maybePop(context),
              child: const Text(
                '← back',
                style: TextStyle(color: Color(0xFF9090B0)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
