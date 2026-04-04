import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:we_play/app/theme.dart';
import 'package:we_play/core/models/store_game_model.dart';
import 'package:we_play/core/providers/ad_provider.dart';
import 'package:we_play/core/providers/game_unlock_provider.dart';
import 'package:we_play/core/widgets/coin_display.dart';

/// App Store screen
class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  @override
  void initState() {
    super.initState();
    // Banner ad will be created after first build when ref is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBannerAd();
    });
  }

  void _loadBannerAd() {
    final adService = ref.read(adServiceProvider);
    _bannerAd = adService.createBannerAd(
      onLoaded: () {
        if (mounted) setState(() => _isBannerLoaded = true);
      },
      onFailed: () {
        if (mounted) setState(() => _isBannerLoaded = false);
      },
    );
    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch unlock state strictly for reactivity, but access logic through notifier
    ref.watch(gameUnlockProvider);
    final notifier = ref.read(gameUnlockProvider.notifier);

    // Store exclusives
    final storeGames =
        GameCatalog.allGames.where((g) => !g.isDefaultGame).toList();

    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final surfaceColor = theme.colorScheme.surface;
    final subtleText = onSurface.withAlpha(140);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [WePlayColors.amber, WePlayColors.energy],
                    ).createShader(bounds),
                    child: const Icon(Icons.storefront_rounded,
                        size: 28, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'store',
                    style: GoogleFonts.orbitron(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: onSurface,
                    ),
                  ),
                  const Spacer(),
                  const CoinDisplay(),
                ],
              ),
            ),

            // Available items
            Expanded(
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: storeGames.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final game = storeGames[index];
                  final isUnlocked = notifier.isUnlocked(game.id);

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: game.accentColor.withAlpha(40)),
                      boxShadow: [
                        BoxShadow(
                          color: game.accentColor.withAlpha(10),
                          blurRadius: 20,
                          spreadRadius: -5,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Icon
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: game.accentColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(game.icon,
                              color: game.accentColor, size: 28),
                        ),
                        const SizedBox(width: 16),

                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                game.title,
                                style: GoogleFonts.orbitron(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                game.description,
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  color: subtleText,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Action Button
                        const SizedBox(width: 12),
                        isUnlocked
                            ? _buildPurchasedButton()
                            : _buildLockedAction(game, notifier),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── Banner Ad ────────────────────────────
            if (_isBannerLoaded && _bannerAd != null)
              Container(
                width: double.infinity,
                height: _bannerAd!.size.height.toDouble(),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  border: Border(
                    top: BorderSide(
                      color: onSurface.withAlpha(20),
                      width: 0.5,
                    ),
                  ),
                ),
                child: AdWidget(ad: _bannerAd!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchasedButton() {
    final subtleText = Theme.of(context).colorScheme.onSurface.withAlpha(140);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: subtleText.withAlpha(20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: subtleText.withAlpha(40)),
      ),
      child: Text(
        'Unlocked',
        style: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: subtleText,
        ),
      ),
    );
  }

  Widget _buildBuyButton(StoreGameModel game, GameUnlockNotifier notifier) {
    return GestureDetector(
      onTap: () async {
        final success = notifier.buyGame(game.id, game.coinPrice);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Unlocked ${game.title}! It is now available in the Home games list.'),
              backgroundColor: WePlayColors.primary,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Not enough coins to unlock this game.'),
              backgroundColor: WePlayColors.energy,
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [WePlayColors.amber, WePlayColors.energy],
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: WePlayColors.amber.withAlpha(60),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_open_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              'unlock',
              style: GoogleFonts.orbitron(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedAction(StoreGameModel game, GameUnlockNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: WePlayColors.energy.withAlpha(22),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: WePlayColors.energy.withAlpha(70)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_rounded,
                  color: WePlayColors.energy, size: 12),
              const SizedBox(width: 4),
              Text(
                '${game.coinPrice} coins',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: WePlayColors.energy,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildBuyButton(game, notifier),
      ],
    );
  }
}
