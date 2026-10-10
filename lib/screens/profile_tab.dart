import 'package:flutter/material.dart';

import '../data/store_repository.dart';
import '../data/store_scope.dart';
import '../models/game.dart';
import '../theme/app_colors.dart';
import '../widgets/game_cards.dart';
import 'game_detail_screen.dart';

/// Tab 3 (Profile): account, library of purchased games, settings.
class ProfileTab extends StatefulWidget {
  /// Opens the Guard tab; null on web, where there's nothing to scan.
  final VoidCallback? onOpenGuard;

  const ProfileTab({super.key, this.onOpenGuard});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool notifications = true;
  bool priceAlerts = true;

  @override
  Widget build(BuildContext context) {
    final StoreController store = StoreScope.of(context);
    final UserProfile? profile = store.profile;
    final List<Game> library = store.libraryGames;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const Text(
              'Profile',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            _AccountCard(profile: profile),
            const SizedBox(height: 12),
            Row(
              children: [
                _Stat(label: 'Owned', value: library.length),
                const SizedBox(width: 10),
                _Stat(label: 'Wishlist', value: store.wishlist.length),
                const SizedBox(width: 10),
                _Stat(label: 'In cart', value: store.cartCount),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Library'),
            if (library.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Games you buy show up here.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                ),
              )
            else
              for (final Game g in library)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GameListTile(
                    game: g,
                    onTap: () => GameDetailScreen.open(context, g),
                    trailing: const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                    ),
                  ),
                ),
            const SizedBox(height: 16),
            const _SectionTitle('Settings'),
            Material(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  SwitchListTile(
                    value: notifications,
                    onChanged: (v) => setState(() => notifications = v),
                    activeThumbColor: AppColors.accent,
                    secondary: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.textSecondary,
                    ),
                    title: const Text(
                      'Notifications',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                  SwitchListTile(
                    value: priceAlerts,
                    onChanged: (v) => setState(() => priceAlerts = v),
                    activeThumbColor: AppColors.accent,
                    secondary: const Icon(
                      Icons.local_offer_outlined,
                      color: AppColors.textSecondary,
                    ),
                    title: const Text(
                      'Wishlist price drops',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                  if (widget.onOpenGuard != null)
                    ListTile(
                      onTap: widget.onOpenGuard,
                      leading: const Icon(
                        Icons.qr_code_2,
                        color: AppColors.textSecondary,
                      ),
                      title: const Text(
                        'Sign in on another device',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: store.signOut,
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final UserProfile? profile;

  const _AccountCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final String name = profile?.name.trim().isNotEmpty == true
        ? profile!.name
        : (profile?.email ?? '');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.accent.withValues(alpha: 0.18),
            child: Text(
              name.isEmpty ? '?' : name[0].toUpperCase(),
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  profile?.email ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                if (profile != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.darkBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      profile!.role,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final int value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
