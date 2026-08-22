import 'package:campus_event_hub/app/providers.dart';
import 'package:campus_event_hub/app/theme.dart';
import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/core/widgets/widgets.dart';
import 'package:campus_event_hub/features/clubs/presentation/controllers/club_controllers.dart';
import 'package:campus_event_hub/features/events/presentation/controllers/events_controllers.dart';
import 'package:campus_event_hub/features/events/presentation/widgets/event_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ClubDetailsScreen extends ConsumerWidget {
  final String clubId;
  const ClubDetailsScreen({super.key, required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubAsync = ref.watch(clubByIdProvider(clubId));
    final eventsAsync = ref.watch(clubUpcomingEventsProvider(clubId));
    final followedClubs = ref.watch(followedClubsProvider).valueOrNull ?? {};
    final isFollowing = followedClubs.contains(clubId);
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final isStudent = profile?.role == UserRole.student;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: clubAsync.when(
        loading: () => const Scaffold(
          body: LoadingState(message: 'Loading club...'),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('Club')),
          body: ErrorState(
            message: 'Could not load this club.',
            onRetry: () => ref.invalidate(clubByIdProvider(clubId)),
          ),
        ),
        data: (club) {
          final initial =
              club.name.isNotEmpty ? club.name[0].toUpperCase() : '?';

          return CustomScrollView(
            slivers: [
              // ── Hero app bar ──────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppColors.surface,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Gradient backdrop
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.primary, AppColors.primaryDark],
                          ),
                        ),
                      ),
                      // Club info
                      Positioned(
                        bottom: AppSpacing.xl,
                        left: AppSpacing.xl,
                        right: AppSpacing.xl,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Avatar
                            Container(
                              width: 64,
                              height: 64,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: AppRadius.md,
                                boxShadow: AppShadows.md,
                              ),
                              child: Text(
                                initial,
                                style: AppTextStyles.headline.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            // Name + email
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    club.name,
                                    style: AppTextStyles.title.copyWith(
                                      color: AppColors.textOnPrimary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.mail_outline,
                                        size: 12,
                                        color: AppColors.textOnPrimary,
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      Expanded(
                                        child: Text(
                                          club.contactEmail,
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.textOnPrimary
                                                .withValues(alpha: 0.8),
                                          ),
                                          overflow: TextOverflow.ellipsis,
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
                    ],
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(height: 1, color: AppColors.border),
                ),
              ),

              // ── Body content ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width >=
                                AppBreakpoints.wide
                            ? AppSpacing.maxContentWidth
                            : double.infinity,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // About section
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: AppRadius.lg,
                              border: Border.all(color: AppColors.border),
                              boxShadow: AppShadows.sm,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      'About this club',
                                      style: AppTextStyles.label
                                          .copyWith(color: AppColors.primary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  club.description,
                                  style: AppTextStyles.bodySecondary.copyWith(
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Follow / Unfollow button
                          if (isStudent) ...[
                            isFollowing
                                ? AppSecondaryButton(
                                    label: 'Following',
                                    icon: const Icon(Icons.check),
                                    iconPosition: AppButtonIconPosition.left,
                                    fullWidth: true,
                                    onPressed: () => ref
                                        .read(followedClubsProvider.notifier)
                                        .toggle(clubId),
                                  )
                                : AppPrimaryButton(
                                    label: 'Follow',
                                    icon: const Icon(Icons.add),
                                    iconPosition: AppButtonIconPosition.left,
                                    fullWidth: true,
                                    onPressed: () => ref
                                        .read(followedClubsProvider.notifier)
                                        .toggle(clubId),
                                  ),
                            const SizedBox(height: AppSpacing.xl),
                          ],

                          // Upcoming events section
                          const SectionHeader(
                            title: 'Upcoming Events',
                            subtitle: 'Events from this club',
                          ),
                          const SizedBox(height: AppSpacing.md),

                          eventsAsync.when(
                            loading: () => const LoadingState(
                                message: 'Loading events...'),
                            error: (e, _) => ErrorState(
                              message: 'Could not load events.',
                              onRetry: () => ref.invalidate(
                                  clubUpcomingEventsProvider(clubId)),
                            ),
                            data: (events) {
                              if (events.isEmpty) {
                                return const EmptyState(
                                  icon: Icon(Icons.event_busy_outlined),
                                  title: 'No upcoming events',
                                  description:
                                      'This club has no upcoming events right now. Follow it to get notified when they publish new events.',
                                );
                              }
                              final favIds =
                                  ref.watch(favouritesProvider).valueOrNull ??
                                      {};
                              return Column(
                                children: events
                                    .map((e) => Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: AppSpacing.md),
                                          child: EventCard(
                                            event: e,
                                            isFavourite: favIds.contains(e.id),
                                            showFavouriteButton: isStudent,
                                            onTap: () =>
                                                context.push('/event/${e.id}'),
                                            onToggleFavourite: () => ref
                                                .read(
                                                    favouritesProvider.notifier)
                                                .toggle(e.id),
                                          ),
                                        ))
                                    .toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
