import 'package:campus_event_hub/app/theme.dart';
import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/core/widgets/widgets.dart';
import 'package:campus_event_hub/features/events/domain/event.dart';
import 'package:campus_event_hub/features/events/presentation/controllers/events_controllers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

enum _MyEventsTab { upcoming, past }

class MyEventsScreen extends ConsumerStatefulWidget {
  const MyEventsScreen({super.key});

  @override
  ConsumerState<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends ConsumerState<MyEventsScreen> {
  _MyEventsTab _selectedTab = _MyEventsTab.upcoming;

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(upcomingEventsProvider);
    final enrolmentsAsync = ref.watch(enrolmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Events'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: eventsAsync.when(
        loading: () => const LoadingState(message: 'Loading your events...'),
        error: (e, _) => ErrorState(
          message: 'Could not load your events.',
          onRetry: () {
            ref.invalidate(upcomingEventsProvider);
            ref.read(enrolmentsProvider.notifier).refresh();
          },
        ),
        data: (events) {
          return enrolmentsAsync.when(
            loading: () =>
                const LoadingState(message: 'Loading your registrations...'),
            error: (e, _) => ErrorState(
              message: 'Could not load your registrations.',
              onRetry: () {
                ref.invalidate(upcomingEventsProvider);
                ref.read(enrolmentsProvider.notifier).refresh();
              },
            ),
            data: (enrolments) {
              final myEvents =
                  events.where((e) => enrolments.containsKey(e.id)).toList();

              final now = DateTime.now();

              final upcomingEvents = myEvents
                  .where((event) => event.startAt.isAfter(now))
                  .toList()
                ..sort((a, b) => a.startAt.compareTo(b.startAt));

              final pastEvents = myEvents
                  .where((event) => event.startAt.isBefore(now))
                  .toList()
                ..sort((a, b) => b.startAt.compareTo(a.startAt));

              final isUpcoming = _selectedTab == _MyEventsTab.upcoming;
              final currentList = isUpcoming ? upcomingEvents : pastEvents;

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  ref.invalidate(upcomingEventsProvider);
                  await ref.read(enrolmentsProvider.notifier).refresh();
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  children: [
                    // Segmented Tab Selector
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.full,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _SegmentTab(
                              label: 'Upcoming',
                              selected: isUpcoming,
                              onTap: () => setState(
                                  () => _selectedTab = _MyEventsTab.upcoming),
                            ),
                          ),
                          Expanded(
                            child: _SegmentTab(
                              label: 'Past',
                              selected: !isUpcoming,
                              onTap: () => setState(
                                  () => _selectedTab = _MyEventsTab.past),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Section Header with count
                    SectionHeader(
                      title: isUpcoming ? 'Upcoming Events' : 'Past Events',
                      subtitle:
                          '${currentList.length} event${currentList.length == 1 ? '' : 's'}',
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Content List or Empty State
                    if (currentList.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: EmptyState(
                          icon: Icon(
                            isUpcoming
                                ? Icons.event_available_outlined
                                : Icons.history_outlined,
                          ),
                          title: isUpcoming
                              ? 'No Upcoming Events'
                              : 'No Past Events',
                          description: isUpcoming
                              ? "You don't have any upcoming registered events."
                              : "You don't have any past registered events.",
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: currentList.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, i) {
                          final event = currentList[i];
                          final enrolment = enrolments[event.id]!;
                          return _MyEventCard(
                            event: event,
                            attendanceStatus: enrolment.attendanceStatus,
                            isPast: !isUpcoming,
                            onTap: () => context.push('/event/${event.id}'),
                            onQrPass: () => context
                                .push('/student/my-events/${event.id}/qr'),
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : Colors.transparent,
      borderRadius: AppRadius.full,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.full,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: selected
                  ? AppColors.textOnPrimary
                  : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _MyEventCard extends StatelessWidget {
  final EventModel event;
  final AttendanceStatus attendanceStatus;
  final bool isPast;
  final VoidCallback onTap;
  final VoidCallback onQrPass;

  const _MyEventCard({
    required this.event,
    required this.attendanceStatus,
    required this.isPast,
    required this.onTap,
    required this.onQrPass,
  });

  @override
  Widget build(BuildContext context) {
    final isAttended = attendanceStatus == AttendanceStatus.attended;
    final dateFmt = DateFormat('EEE, d MMM · h:mm a');

    final badgeLabel = isPast
        ? (isAttended ? 'Attended' : 'Completed')
        : (isAttended ? 'Attended' : 'Registered');

    final badgeTone = isPast
        ? (isAttended ? AppBadgeTone.success : AppBadgeTone.neutral)
        : (isAttended ? AppBadgeTone.success : AppBadgeTone.warning);

    final badgeIcon = isPast
        ? (isAttended
            ? Icons.check_circle_outline
            : Icons.event_available_outlined)
        : (isAttended
            ? Icons.check_circle_outline
            : Icons.confirmation_number_outlined);

    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.lg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lg,
        child: Container(
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
              // Header badges: Category & Attendance status
              Row(
                children: [
                  Flexible(
                    child: AppBadge(
                      label: event.categoryName,
                      tone: AppBadgeTone.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Spacer(),
                  AppBadge(
                    label: badgeLabel,
                    tone: badgeTone,
                    icon: Icon(
                      badgeIcon,
                      size: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Title
              Text(
                event.title,
                style: AppTextStyles.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Meta details: Date & Venue
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      dateFmt.format(event.startAt),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      event.venue,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: AppSpacing.md),

              // Bottom row: Club name + QR Pass button (only for upcoming)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.clubName,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!isPast) ...[
                    const SizedBox(width: AppSpacing.md),
                    AppPrimaryButton(
                      label: 'QR Pass',
                      icon: const Icon(Icons.qr_code_rounded, size: 16),
                      iconPosition: AppButtonIconPosition.left,
                      onPressed: onQrPass,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
