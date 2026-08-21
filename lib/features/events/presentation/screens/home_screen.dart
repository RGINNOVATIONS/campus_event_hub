import 'package:campus_pulse/app/providers.dart';
import 'package:campus_pulse/app/theme.dart';
import 'package:campus_pulse/core/domain/enums.dart';
import 'package:campus_pulse/core/widgets/app_badge.dart';
import 'package:campus_pulse/core/widgets/app_search_field.dart';
import 'package:campus_pulse/core/widgets/empty_state.dart';
import 'package:campus_pulse/core/widgets/error_state.dart';
import 'package:campus_pulse/core/widgets/event_category_chip.dart';
import 'package:campus_pulse/core/widgets/event_poster_container.dart';
import 'package:campus_pulse/core/widgets/loading_state.dart';
import 'package:campus_pulse/core/widgets/section_header.dart';
import 'package:campus_pulse/features/clubs/presentation/controllers/club_controllers.dart';
import 'package:campus_pulse/features/events/domain/event.dart';
import 'package:campus_pulse/features/events/domain/event_repository.dart';
import 'package:campus_pulse/features/events/presentation/controllers/events_controllers.dart';
import 'package:campus_pulse/features/events/presentation/widgets/event_card.dart';
import 'package:campus_pulse/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final eventsAsync = ref.watch(upcomingEventsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final favouritesAsync = ref.watch(favouritesProvider);
    final followedClubs = ref.watch(followedClubsProvider).valueOrNull ?? {};
    final followedCategories =
        ref.watch(followedCategoriesProvider).valueOrNull ?? {};
    final filter = ref.watch(feedFilterProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: AppSpacing.mobileHeaderHeight,
        titleSpacing: AppSpacing.lg,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hi, ${profile?.fullName.split(' ').first ?? 'there'}',
              style: AppTextStyles.title,
            ),
            const Text(
              'Find your next campus moment',
              style: AppTextStyles.caption,
            ),
          ],
        ),
        actions: [
          if (profile?.role == UserRole.student)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: IconButton(
                icon: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text('$unreadCount'),
                  backgroundColor: AppColors.primary,
                  textColor: AppColors.textOnPrimary,
                  child: const Icon(Icons.notifications_outlined),
                ),
                onPressed: () => context.push('/student/notifications'),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(upcomingEventsProvider);
          ref.invalidate(categoriesProvider);
        },
        child: eventsAsync.when(
          loading: () =>
              const LoadingState(message: 'Loading campus events...'),
          error: (e, _) => ErrorState(
            title: 'Events unavailable',
            message: 'Could not load events.',
            onRetry: () => ref.invalidate(upcomingEventsProvider),
          ),
          data: (events) {
            final filtered = _filteredEvents(
              events: events,
              filter: filter,
              followedClubs: followedClubs,
              followedCategories: followedCategories,
            );
            final favIds = favouritesAsync.valueOrNull ?? {};
            final featured = filtered.isNotEmpty ? filtered.first : null;
            final contentWidth =
                MediaQuery.of(context).size.width >= AppBreakpoints.wide
                    ? AppSpacing.maxContentWidth
                    : double.infinity;

            return ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentWidth),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: 'Explore Categories',
                            subtitle: 'Filter events by your interests.',
                            action: TextButton(
                              onPressed: () => ref
                                  .read(feedFilterProvider.notifier)
                                  .state = filter.copyWith(clearCategory: true),
                              child: const Text('Clear'),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          categoriesAsync.when(
                            loading: () => const LoadingState(compact: true),
                            error: (_, __) => const SizedBox.shrink(),
                            data: (categories) => _CategoryScroller(
                              categories: categories,
                              filter: filter,
                              showFollowing: profile?.role == UserRole.student,
                              onFollowing: (value) =>
                                  ref.read(feedFilterProvider.notifier).state =
                                      filter.copyWith(followingOnly: value),
                              onCategory: (categoryId) =>
                                  ref.read(feedFilterProvider.notifier).state =
                                      categoryId == null
                                          ? filter.copyWith(clearCategory: true)
                                          : filter.copyWith(
                                              categoryId: categoryId,
                                            ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          if (featured != null)
                            _FeaturedEventCard(
                              event: featured,
                              onTap: () =>
                                  context.push('/event/${featured.id}'),
                            ),
                          if (featured != null)
                            const SizedBox(height: AppSpacing.xl),
                          AppSearchField(
                            controller: _searchController,
                            hintText: 'Search events...',
                            onChanged: (value) =>
                                setState(() => _query = value),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          SectionHeader(
                            title: 'Upcoming Events',
                            subtitle:
                                '${filtered.length} event${filtered.length == 1 ? '' : 's'} available',
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ),
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  const EmptyState(
                    icon: Icon(Icons.event_busy_outlined),
                    title: 'No upcoming events match your filters.',
                    description:
                        'Try another search term, category, or following filter.',
                  )
                else
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentWidth),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final crossAxisCount = width >= AppBreakpoints.wide
                                ? 3
                                : width >= AppBreakpoints.tablet
                                    ? 2
                                    : 1;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisExtent: 380,
                                crossAxisSpacing: AppSpacing.lg,
                                mainAxisSpacing: AppSpacing.lg,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, i) {
                                final event = filtered[i];
                                return EventCard(
                                  event: event,
                                  isFavourite: favIds.contains(event.id),
                                  showFavouriteButton: profile?.role == UserRole.student,
                                  onTap: () =>
                                      context.push('/event/${event.id}'),
                                  onToggleFavourite: () => ref
                                      .read(favouritesProvider.notifier)
                                      .toggle(event.id),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<EventModel> _filteredEvents({
    required List<EventModel> events,
    required FeedFilter filter,
    required Set<String> followedClubs,
    required Set<String> followedCategories,
  }) {
    final normalizedQuery = _query.trim().toLowerCase();
    return events.where((event) {
      if (filter.categoryId != null && event.categoryId != filter.categoryId) {
        return false;
      }
      if (filter.followingOnly) {
        final followsClub = followedClubs.contains(event.clubId);
        final followsCategory = followedCategories.contains(event.categoryId);
        if (!followsClub && !followsCategory) return false;
      }
      if (normalizedQuery.isNotEmpty) {
        final haystack = [
          event.title,
          event.shortDescription,
          event.fullDescription,
          event.categoryName,
          event.clubName,
          event.venue,
        ].join(' ').toLowerCase();
        if (!haystack.contains(normalizedQuery)) return false;
      }
      return true;
    }).toList();
  }
}

class _CategoryScroller extends StatelessWidget {
  final List<CategoryModel> categories;
  final FeedFilter filter;
  final bool showFollowing;
  final ValueChanged<bool> onFollowing;
  final ValueChanged<String?> onCategory;

  const _CategoryScroller({
    required this.categories,
    required this.filter,
    required this.showFollowing,
    required this.onFollowing,
    required this.onCategory,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (showFollowing) ...[
            EventCategoryChip(
              label: 'Following',
              selected: filter.followingOnly,
              compact: true,
              icon: const Icon(Icons.favorite_border),
              onTap: () => onFollowing(!filter.followingOnly),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          EventCategoryChip(
            label: 'All Categories',
            selected: filter.categoryId == null,
            compact: true,
            onTap: () => onCategory(null),
          ),
          ...categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: EventCategoryChip(
                label: category.name,
                selected: filter.categoryId == category.id,
                compact: true,
                onTap: () => onCategory(category.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedEventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;

  const _FeaturedEventCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM - h:mm a');
    return Material(
      color: AppColors.textPrimary,
      borderRadius: AppRadius.lg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lg,
        child: ClipRRect(
          borderRadius: AppRadius.lg,
          child: Stack(
            children: [
              EventPosterContainer(
                imageUrl: event.posterPath,
                aspectRatio:
                    MediaQuery.of(context).size.width >= AppBreakpoints.tablet
                        ? 21 / 7
                        : 16 / 9,
                borderRadius: AppRadius.lg,
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.textPrimary.withValues(alpha: 0.72),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: AppSpacing.lg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppBadge(
                        label: event.categoryName, tone: AppBadgeTone.primary),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headline.copyWith(
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _HeroMeta(
                          icon: Icons.calendar_today_outlined,
                          text: dateFmt.format(event.startAt),
                        ),
                        _HeroMeta(
                          icon: Icons.location_on_outlined,
                          text: event.venue,
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

class _HeroMeta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroMeta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.textOnPrimary),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textOnPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
