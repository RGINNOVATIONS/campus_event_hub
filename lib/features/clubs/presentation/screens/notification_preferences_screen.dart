import 'package:campus_event_hub/app/theme.dart';
import 'package:campus_event_hub/core/widgets/widgets.dart';
import 'package:campus_event_hub/features/clubs/presentation/controllers/club_controllers.dart';
import 'package:campus_event_hub/features/events/presentation/controllers/events_controllers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Reachable from Profile. Lets a student manage which clubs and
/// categories they follow — the source of both the Home "Following"
/// filter and which publish notifications they receive.
class NotificationPreferencesScreen extends ConsumerWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final clubsAsync = ref.watch(verifiedClubsProvider);
    final followedCategories =
        ref.watch(followedCategoriesProvider).valueOrNull ?? {};
    final followedClubs = ref.watch(followedClubsProvider).valueOrNull ?? {};

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ── Categories section ────────────────────────────────────────
          _PreferenceSection(
            icon: Icons.category_outlined,
            title: 'Categories',
            badge: const AppBadge(
              label: 'Category notifications',
              tone: AppBadgeTone.primary,
              icon: Icon(Icons.notifications_outlined),
            ),
            description:
                'Get notified when a new event in these categories is published.',
            child: categoriesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => ErrorState(
                message: 'Could not load categories.',
                onRetry: () => ref.invalidate(categoriesProvider),
              ),
              data: (categories) => Column(
                children: categories.map((c) {
                  final isFollowed = followedCategories.contains(c.id);
                  return _PreferenceTile(
                    initial: c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                    title: c.name,
                    isActive: isFollowed,
                    onToggle: () => ref
                        .read(followedCategoriesProvider.notifier)
                        .toggle(c.id),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Clubs section ─────────────────────────────────────────────
          _PreferenceSection(
            icon: Icons.groups_outlined,
            title: 'Clubs',
            badge: const AppBadge(
              label: 'Club notifications',
              tone: AppBadgeTone.primary,
              icon: Icon(Icons.notifications_outlined),
            ),
            description: 'Get notified when these clubs publish a new event.',
            child: clubsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => ErrorState(
                message: 'Could not load clubs.',
                onRetry: () => ref.invalidate(verifiedClubsProvider),
              ),
              data: (clubs) {
                if (clubs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      'No verified clubs yet.',
                      style: AppTextStyles.bodySecondary,
                    ),
                  );
                }
                return Column(
                  children: clubs.map((c) {
                    final isFollowed = followedClubs.contains(c.id);
                    return _PreferenceTile(
                      initial:
                          c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                      title: c.name,
                      isActive: isFollowed,
                      onToggle: () =>
                          ref.read(followedClubsProvider.notifier).toggle(c.id),
                      onViewTap: () => context.push('/student/clubs/${c.id}'),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

// ── Preference section container ──────────────────────────────────────────────

class _PreferenceSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget badge;
  final String description;
  final Widget child;

  const _PreferenceSection({
    required this.icon,
    required this.title,
    required this.badge,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border),
        borderRadius: AppRadius.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 16, color: AppColors.primary),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      title,
                      style: AppTextStyles.title,
                    ),
                    const Spacer(),
                    badge,
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(description, style: AppTextStyles.bodySecondary),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          // Items
          child,
        ],
      ),
    );
  }
}

// ── Preference tile ───────────────────────────────────────────────────────────

class _PreferenceTile extends StatelessWidget {
  final String initial;
  final String title;
  final bool isActive;
  final VoidCallback onToggle;
  final VoidCallback? onViewTap;

  const _PreferenceTile({
    required this.initial,
    required this.title,
    required this.isActive,
    required this.onToggle,
    this.onViewTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          value: isActive,
          onChanged: (_) => onToggle(),
          activeTrackColor: AppColors.primary,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          title: Row(
            children: [
              // Avatar initial
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      isActive ? AppColors.primaryLight : AppColors.background,
                  borderRadius: AppRadius.sm,
                  border: Border.all(
                    color: isActive
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : AppColors.border,
                  ),
                ),
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isActive ? AppColors.primary : AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.label.copyWith(
                    color: isActive
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              if (onViewTap != null)
                TextButton(
                  onPressed: onViewTap,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: const Text('View'),
                ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}
