import 'package:campus_pulse/app/providers.dart';
import 'package:campus_pulse/app/theme.dart';
import 'package:campus_pulse/core/domain/enums.dart';
import 'package:campus_pulse/core/widgets/widgets.dart';
import 'package:campus_pulse/features/clubs/domain/club_repository.dart';
import 'package:campus_pulse/features/clubs/presentation/controllers/club_controllers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ClubsScreen extends ConsumerStatefulWidget {
  const ClubsScreen({super.key});

  @override
  ConsumerState<ClubsScreen> createState() => _ClubsScreenState();
}

class _ClubsScreenState extends ConsumerState<ClubsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clubsAsync = ref.watch(verifiedClubsProvider);
    final followedClubs = ref.watch(followedClubsProvider).valueOrNull ?? {};
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final isStudent = profile?.role == UserRole.student;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Clubs'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: clubsAsync.when(
        loading: () => const LoadingState(message: 'Loading clubs...'),
        error: (e, _) => ErrorState(
          message: 'Could not load clubs.',
          onRetry: () => ref.invalidate(verifiedClubsProvider),
        ),
        data: (clubs) {
          final filtered = _filtered(clubs);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(verifiedClubsProvider),
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width >=
                              AppBreakpoints.wide
                          ? AppSpacing.maxContentWidth
                          : double.infinity,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          SectionHeader(
                            title: 'Campus Clubs',
                            subtitle:
                                '${clubs.length} verified ${clubs.length == 1 ? 'club' : 'clubs'} — follow to get notified of new events',
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Search
                          AppSearchField(
                            controller: _searchController,
                            hintText: 'Search clubs...',
                            onChanged: (v) => setState(() => _query = v),
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          // Empty state for search
                          if (filtered.isEmpty && clubs.isNotEmpty)
                            const EmptyState(
                              icon: Icon(Icons.search_off_outlined),
                              title: 'No clubs match your search',
                              description:
                                  'Try a different club name or clear the search.',
                            )
                          else if (clubs.isEmpty)
                            const EmptyState(
                              icon: Icon(Icons.groups_outlined),
                              title: 'No clubs yet',
                              description:
                                  'Verified clubs will appear here. Check back soon.',
                            )
                          else
                            Column(
                              children: [
                                for (final club in filtered)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: AppSpacing.md),
                                    child: _ClubCard(
                                      club: club,
                                      isFollowing:
                                          followedClubs.contains(club.id),
                                      isStudent: isStudent,
                                      onTap: () => context
                                          .push('/student/clubs/${club.id}'),
                                      onFollowToggle: () => ref
                                          .read(followedClubsProvider.notifier)
                                          .toggle(club.id),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<ClubModel> _filtered(List<ClubModel> clubs) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return clubs;
    return clubs
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.description.toLowerCase().contains(q))
        .toList();
  }
}

// ── Club card ─────────────────────────────────────────────────────────────────

class _ClubCard extends StatelessWidget {
  final ClubModel club;
  final bool isFollowing;
  final bool isStudent;
  final VoidCallback onTap;
  final VoidCallback onFollowToggle;

  const _ClubCard({
    required this.club,
    required this.isFollowing,
    required this.isStudent,
    required this.onTap,
    required this.onFollowToggle,
  });

  @override
  Widget build(BuildContext context) {
    final initial = club.name.isNotEmpty ? club.name[0].toUpperCase() : '?';

    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.lg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lg,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: AppRadius.lg,
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: AppRadius.md,
                ),
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            club.name,
                            style: AppTextStyles.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isFollowing) ...[
                          const SizedBox(width: AppSpacing.sm),
                          const AppBadge(
                            label: 'Following',
                            tone: AppBadgeTone.success,
                            icon: Icon(Icons.check),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      club.description,
                      style: AppTextStyles.bodySecondary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.mail_outline,
                                size: 13,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  club.contactEmail,
                                  style: AppTextStyles.caption,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        // Follow / Unfollow button
                        if (isStudent)
                          SizedBox(
                            height: 34,
                            child: isFollowing
                                ? OutlinedButton.icon(
                                    onPressed: onFollowToggle,
                                    icon: const Icon(Icons.check, size: 14),
                                    label: const Text('Following'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.success,
                                      side: const BorderSide(
                                          color: AppColors.success),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      minimumSize: Size.zero,
                                    ),
                                  )
                                : FilledButton.icon(
                                    onPressed: onFollowToggle,
                                    icon: const Icon(Icons.add, size: 14),
                                    label: const Text('Follow'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: AppColors.textOnPrimary,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      minimumSize: Size.zero,
                                    ),
                                  ),
                          ),
                      ],
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
}
