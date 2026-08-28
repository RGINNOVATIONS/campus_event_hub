import 'package:campus_event_hub/app/providers.dart';
import 'package:campus_event_hub/app/theme.dart';
import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/core/widgets/widgets.dart';
import 'package:campus_event_hub/features/events/domain/event.dart';
import 'package:campus_event_hub/features/organizer/presentation/screens/create_event_screen.dart';
import 'package:campus_event_hub/features/organizer/presentation/screens/event_management_screen.dart';
import 'package:campus_event_hub/features/organizer/presentation/widgets/postpone_event_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final organizerEventsProvider =
    FutureProvider.autoDispose<List<EventModel>>((ref) async {
  final repo = ref.watch(organizerRepositoryProvider);
  final result = await repo.myClubEvents();
  return result.when(ok: (v) => v, err: (f) => throw f);
});

final organizerEventsFilterProvider =
    StateProvider<EventStatus?>((ref) => null);

class OrganizerEventsScreen extends ConsumerWidget {
  const OrganizerEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(organizerEventsProvider);
    final currentFilter = ref.watch(organizerEventsFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Events'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        actions: const [OrganizerProfileButton()],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const CreateEventScreen(),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Create Event'),
      ),
      body: eventsAsync.when(
        loading: () =>
            const LoadingState(message: 'Loading your club events...'),
        error: (e, _) => ErrorState(
          message: 'Could not load your events.',
          onRetry: () => ref.invalidate(organizerEventsProvider),
        ),
        data: (events) {
          if (events.isEmpty) {
            return const EmptyState(
              icon: Icon(Icons.event_note_outlined),
              title: 'No events yet',
              description:
                  'You have not created any events for your club yet. Tap "+ Create Event" to draft your first event.',
            );
          }

          final publishedCount =
              events.where((e) => e.status == EventStatus.published).length;
          final pendingCount = events
              .where((e) => e.status == EventStatus.pendingApproval)
              .length;
          final postponedCount =
              events.where((e) => e.status == EventStatus.postponed).length;
          final completedCount =
              events.where((e) => e.status == EventStatus.completed).length;
          final draftCount =
              events.where((e) => e.status == EventStatus.draft).length;

          final filteredEvents = currentFilter == null
              ? events
              : events.where((e) => e.status == currentFilter).toList();

          return Column(
            children: [
              // Filter chips bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    bottom: BorderSide(color: AppColors.border),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterTabChip(
                        label: 'All (${events.length})',
                        selected: currentFilter == null,
                        onTap: () => ref
                            .read(organizerEventsFilterProvider.notifier)
                            .state = null,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _FilterTabChip(
                        label: 'Published ($publishedCount)',
                        selected: currentFilter == EventStatus.published,
                        onTap: () => ref
                            .read(organizerEventsFilterProvider.notifier)
                            .state = EventStatus.published,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _FilterTabChip(
                        label: 'Pending ($pendingCount)',
                        selected: currentFilter == EventStatus.pendingApproval,
                        onTap: () => ref
                            .read(organizerEventsFilterProvider.notifier)
                            .state = EventStatus.pendingApproval,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _FilterTabChip(
                        label: 'Postponed ($postponedCount)',
                        selected: currentFilter == EventStatus.postponed,
                        onTap: () => ref
                            .read(organizerEventsFilterProvider.notifier)
                            .state = EventStatus.postponed,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _FilterTabChip(
                        label: 'Completed ($completedCount)',
                        selected: currentFilter == EventStatus.completed,
                        onTap: () => ref
                            .read(organizerEventsFilterProvider.notifier)
                            .state = EventStatus.completed,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _FilterTabChip(
                        label: 'Drafts ($draftCount)',
                        selected: currentFilter == EventStatus.draft,
                        onTap: () => ref
                            .read(organizerEventsFilterProvider.notifier)
                            .state = EventStatus.draft,
                      ),
                    ],
                  ),
                ),
              ),

              // Events list or empty filtered state
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(organizerEventsProvider);
                  },
                  child: filteredEvents.isEmpty
                      ? ListView(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.xxl),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      color: AppColors.surfaceElevated,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.filter_alt_off_outlined,
                                      color: AppColors.textMuted,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  const Text(
                                    'No events found in this category',
                                    style: AppTextStyles.title,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  const Text(
                                    'No events match the selected status filter.',
                                    style: AppTextStyles.bodySecondary,
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  AppSecondaryButton(
                                    label: 'Show All Events',
                                    onPressed: () => ref
                                        .read(organizerEventsFilterProvider
                                            .notifier)
                                        .state = null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          itemCount: filteredEvents.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, i) {
                            final e = filteredEvents[i];
                            return _OrganizerEventCard(
                              event: e,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EventManagementScreen(event: e),
                                ),
                              ),
                              onEdit: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CreateEventScreen(existing: e),
                                ),
                              ),
                              onDelete: () =>
                                  _confirmAndDelete(context, ref, e),
                              onPostpone: (e.status == EventStatus.published ||
                                      e.status == EventStatus.postponed)
                                  ? () => PostponeEventDialog.show(context, e)
                                  : null,
                            );
                          },
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

class _FilterTabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterTabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.full,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs + 2,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surfaceElevated,
            borderRadius: AppRadius.full,
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.textOnPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _confirmAndDelete(
    BuildContext context, WidgetRef ref, EventModel event) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lg,
      ),
      title: const Text('Delete Event?'),
      content: Text(
        'Are you sure you want to delete "${event.title}"? This action cannot be undone.',
        style: AppTextStyles.bodySecondary,
      ),
      actions: [
        AppSecondaryButton(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context, false),
        ),
        AppPrimaryButton(
          label: 'Delete',
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  if (!context.mounted) return;

  final result =
      await ref.read(organizerRepositoryProvider).deleteEvent(event.id);
  if (!context.mounted) return;
  
  result.when(
    ok: (_) {
      ref.invalidate(organizerEventsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event deleted successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
    },
    err: (f) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(f.message),
        backgroundColor: AppColors.danger,
      ),
    ),
  );
}

class _OrganizerEventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onPostpone;

  const _OrganizerEventCard({
    required this.event,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.onPostpone,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEE, d MMM · h:mm a');

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
              // Header: Category chip, Status badge & More Popup
              Row(
                children: [
                  AppBadge(
                    label: event.categoryName,
                    tone: AppBadgeTone.primary,
                  ),
                  const Spacer(),
                  _StatusBadge(status: event.status),
                  const SizedBox(width: AppSpacing.xs),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    padding: EdgeInsets.zero,
                    color: AppColors.surface,
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
                    onSelected: (val) {
                      switch (val) {
                        case 'manage':
                          onTap();
                          break;
                        case 'edit':
                          onEdit();
                          break;
                        case 'postpone':
                          onPostpone?.call();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'manage',
                        child: Row(
                          children: [
                            Icon(Icons.dashboard_customize_outlined,
                                size: 18, color: AppColors.textPrimary),
                            SizedBox(width: AppSpacing.sm),
                            Text('Manage Event'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined,
                                size: 18, color: AppColors.textPrimary),
                            SizedBox(width: AppSpacing.sm),
                            Text('Edit Event'),
                          ],
                        ),
                      ),
                      if (onPostpone != null)
                        const PopupMenuItem(
                          value: 'postpone',
                          child: Row(
                            children: [
                              Icon(Icons.update_rounded,
                                  size: 18, color: AppColors.warning),
                              SizedBox(width: AppSpacing.sm),
                              Text('Postpone Event'),
                            ],
                          ),
                        ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded,
                                size: 18, color: AppColors.danger),
                            SizedBox(width: AppSpacing.sm),
                            Text(
                              'Delete Event',
                              style: TextStyle(color: AppColors.danger),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Title
              Text(
                event.title,
                style: AppTextStyles.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Timing & Venue
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    dateFmt.format(event.startAt),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
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

              // Postponed notice
              if (event.status == EventStatus.postponed) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: AppRadius.sm,
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.update_rounded,
                        color: AppColors.warning,
                        size: 16,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          event.postponementReason != null &&
                                  event.postponementReason!.isNotEmpty
                              ? 'Postponed: ${event.postponementReason}'
                              : 'Event has been rescheduled.',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.warning,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Rejection alert callout
              if (event.status == EventStatus.rejected &&
                  event.rejectionReason != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: AppRadius.sm,
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.danger,
                        size: 16,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Rejected: ${event.rejectionReason}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: AppSpacing.md),

              // Action Buttons Row: [Manage] [Edit] [Postpone] [Delete]
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _CardActionButton(
                    icon: Icons.dashboard_customize_outlined,
                    label: 'Manage',
                    color: AppColors.primary,
                    onTap: onTap,
                  ),
                  _CardActionButton(
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    color: AppColors.textPrimary,
                    onTap: onEdit,
                  ),
                  if (onPostpone != null)
                    _CardActionButton(
                      icon: Icons.update_rounded,
                      label: 'Postpone',
                      color: AppColors.warning,
                      onTap: onPostpone!,
                    ),
                  _CardActionButton(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete',
                    color: AppColors.danger,
                    onTap: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CardActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.sm,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 2,
            vertical: AppSpacing.xs + 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: AppRadius.sm,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final EventStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    AppBadgeTone tone;
    String label;
    IconData? icon;

    switch (status) {
      case EventStatus.published:
        tone = AppBadgeTone.success;
        label = 'Published';
        icon = Icons.check_circle_outline;
        break;
      case EventStatus.postponed:
        tone = AppBadgeTone.warning;
        label = 'Postponed';
        icon = Icons.update_rounded;
        break;
      case EventStatus.pendingApproval:
        tone = AppBadgeTone.warning;
        label = 'Pending approval';
        icon = Icons.hourglass_top_outlined;
        break;
      case EventStatus.rejected:
        tone = AppBadgeTone.danger;
        label = 'Rejected';
        icon = Icons.cancel_outlined;
        break;
      case EventStatus.cancelled:
        tone = AppBadgeTone.danger;
        label = 'Cancelled';
        icon = Icons.block_outlined;
        break;
      case EventStatus.completed:
        tone = AppBadgeTone.neutral;
        label = 'Completed';
        icon = Icons.task_alt;
        break;
      case EventStatus.draft:
        tone = AppBadgeTone.neutral;
        label = 'Draft';
        icon = Icons.edit_note_outlined;
        break;
    }

    return AppBadge(
      label: label,
      tone: tone,
      icon: Icon(icon, size: 13),
    );
  }
}
