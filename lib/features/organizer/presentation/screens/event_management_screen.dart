import 'package:campus_event_hub/app/providers.dart';
import 'package:campus_event_hub/app/theme.dart';
import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/core/widgets/widgets.dart';
import 'package:campus_event_hub/features/events/domain/event.dart';
import 'package:campus_event_hub/features/organizer/domain/organizer_repository.dart';
import 'package:campus_event_hub/features/organizer/presentation/screens/create_event_screen.dart';
import 'package:campus_event_hub/features/organizer/presentation/screens/organizer_events_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EventManagementScreen extends ConsumerStatefulWidget {
  final EventModel event;
  const EventManagementScreen({super.key, required this.event});

  @override
  ConsumerState<EventManagementScreen> createState() =>
      _EventManagementScreenState();
}

class _EventManagementScreenState extends ConsumerState<EventManagementScreen> {
  List<RegistrationRow>? _registrations;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(organizerRepositoryProvider);
    final result = await repo.registrationsFor(widget.event.id);
    if (mounted) setState(() => _registrations = result.valueOrNull ?? []);
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final totalCount = _registrations?.length ?? 0;
    final attendedCount = _registrations
            ?.where((r) => r.attendanceStatus == AttendanceStatus.attended)
            .length ??
        0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(event.title),
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
          // 1. Event Status Overview Card
          Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: AppColors.border),
              borderRadius: AppRadius.lg,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Text(
                    event.title,
                    style: AppTextStyles.headline,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    event.venue,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),

                  // Rejection Box
                  if (event.status == EventStatus.rejected &&
                      event.rejectionReason != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.dangerBg,
                        borderRadius: AppRadius.sm,
                        border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.danger,
                                size: 18,
                              ),
                              SizedBox(width: AppSpacing.xs),
                              Text(
                                'Rejection Reason',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            event.rejectionReason!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.danger,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppSecondaryButton(
                            label: 'Edit & Resubmit Event',
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            iconPosition: AppButtonIconPosition.left,
                            fullWidth: true,
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    CreateEventScreen(existing: event),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AppSecondaryButton(
                            label: 'Delete Event',
                            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                            iconPosition: AppButtonIconPosition.left,
                            fullWidth: true,
                            onPressed: _busy ? null : () => _confirmAndDelete(context),
                          ),
                        ],
                      ),
                    ),
                  ] else if (event.status == EventStatus.draft ||
                      event.status == EventStatus.pendingApproval) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: AppSecondaryButton(
                            label: 'Edit Event',
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            iconPosition: AppButtonIconPosition.left,
                            fullWidth: true,
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CreateEventScreen(existing: event),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppSecondaryButton(
                            label: 'Delete',
                            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                            iconPosition: AppButtonIconPosition.left,
                            fullWidth: true,
                            onPressed: _busy ? null : () => _confirmAndDelete(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // 2. Attendance & Metrics Summary
          Row(
            children: [
              Expanded(
                child: AppStatCard(
                  title: 'Total Registered',
                  value: '$totalCount',
                  icon: const Icon(Icons.people_alt_outlined),
                  filled: true,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppStatCard(
                  title: 'Verified Attended',
                  value: '$attendedCount',
                  icon: const Icon(Icons.check_circle_outline_rounded),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // 3. Registered Attendees List Card
          Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: AppColors.border),
              borderRadius: AppRadius.lg,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Registered Students',
                        style: AppTextStyles.title,
                      ),
                      const Spacer(),
                      AppBadge(
                        label: '$totalCount student(s)',
                        tone: AppBadgeTone.neutral,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: AppSpacing.sm),
                  if (_registrations == null)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: LoadingState(message: 'Loading registrations...'),
                    )
                  else if (_registrations!.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: EmptyState(
                        icon: Icon(Icons.people_outline_rounded),
                        title: 'No Registrations Yet',
                        description:
                            'Students will appear here once they enroll in this event.',
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _registrations!.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (context, i) {
                        final r = _registrations![i];
                        final isAttended =
                            r.attendanceStatus == AttendanceStatus.attended;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isAttended
                                      ? AppColors.successBg
                                      : AppColors.surfaceElevated,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isAttended
                                      ? Icons.check_circle_rounded
                                      : Icons.person_outline_rounded,
                                  color: isAttended
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.studentName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'ID: ${r.userId}',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AppBadge(
                                label: isAttended ? 'Attended' : 'Registered',
                                tone: isAttended
                                    ? AppBadgeTone.success
                                    : AppBadgeTone.neutral,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // 4. Lifecycle Actions (Mark Completed / Issue Certificates)
          if (event.status == EventStatus.published)
            AppPrimaryButton(
              label: 'Mark Event Completed',
              icon: const Icon(Icons.task_alt_rounded, size: 18),
              iconPosition: AppButtonIconPosition.left,
              isLoading: _busy,
              fullWidth: true,
              onPressed: _busy ? null : () => _confirmAndComplete(context),
            ),

          if (event.status == EventStatus.completed)
            Material(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: AppColors.border),
                borderRadius: AppRadius.lg,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.workspace_premium_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Text(
                          'Issue Certificates',
                          style: AppTextStyles.title,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '$attendedCount verified attendee(s) are eligible to receive completion certificates.',
                      style: AppTextStyles.bodySecondary,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppPrimaryButton(
                      label: 'Issue Digital Certificates',
                      icon: const Icon(Icons.card_membership_rounded, size: 18),
                      iconPosition: AppButtonIconPosition.left,
                      isLoading: _busy,
                      fullWidth: true,
                      onPressed: _busy ? null : _issueCertificates,
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Future<void> _confirmAndComplete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lg,
        ),
        title: const Text('Mark event as completed?'),
        content: const Text(
          'This locks the event attendance and enables certificate issuance for all verified attendees.',
          style: AppTextStyles.bodySecondary,
        ),
        actions: [
          AppSecondaryButton(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context, false),
          ),
          AppPrimaryButton(
            label: 'Confirm Completion',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    await ref
        .read(organizerRepositoryProvider)
        .markEventCompleted(widget.event.id);
    ref.invalidate(organizerEventsProvider);
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lg,
        ),
        title: const Text('Delete Event?'),
        content: Text(
          'Are you sure you want to delete "${widget.event.title}"? This action cannot be undone.',
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
    setState(() => _busy = true);
    final result = await ref
        .read(organizerRepositoryProvider)
        .deleteEvent(widget.event.id);
    if (!mounted) return;
    setState(() => _busy = false);
    result.when(
      ok: (_) {
        ref.invalidate(organizerEventsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event deleted successfully.'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop(); // Go back to events list
        }
      },
      err: (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(f.message),
          backgroundColor: AppColors.danger,
        ),
      ),
    );
  }

  Future<void> _issueCertificates() async {
    setState(() => _busy = true);
    final result = await ref
        .read(organizerRepositoryProvider)
        .issueCertificates(widget.event.id);
    if (!mounted) return;
    setState(() => _busy = false);
    result.when(
      ok: (count) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Issued $count certificate(s) successfully!'),
          backgroundColor: AppColors.success,
        ),
      ),
      err: (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(f.message),
          backgroundColor: AppColors.danger,
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

    switch (status) {
      case EventStatus.published:
        tone = AppBadgeTone.success;
        label = 'Published';
        break;
      case EventStatus.pendingApproval:
        tone = AppBadgeTone.warning;
        label = 'Pending approval';
        break;
      case EventStatus.rejected:
        tone = AppBadgeTone.danger;
        label = 'Rejected';
        break;
      case EventStatus.cancelled:
        tone = AppBadgeTone.danger;
        label = 'Cancelled';
        break;
      case EventStatus.completed:
        tone = AppBadgeTone.neutral;
        label = 'Completed';
        break;
      case EventStatus.draft:
        tone = AppBadgeTone.neutral;
        label = 'Draft';
        break;
    }

    return AppBadge(label: label, tone: tone);
  }
}
