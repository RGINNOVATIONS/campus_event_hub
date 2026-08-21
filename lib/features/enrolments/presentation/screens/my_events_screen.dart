import 'package:campus_pulse/app/theme.dart';
import 'package:campus_pulse/core/domain/enums.dart';
import 'package:campus_pulse/core/widgets/widgets.dart';
import 'package:campus_pulse/features/events/domain/event.dart';
import 'package:campus_pulse/features/events/presentation/controllers/events_controllers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class MyEventsScreen extends ConsumerWidget {
  const MyEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          onRetry: () => ref.invalidate(upcomingEventsProvider),
        ),
        data: (events) {
          final enrolments = enrolmentsAsync.valueOrNull ?? {};
          final myEvents =
              events.where((e) => enrolments.containsKey(e.id)).toList();

          if (myEvents.isEmpty) {
            return const EmptyState(
              icon: Icon(Icons.event_busy_outlined),
              title: 'No registered events',
              description:
                  'You have not enrolled in any events yet. Explore upcoming campus events and register to attend.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: myEvents.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, i) {
              final event = myEvents[i];
              final enrolment = enrolments[event.id]!;
              return _MyEventCard(
                event: event,
                attendanceStatus: enrolment.attendanceStatus,
                onTap: () => context.push('/event/${event.id}'),
                onQrPass: () =>
                    context.push('/student/my-events/${event.id}/qr'),
              );
            },
          );
        },
      ),
    );
  }
}

class _MyEventCard extends StatelessWidget {
  final EventModel event;
  final AttendanceStatus attendanceStatus;
  final VoidCallback onTap;
  final VoidCallback onQrPass;

  const _MyEventCard({
    required this.event,
    required this.attendanceStatus,
    required this.onTap,
    required this.onQrPass,
  });

  @override
  Widget build(BuildContext context) {
    final isAttended = attendanceStatus == AttendanceStatus.attended;
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
              // Header badges: Category & Attendance status
              Row(
                children: [
                  AppBadge(
                    label: event.categoryName,
                    tone: AppBadgeTone.primary,
                  ),
                  const Spacer(),
                  AppBadge(
                    label: isAttended ? 'Attended' : 'Registered',
                    tone: isAttended
                        ? AppBadgeTone.success
                        : AppBadgeTone.warning,
                    icon: Icon(
                      isAttended
                          ? Icons.check_circle_outline
                          : Icons.confirmation_number_outlined,
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
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: AppSpacing.md),

              // Bottom row: Club name + QR Pass button
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
                  const SizedBox(width: AppSpacing.md),
                  AppPrimaryButton(
                    label: 'QR Pass',
                    icon: const Icon(Icons.qr_code_rounded, size: 16),
                    iconPosition: AppButtonIconPosition.left,
                    onPressed: onQrPass,
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
