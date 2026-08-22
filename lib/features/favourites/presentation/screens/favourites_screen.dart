import 'package:campus_event_hub/app/theme.dart';
import 'package:campus_event_hub/core/widgets/app_search_field.dart';
import 'package:campus_event_hub/core/widgets/empty_state.dart';
import 'package:campus_event_hub/core/widgets/error_state.dart';
import 'package:campus_event_hub/core/widgets/loading_state.dart';
import 'package:campus_event_hub/core/widgets/section_header.dart';
import 'package:campus_event_hub/features/events/domain/event.dart';
import 'package:campus_event_hub/features/events/presentation/controllers/events_controllers.dart';
import 'package:campus_event_hub/features/events/presentation/widgets/event_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class FavouritesScreen extends ConsumerStatefulWidget {
  const FavouritesScreen({super.key});

  @override
  ConsumerState<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends ConsumerState<FavouritesScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(upcomingEventsProvider);
    final favouritesAsync = ref.watch(favouritesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favourites')),
      body: eventsAsync.when(
        loading: () => const LoadingState(message: 'Loading saved events...'),
        error: (e, _) => ErrorState(
          title: 'Favourites unavailable',
          message: 'Could not load favourites.',
          onRetry: () => ref.invalidate(upcomingEventsProvider),
        ),
        data: (events) {
          final favIds = favouritesAsync.valueOrNull ?? {};
          final favEvents = events.where((e) => favIds.contains(e.id)).toList();
          final filtered = _filteredFavourites(favEvents);
          final contentWidth =
              MediaQuery.of(context).size.width >= AppBreakpoints.wide
                  ? AppSpacing.maxContentWidth
                  : double.infinity;

          if (favEvents.isEmpty) {
            return const EmptyState(
              icon: Icon(Icons.favorite_border),
              title: 'No favourites yet',
              description:
                  'Tap the heart on any event to save it here for later.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(upcomingEventsProvider);
              ref.invalidate(favouritesProvider);
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentWidth),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(
                            title: 'Saved Events',
                            subtitle:
                                'Your favourite campus events, ready when you are.',
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppSearchField(
                            controller: _searchController,
                            hintText: 'Search favourites...',
                            onChanged: (value) =>
                                setState(() => _query = value),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          if (filtered.isEmpty)
                            const EmptyState(
                              icon: Icon(Icons.search_off_outlined),
                              title: 'No favourites match your search',
                              description:
                                  'Try a different event name, venue, club, or category.',
                            )
                          else
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final width = constraints.maxWidth;
                                final crossAxisCount =
                                    width >= AppBreakpoints.wide
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
                                      isFavourite: true,
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

  List<EventModel> _filteredFavourites(List<EventModel> events) {
    final normalizedQuery = _query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return events;

    return events.where((event) {
      final haystack = [
        event.title,
        event.shortDescription,
        event.fullDescription,
        event.categoryName,
        event.clubName,
        event.venue,
      ].join(' ').toLowerCase();
      return haystack.contains(normalizedQuery);
    }).toList();
  }
}
