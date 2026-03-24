import 'package:flutter/material.dart';

class FlappyBirdScreen extends StatelessWidget {
  const FlappyBirdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🐦', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text(
              'Flappy Bird',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7B61FF),
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
