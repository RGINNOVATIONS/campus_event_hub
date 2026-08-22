import 'package:campus_event_hub/app/providers.dart';
import 'package:campus_event_hub/app/theme.dart';
import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/core/widgets/widgets.dart';
import 'package:campus_event_hub/features/events/domain/event.dart';
import 'package:campus_event_hub/features/organizer/presentation/screens/create_event_screen.dart';
import 'package:campus_event_hub/features/organizer/presentation/screens/event_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final organizerEventsProvider =
    FutureProvider.autoDispose<List<EventModel>>((ref) async {
  final repo = ref.watch(organizerRepositoryProvider);
  final result = await repo.myClubEvents();
  return result.when(ok: (v) => v, err: (f) => throw f);
});

class OrganizerEventsScreen extends ConsumerWidget {
  const OrganizerEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(organizerEventsProvider);

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

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, i) {
              final e = events[i];
              return _OrganizerEventCard(
                event: e,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EventManagementScreen(event: e),
                  ),
                ),
                onEdit: (e.status == EventStatus.draft ||
                        e.status == EventStatus.pendingApproval ||
                        e.status == EventStatus.rejected)
                    ? () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CreateEventScreen(existing: e),
                          ),
                        )
                    : null,
                onDelete: (e.status == EventStatus.draft ||
                        e.status == EventStatus.pendingApproval ||
                        e.status == EventStatus.rejected)
                    ? () => _confirmAndDelete(context, ref, e)
                    : null,
              );
            },
          );
        },
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
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _OrganizerEventCard({
    required this.event,
    required this.onTap,
    this.onEdit,
    this.onDelete,
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
              // Header: Category chip & Status badge
              Row(
                children: [
                  AppBadge(
                    label: event.categoryName,
                    tone: AppBadgeTone.primary,
                  ),
                  const Spacer(),
                  _StatusBadge(status: event.status),
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

              // Manage link
              Row(
                children: [
                  Text(
                    'Manage Event',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const Spacer(),
                  if (onEdit != null)
                    InkWell(
                      onTap: onEdit,
                      borderRadius: AppRadius.sm,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.edit_outlined,
                              size: 14,
                              color: AppColors.textPrimary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Edit',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (onDelete != null)
                    InkWell(
                      onTap: onDelete,
                      borderRadius: AppRadius.sm,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete_outline_rounded,
                              size: 14,
                              color: AppColors.danger,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Delete',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
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
