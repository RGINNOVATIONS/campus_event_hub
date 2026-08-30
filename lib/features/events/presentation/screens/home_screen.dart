import 'dart:async';

import 'package:campus_event_hub/app/providers.dart';
import 'package:campus_event_hub/app/theme.dart';
import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/core/widgets/app_badge.dart';
import 'package:campus_event_hub/core/widgets/app_search_field.dart';
import 'package:campus_event_hub/core/widgets/empty_state.dart';
import 'package:campus_event_hub/core/widgets/error_state.dart';
import 'package:campus_event_hub/core/widgets/event_poster_container.dart';
import 'package:campus_event_hub/core/widgets/loading_state.dart';
import 'package:campus_event_hub/core/widgets/section_header.dart';
import 'package:campus_event_hub/features/clubs/presentation/controllers/club_controllers.dart';
import 'package:campus_event_hub/features/events/domain/event.dart';
import 'package:campus_event_hub/features/events/domain/event_repository.dart';
import 'package:campus_event_hub/features/events/presentation/controllers/events_controllers.dart';
import 'package:campus_event_hub/features/events/presentation/widgets/event_card.dart';
import 'package:campus_event_hub/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final eventsAsync = ref.watch(openEventsProvider);
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
              style: AppTextStyles.headline.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Find your next campus moment',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          if (profile?.role == UserRole.student)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: Center(
                child: Material(
                  color: AppColors.surface,
                  shape: const CircleBorder(
                    side: BorderSide(color: AppColors.border),
                  ),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => context.push('/student/notifications'),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Badge(
                        isLabelVisible: unreadCount > 0,
                        label: Text('$unreadCount'),
                        backgroundColor: AppColors.primary,
                        textColor: AppColors.textOnPrimary,
                        child: const Icon(
                          Icons.notifications_outlined,
                          size: 22,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(openEventsProvider);
          ref.invalidate(categoriesProvider);
          await ref.read(favouritesProvider.notifier).refresh();
        },
        child: eventsAsync.when(
          loading: () =>
              const LoadingState(message: 'Loading campus events...'),
          error: (e, _) => ErrorState(
            title: 'Events unavailable',
            message: 'Could not load events.',
            onRetry: () => ref.invalidate(openEventsProvider),
          ),
          data: (events) {
            final filtered = _filteredEvents(
              events: events,
              filter: filter,
              followedClubs: followedClubs,
              followedCategories: followedCategories,
            );
            final favIds = favouritesAsync.valueOrNull ?? {};
            final carouselEvents =
                _selectCarouselEvents(filtered.isNotEmpty ? filtered : events);
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
                          if (carouselEvents.isNotEmpty)
                            _FeaturedPosterCarousel(
                              events: carouselEvents,
                              onEventTap: (event) =>
                                  context.push('/event/${event.id}'),
                            ),
                          if (carouselEvents.isNotEmpty)
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
                        padding: const EdgeInsets.only(
                          left: AppSpacing.lg,
                          right: AppSpacing.lg,
                          bottom: AppSpacing.xxl,
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            if (width < AppBreakpoints.tablet) {
                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filtered.length,
                                separatorBuilder: (context, _) =>
                                    const SizedBox(height: AppSpacing.lg),
                                itemBuilder: (context, i) {
                                  final event = filtered[i];
                                  return EventCard(
                                    event: event,
                                    isFavourite: favIds.contains(event.id),
                                    showFavouriteButton:
                                        profile?.role == UserRole.student,
                                    onTap: () =>
                                        context.push('/event/${event.id}'),
                                    onToggleFavourite: () => ref
                                        .read(favouritesProvider.notifier)
                                        .toggle(event.id),
                                  );
                                },
                              );
                            }
                            final crossAxisCount =
                                width >= AppBreakpoints.wide ? 3 : 2;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisExtent: 440,
                                crossAxisSpacing: AppSpacing.lg,
                                mainAxisSpacing: AppSpacing.lg,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, i) {
                                final event = filtered[i];
                                return EventCard(
                                  event: event,
                                  isFavourite: favIds.contains(event.id),
                                  showFavouriteButton:
                                      profile?.role == UserRole.student,
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

  List<EventModel> _selectCarouselEvents(List<EventModel> events) {
    final now = DateTime.now();
    final eligible = events.where((e) {
      final isUpcoming = now.isBefore(e.startAt);
      final isRegistrationOpen = now.isBefore(e.registrationDeadline);
      final isValidStatus = e.status == EventStatus.published ||
          e.status == EventStatus.postponed;
      return isValidStatus && isUpcoming && isRegistrationOpen;
    }).toList();

    final sorted = List<EventModel>.from(eligible)
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    return sorted.take(5).toList();
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
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (showFollowing) ...[
            _HomeCategoryChip(
              label: 'Following',
              selected: filter.followingOnly,
              icon: Icon(
                filter.followingOnly ? Icons.favorite : Icons.favorite_border,
              ),
              onTap: () => onFollowing(!filter.followingOnly),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          _HomeCategoryChip(
            label: 'All Categories',
            selected: filter.categoryId == null,
            onTap: () => onCategory(null),
          ),
          ...categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: _HomeCategoryChip(
                label: category.name,
                selected: filter.categoryId == category.id,
                onTap: () => onCategory(category.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeCategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Widget? icon;
  final VoidCallback? onTap;

  const _HomeCategoryChip({
    required this.label,
    this.selected = false,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background = selected ? const Color(0xFFFFEBEE) : AppColors.surface;
    final foreground =
        selected ? const Color(0xFFC62828) : AppColors.textSecondary;
    final borderColor = selected ? const Color(0xFFE57373) : AppColors.border;

    return Material(
      color: background,
      borderRadius: AppRadius.full,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.full,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.full,
            border: Border.all(
              color: borderColor,
              width: selected ? 1.2 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                IconTheme.merge(
                  data: IconThemeData(size: 14, color: foreground),
                  child: icon!,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label.copyWith(
                  color: foreground,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedPosterCarousel extends StatefulWidget {
  final List<EventModel> events;
  final void Function(EventModel event) onEventTap;

  const _FeaturedPosterCarousel({
    required this.events,
    required this.onEventTap,
  });

  @override
  State<_FeaturedPosterCarousel> createState() =>
      _FeaturedPosterCarouselState();
}

class _FeaturedPosterCarouselState extends State<_FeaturedPosterCarousel> {
  late final PageController _pageController;
  Timer? _autoSlideTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoSlide();
  }

  @override
  void didUpdateWidget(covariant _FeaturedPosterCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.events.length != widget.events.length) {
      if (_currentPage >= widget.events.length && widget.events.isNotEmpty) {
        _currentPage = 0;
      }
      _startAutoSlide();
    }
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    if (widget.events.length > 1) {
      _autoSlideTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        if (!_pageController.hasClients || widget.events.isEmpty) return;
        final nextPage = (_currentPage + 1) % widget.events.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.events.isEmpty) {
      return const SizedBox.shrink();
    }

    final isTablet = MediaQuery.of(context).size.width >= AppBreakpoints.tablet;
    final aspectRatio = isTablet ? 21 / 8 : 16 / 9;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: aspectRatio,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.events.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              final event = widget.events[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Material(
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => widget.onEventTap(event),
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        EventPosterContainer(
                          imageUrl: event.posterPath,
                          aspectRatio: aspectRatio,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        Positioned(
                          top: AppSpacing.md,
                          left: AppSpacing.md,
                          child: AppBadge(
                            label: event.categoryName,
                            tone: AppBadgeTone.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.events.length > 1) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.events.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentPage == index ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? const Color(0xFFC62828)
                      : const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
