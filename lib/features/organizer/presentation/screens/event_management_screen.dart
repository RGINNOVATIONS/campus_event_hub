import 'package:campus_event_hub/app/providers.dart';
import 'package:campus_event_hub/app/theme.dart';
import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/core/services/csv_export_service.dart';
import 'package:campus_event_hub/core/widgets/widgets.dart';
import 'package:campus_event_hub/features/attendance/presentation/screens/attendance_scan_screen.dart';
import 'package:campus_event_hub/features/events/domain/event.dart';
import 'package:campus_event_hub/features/events/presentation/controllers/events_controllers.dart';
import 'package:campus_event_hub/features/organizer/domain/organizer_repository.dart';
import 'package:campus_event_hub/features/organizer/presentation/screens/create_event_screen.dart';
import 'package:campus_event_hub/features/organizer/presentation/screens/organizer_dashboard_screen.dart';
import 'package:campus_event_hub/features/organizer/presentation/screens/organizer_events_screen.dart';
import 'package:campus_event_hub/features/organizer/presentation/widgets/postpone_event_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class EventManagementScreen extends ConsumerStatefulWidget {
  final EventModel event;
  final bool isReadOnly;
  const EventManagementScreen({
    super.key,
    required this.event,
    this.isReadOnly = false,
  });

  @override
  ConsumerState<EventManagementScreen> createState() =>
      _EventManagementScreenState();
}

class _EventManagementScreenState extends ConsumerState<EventManagementScreen> {
  late EventModel _currentEvent;
  List<RegistrationRow>? _registrations;
  String? _registrationsError;
  bool _busy = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
    _load();
  }

  Future<void> _load() async {
    setState(() => _registrationsError = null);
    final repo = ref.read(organizerRepositoryProvider);
    final result = await repo.registrationsFor(_currentEvent.id);
    if (mounted) {
      result.when(
        ok: (list) => setState(() {
          _registrations = list;
          _registrationsError = null;
        }),
        err: (f) => setState(() {
          _registrations = null;
          _registrationsError = f.message;
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = _currentEvent;
    final totalCount = _registrations?.length ?? 0;
    final attendedCount = _registrations
            ?.where((r) => r.attendanceStatus == AttendanceStatus.attended)
            .length ??
        0;
    final dateFmt = DateFormat('EEE, d MMM yyyy · h:mm a');

    final canPostpone = event.status == EventStatus.published ||
        event.status == EventStatus.postponed;
    final canScan = event.status == EventStatus.published ||
        event.status == EventStatus.postponed;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(event.title),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        actions: widget.isReadOnly
            ? [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Refresh',
                  onPressed: _refreshCurrentEvent,
                ),
              ]
            : const [OrganizerProfileButton()],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: () async => _refreshCurrentEvent(),
        child: ListView(
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
                    event.shortDescription,
                    style: AppTextStyles.bodySecondary,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Event Metadata Rows
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Schedule',
                    value:
                        '${dateFmt.format(event.startAt)} — ${DateFormat('h:mm a').format(event.endAt)}',
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'Venue',
                    value: event.venue,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _DetailRow(
                    icon: Icons.timer_outlined,
                    label: 'Deadline',
                    value: dateFmt.format(event.registrationDeadline),
                  ),

                  // Postponed Highlight Callout
                  if (event.status == EventStatus.postponed) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: AppRadius.sm,
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.update_rounded,
                                color: AppColors.warning,
                                size: 18,
                              ),
                              SizedBox(width: AppSpacing.xs),
                              Text(
                                'Event Rescheduled',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                          if (event.postponementReason != null &&
                              event.postponementReason!.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Reason: ${event.postponementReason}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // Rejection Box
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
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.lg),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: AppSpacing.md),

                  // Comprehensive Management Action Bar
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      if (!widget.isReadOnly) ...[
                        AppSecondaryButton(
                          label: 'Edit Event',
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          iconPosition: AppButtonIconPosition.left,
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    CreateEventScreen(existing: event),
                              ),
                            );
                            _refreshCurrentEvent();
                          },
                        ),
                        if (canPostpone)
                          AppSecondaryButton(
                            label: 'Postpone Event',
                            icon: const Icon(Icons.update_rounded,
                                size: 16, color: AppColors.warning),
                            iconPosition: AppButtonIconPosition.left,
                            onPressed: () async {
                              final postponed = await PostponeEventDialog.show(
                                  context, event);
                              if (postponed == true) {
                                _refreshCurrentEvent();
                              }
                            },
                          ),
                        if (canScan)
                          AppSecondaryButton(
                            label: 'Scan Attendance',
                            icon: const Icon(Icons.qr_code_scanner_rounded,
                                size: 16, color: AppColors.primary),
                            iconPosition: AppButtonIconPosition.left,
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    AttendanceScanScreen(initialEvent: event),
                              ),
                            ),
                          ),
                      ],
                      AppSecondaryButton(
                        label: _isExporting ? 'Exporting...' : 'Download CSV',
                        icon: _isExporting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            : const Icon(Icons.file_download_outlined,
                                size: 16, color: AppColors.primary),
                        iconPosition: AppButtonIconPosition.left,
                        onPressed: (_busy || _isExporting) ? null : _exportCsv,
                      ),
                      if (!widget.isReadOnly)
                        AppSecondaryButton(
                          label: 'Delete Event',
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 16, color: AppColors.danger),
                          iconPosition: AppButtonIconPosition.left,
                          onPressed:
                              _busy ? null : () => _confirmAndDelete(context),
                        ),
                    ],
                  ),
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
                      const Expanded(
                        child: Text(
                          'Registered Students',
                          style: AppTextStyles.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      AppBadge(
                        label: '$totalCount student(s)',
                        tone: AppBadgeTone.neutral,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      IconButton(
                        icon: _isExporting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            : const Icon(
                                Icons.file_download_outlined,
                                size: 20,
                                color: AppColors.primary,
                              ),
                        tooltip: 'Export student list (CSV)',
                        onPressed: (_busy || _isExporting) ? null : _exportCsv,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: AppSpacing.sm),
                  if (_registrationsError != null)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        children: [
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
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: AppColors.danger,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    _registrationsError!,
                                    style: const TextStyle(
                                      color: AppColors.danger,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppSecondaryButton(
                            label: 'Retry Loading',
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            iconPosition: AppButtonIconPosition.left,
                            onPressed: _load,
                          ),
                        ],
                      ),
                    )
                  else if (_registrations == null)
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
                        final displayName = r.studentName.trim().isNotEmpty
                            ? r.studentName.trim()
                            : (r.userId.length > 8
                                ? 'Student (${r.userId.substring(0, 8)})'
                                : 'Student');

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
                                      displayName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    () {
                                      final details = <String>[];
                                      if (r.studentId.isNotEmpty &&
                                          r.studentId != 'N/A') {
                                        details.add('ID: ${r.studentId}');
                                      }
                                      if (r.rollNo.isNotEmpty &&
                                          r.rollNo != 'N/A') {
                                        details.add('Roll: ${r.rollNo}');
                                      }
                                      if (r.branch.isNotEmpty &&
                                          r.branch != 'N/A') {
                                        details.add(r.branch);
                                      }
                                      final subtitle = details.isNotEmpty
                                          ? details.join(' · ')
                                          : (r.userId.length > 8
                                              ? 'ID: ${r.userId.substring(0, 8)}'
                                              : 'ID: ${r.userId}');
                                      return Text(
                                        subtitle,
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.textMuted,
                                        ),
                                      );
                                    }(),
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
          if (!widget.isReadOnly) ...[
            if (event.status == EventStatus.published ||
                event.status == EventStatus.postponed)
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
          ],

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    ),
  );
  }

  Future<void> _refreshCurrentEvent() async {
    final eventRes =
        await ref.read(eventRepositoryProvider).eventById(_currentEvent.id);
    if (mounted && eventRes.valueOrNull != null) {
      setState(() => _currentEvent = eventRes.valueOrNull!);
    }
    _load();
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
        .markEventCompleted(_currentEvent.id);
    ref.invalidate(organizerEventsProvider);
    ref.invalidate(organizerDashboardProvider);
    ref.invalidate(upcomingEventsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event marked as completed.'),
          backgroundColor: AppColors.success,
        ),
      );
      _refreshCurrentEvent();
      setState(() => _busy = false);
    }
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
          'Are you sure you want to delete "${_currentEvent.title}"? This action cannot be undone.',
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
        .deleteEvent(_currentEvent.id);
    if (!mounted) return;
    setState(() => _busy = false);
    result.when(
      ok: (_) {
        ref.invalidate(organizerEventsProvider);
        ref.invalidate(organizerDashboardProvider);
        ref.invalidate(upcomingEventsProvider);
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
        .issueCertificates(_currentEvent.id);
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

  Future<void> _exportCsv() async {
    setState(() => _isExporting = true);
    try {
      final repo = ref.read(organizerRepositoryProvider);
      final result = await repo.registrationsFor(_currentEvent.id);

      await result.when(
        ok: (regs) async {
          if (regs.isEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No registrations found to export.'),
                ),
              );
            }
            return;
          }

          final csv = CsvExportService.buildStudentListCsv(registrations: regs);
          final fileName = CsvExportService.sanitizeFileName(
            _currentEvent.title,
            DateTime.now(),
          );
          final downloadService = ref.read(downloadServiceProvider);
          final success = await downloadService.saveAndOpenCsv(
            csvContent: csv,
            fileName: fileName,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success
                      ? 'Exported $fileName successfully.'
                      : 'Saved $fileName.',
                ),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        err: (f) async {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Export failed: ${f.message}'),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '$label: ',
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
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
      case EventStatus.postponed:
        tone = AppBadgeTone.warning;
        label = 'Postponed';
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
