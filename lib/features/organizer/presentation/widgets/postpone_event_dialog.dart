import 'package:campus_event_hub/app/providers.dart';
import 'package:campus_event_hub/app/theme.dart';
import 'package:campus_event_hub/core/widgets/widgets.dart';
import 'package:campus_event_hub/features/events/domain/event.dart';
import 'package:campus_event_hub/features/events/presentation/controllers/events_controllers.dart';
import 'package:campus_event_hub/features/organizer/presentation/screens/organizer_dashboard_screen.dart';
import 'package:campus_event_hub/features/organizer/presentation/screens/organizer_events_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class PostponeEventDialog extends ConsumerStatefulWidget {
  final EventModel event;

  const PostponeEventDialog({super.key, required this.event});

  static Future<bool?> show(BuildContext context, EventModel event) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PostponeEventDialog(event: event),
    );
  }

  @override
  ConsumerState<PostponeEventDialog> createState() =>
      _PostponeEventDialogState();
}

class _PostponeEventDialogState extends ConsumerState<PostponeEventDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _reasonController;

  late DateTime _newStart;
  late DateTime _newEnd;
  late DateTime _newDeadline;

  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController(
      text: widget.event.postponementReason ?? '',
    );
    // Default new dates to 7 days after current schedule
    final initialStart = widget.event.startAt.isAfter(DateTime.now())
        ? widget.event.startAt.add(const Duration(days: 7))
        : DateTime.now().add(const Duration(days: 7));
    final duration = widget.event.endAt.difference(widget.event.startAt);
    _newStart = initialStart;
    _newEnd = _newStart.add(duration.isNegative ? const Duration(hours: 3) : duration);
    _newDeadline = _newStart.subtract(const Duration(days: 1));
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    final dateError = EventDateValidator.validate(
      start: _newStart,
      end: _newEnd,
      registrationDeadline: _newDeadline,
      now: DateTime.now(),
    );
    if (dateError != null) {
      setState(() => _error = dateError);
      return;
    }

    setState(() => _busy = true);
    final repo = ref.read(organizerRepositoryProvider);
    final result = await repo.postponeEvent(
      eventId: widget.event.id,
      startAt: _newStart,
      endAt: _newEnd,
      registrationDeadline: _newDeadline,
      reason: _reasonController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _busy = false);

    result.when(
      ok: (_) {
        ref.invalidate(organizerEventsProvider);
        ref.invalidate(organizerDashboardProvider);
        ref.invalidate(eventByIdProvider(widget.event.id));
        ref.invalidate(upcomingEventsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event postponed successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      },
      err: (f) => setState(() => _error = f.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEE, d MMM yyyy · h:mm a');

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.update_rounded,
                        color: AppColors.warning,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Postpone Event',
                            style: AppTextStyles.headline,
                          ),
                          Text(
                            widget.event.title,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Warning Notice
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: AppRadius.md,
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.warning,
                        size: 18,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'This will change the scheduled date and time of the existing event. Existing registrations and digital passes will remain intact.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Current Schedule Box
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: AppRadius.md,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CURRENT SCHEDULE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Starts: ${dateFmt.format(widget.event.startAt)}',
                        style: AppTextStyles.caption,
                      ),
                      Text(
                        'Ends: ${dateFmt.format(widget.event.endAt)}',
                        style: AppTextStyles.caption,
                      ),
                      Text(
                        'Deadline: ${dateFmt.format(widget.event.registrationDeadline)}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // New Schedule Pickers
                _DialogDateField(
                  label: 'New Start Date & Time',
                  value: _newStart,
                  onPick: (d) => setState(() {
                    _newStart = d;
                    if (_newEnd.isBefore(_newStart)) {
                      _newEnd = _newStart.add(const Duration(hours: 3));
                    }
                    if (_newDeadline.isAfter(_newStart)) {
                      _newDeadline = _newStart.subtract(const Duration(days: 1));
                    }
                  }),
                ),
                const SizedBox(height: AppSpacing.md),
                _DialogDateField(
                  label: 'New End Date & Time',
                  value: _newEnd,
                  onPick: (d) => setState(() => _newEnd = d),
                ),
                const SizedBox(height: AppSpacing.md),
                _DialogDateField(
                  label: 'New Registration Deadline',
                  value: _newDeadline,
                  onPick: (d) => setState(() => _newDeadline = d),
                ),

                const SizedBox(height: AppSpacing.md),

                // Postponement Reason Field
                TextFormField(
                  controller: _reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Reason for Postponement',
                    hintText:
                        'e.g. Rescheduled due to faculty symposium or auditorium maintenance...',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please provide a reason for postponement';
                    }
                    if (v.trim().length < 5) {
                      return 'Reason should be at least 5 characters';
                    }
                    return null;
                  },
                ),

                // Error Display
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.dangerBg,
                      borderRadius: AppRadius.sm,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.danger,
                          size: 16,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.xl),

                // Dialog Buttons
                Row(
                  children: [
                    Expanded(
                      child: AppSecondaryButton(
                        label: 'Cancel',
                        onPressed: _busy ? null : () => Navigator.of(context).pop(false),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppPrimaryButton(
                        label: 'Confirm',
                        isLoading: _busy,
                        onPressed: _busy ? null : _submit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogDateField extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onPick;

  const _DialogDateField({
    required this.label,
    required this.value,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEE, d MMM yyyy · h:mm a');

    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date == null || !context.mounted) return;

        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(value),
        );
        if (time == null) return;

        onPick(
          DateTime(date.year, date.month, date.day, time.hour, time.minute),
        );
      },
      borderRadius: AppRadius.sm,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          dateFmt.format(value),
          style: AppTextStyles.body,
        ),
      ),
    );
  }
}
