import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:we_play/app/theme.dart';

class UpdatePopup extends StatelessWidget {
  final VoidCallback onUpdate;
  final VoidCallback onSkip;

  const UpdatePopup({
    super.key,
    required this.onUpdate,
    required this.onSkip,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onUpdate,
    required VoidCallback onSkip,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => UpdatePopup(
        onUpdate: () {
          Navigator.of(ctx).pop();
          onUpdate();
        },
        onSkip: () {
          Navigator.of(ctx).pop();
          onSkip();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: WePlayColors.primary.withAlpha(50), width: 2),
          boxShadow: [
            BoxShadow(
              color: WePlayColors.primary.withAlpha(20),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: WePlayColors.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.system_update_rounded,
                  size: 48, color: WePlayColors.primary),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Update Available!',
              style: GoogleFonts.orbitron(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              'A new version of MiniPlay Hub is out with new games and bug fixes. Update now to enhance your experience!',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: WePlayColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Primary Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onUpdate,
                child: const Text('UPDATE NOW'),
              ),
            ),
            const SizedBox(height: 12),

            // Secondary Button
            TextButton(
              onPressed: onSkip,
              child: const Text('Not Right Now'),
            ),
          ],
        ),
      ),
    );
  }
}
