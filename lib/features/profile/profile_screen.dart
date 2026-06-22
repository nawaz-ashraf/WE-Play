import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:we_play/app/theme.dart';
import 'package:we_play/core/providers/theme_provider.dart';
import 'package:we_play/core/providers/user_stats_provider.dart';
import 'package:we_play/core/providers/coin_provider.dart';
import 'package:we_play/core/providers/ad_provider.dart';
import 'package:we_play/core/widgets/coin_display.dart';

/// Profile screen
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditingName = false;
  late TextEditingController _nameController;
  bool _savingName = false;
  String _nameError = '';
  String _currentUsername = 'Player_1';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _currentUsername);
    _loadLocalUsername();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadLocalUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final localName = prefs.getString('username');
    if (localName != null && localName.isNotEmpty && mounted) {
      setState(() {
        _currentUsername = localName;
        _nameController.text = localName;
      });
    }
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();

    // Validation
    if (name.isEmpty) {
      setState(() => _nameError = 'name cannot be empty');
      return;
    }
    if (name.length < 3) {
      setState(() => _nameError = 'at least 3 characters');
      return;
    }
    if (name.length > 20) {
      setState(() => _nameError = 'max 20 characters');
      return;
    }
    final valid = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!valid.hasMatch(name)) {
      setState(() => _nameError = 'only letters, numbers, _');
      return;
    }

    setState(() => _savingName = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', name);

      if (mounted) {
        setState(() {
          _currentUsername = name;
          _isEditingName = false;
          _savingName = false;
          _nameError = '';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'username updated! 🎉',
              style: GoogleFonts.orbitron(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            backgroundColor: const Color(0xFF00F5A0),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _savingName = false;
          _nameError = 'failed to save, try again';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final userStats = ref.watch(userStatsProvider);
    final isLight = themeMode == ThemeMode.light;
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final surfaceColor = theme.colorScheme.surface;
    final subtleText = onSurface.withAlpha(140);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Text(
                    'profile',
                    style: GoogleFonts.orbitron(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      ref.read(themeProvider.notifier).toggleTheme();
                    },
                    icon: Icon(
                      isLight ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: subtleText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [WePlayColors.primary, WePlayColors.energy],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: WePlayColors.primary.withAlpha(80),
                    width: 3,
                  ),
                ),
                child: const Icon(Icons.person_rounded,
                    size: 40, color: Colors.white),
              ),
              const SizedBox(height: 12),

              // ── Username (editable) ─────────────────
              _isEditingName
                  ? _buildNameEditor(onSurface)
                  : _buildNameDisplay(onSurface),

              const SizedBox(height: 16),
              const CoinDisplay(),
              const SizedBox(height: 32),
              // Stats grid
              Row(
                children: [
                  _StatCard(
                    label: 'games played',
                    value: '${userStats.gamesPlayed}',
                    icon: Icons.videogame_asset_rounded,
                    color: WePlayColors.primary,
                    surfaceColor: surfaceColor,
                    onSurface: onSurface,
                    subtleText: subtleText,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'login streak',
                    value: '${userStats.loginStreak} days',
                    icon: Icons.calendar_today_rounded,
                    color: WePlayColors.secondary,
                    surfaceColor: surfaceColor,
                    onSurface: onSurface,
                    subtleText: subtleText,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                   _StatCard(
                    label: 'ad coins earned',
                    value: '${userStats.adCoins}',
                    icon: Icons.play_circle_fill_rounded,
                    color: WePlayColors.amber,
                    surfaceColor: surfaceColor,
                    onSurface: onSurface,
                    subtleText: subtleText,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ),

              const SizedBox(height: 32),

              // ── Watch Ad & Earn Coins ──────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: WePlayColors.amber.withAlpha(50)),
                  boxShadow: [
                    BoxShadow(
                      color: WePlayColors.amber.withAlpha(15),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Icon header
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: WePlayColors.amber.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.ondemand_video_rounded,
                        size: 32,
                        color: WePlayColors.amber,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Watch Ads',
                      style: GoogleFonts.orbitron(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Watch ad for 100 bonus coins',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: subtleText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _watchRewardedAd(ref, context);
                        },
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('WATCH AD  •  +100 🪙'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: WePlayColors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          textStyle: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Username display (tap to edit) ──────────────
  Widget _buildNameDisplay(Color onSurface) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isEditingName = true;
          _nameController.text = _currentUsername;
          _nameError = '';
        });
        HapticFeedback.selectionClick();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _currentUsername,
            style: GoogleFonts.orbitron(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: WePlayColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: WePlayColors.primary.withAlpha(80)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.edit_rounded,
                    color: WePlayColors.primary, size: 12),
                const SizedBox(width: 4),
                Text(
                  'edit',
                  style: GoogleFonts.orbitron(
                    fontSize: 10,
                    color: WePlayColors.primary,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Username editor ─────────────────────────────
  Widget _buildNameEditor(Color onSurface) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 240,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: onSurface.withAlpha(10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: WePlayColors.primary.withAlpha(120), width: 1.5),
          ),
          child: TextField(
            controller: _nameController,
            autofocus: true,
            maxLength: 20,
            style: GoogleFonts.orbitron(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: onSurface,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              counterText: '',
              hintText: 'enter username',
              hintStyle: GoogleFonts.orbitron(
                color: onSurface.withAlpha(80),
                fontSize: 14,
              ),
            ),
            onSubmitted: (_) => _saveName(),
          ),
        ),

        // Validation error
        if (_nameError.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(_nameError,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFFFF3E6C))),
        ],

        const SizedBox(height: 10),

        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cancel
            GestureDetector(
              onTap: () => setState(() {
                _isEditingName = false;
                _nameError = '';
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: onSurface.withAlpha(15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'cancel',
                  style: GoogleFonts.orbitron(
                    color: onSurface.withAlpha(140),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Save
            GestureDetector(
              onTap: _savingName ? null : _saveName,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [
                    WePlayColors.primary,
                    Color(0xFF5A45CC),
                  ]),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                        color: WePlayColors.primary.withAlpha(100),
                        blurRadius: 12),
                  ],
                ),
                child: _savingName
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        'save',
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Show a rewarded ad — awards 100 coins on completion.
  void _watchRewardedAd(WidgetRef ref, BuildContext context) async {
    final adService = ref.read(adServiceProvider);

    if (!adService.isRewardedAdReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ad is loading, please try again in a moment.',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
          ),
          backgroundColor: WePlayColors.energy,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    await adService.showRewardedAd(
      onRewarded: (amount) {
        ref.read(coinNotifierProvider.notifier).earnCoins(amount);
        ref.read(userStatsProvider.notifier).addAdCoins(amount);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '+$amount coins earned! 🎉',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
              ),
              backgroundColor: WePlayColors.amber,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color surfaceColor;
  final Color onSurface;
  final Color subtleText;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.surfaceColor,
    required this.onSurface,
    required this.subtleText,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.orbitron(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 11,
                color: subtleText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
