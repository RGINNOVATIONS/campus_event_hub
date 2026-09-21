import 'package:campus_event_hub/app/providers.dart';
import 'package:campus_event_hub/app/theme.dart';
import 'package:campus_event_hub/core/widgets/app_badge.dart';
import 'package:campus_event_hub/core/widgets/app_button.dart';
import 'package:campus_event_hub/features/events/domain/event.dart';
import 'package:campus_event_hub/features/reports/domain/event_report_ai_content.dart';
import 'package:campus_event_hub/features/reports/domain/event_report_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class EventReportPreviewSheet extends ConsumerStatefulWidget {
  final EventReportData report;

  const EventReportPreviewSheet({
    super.key,
    required this.report,
  });

  static Future<void> show(BuildContext context, EventReportData report) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EventReportPreviewSheet(report: report),
    );
  }

  @override
  ConsumerState<EventReportPreviewSheet> createState() =>
      _EventReportPreviewSheetState();
}

class _EventReportPreviewSheetState
    extends ConsumerState<EventReportPreviewSheet> {
  late final TextEditingController _notesController;
  late final TextEditingController _objectivesController;
  late final TextEditingController _outcomesController;
  late final TextEditingController _narrativeController;

  bool _isDraftingObjectives = false;
  bool _isDraftingNarrative = false;
  bool _isPolishingNotes = false;
  bool _isSaving = false;
  bool _isDownloadingDocx = false;

  late String _status;
  DateTime? _confirmedAt;

  String? _objectivesAiError;
  String? _narrativeAiError;
  String? _notesAiError;
  bool _hasUnsavedEdits = false;

  @override
  void initState() {
    super.initState();
    final content = widget.report.content;
    _notesController =
        TextEditingController(text: content?.organizerNotes ?? '');
    _objectivesController =
        TextEditingController(text: content?.objectives ?? '');
    _outcomesController = TextEditingController(text: content?.outcomes ?? '');
    _narrativeController =
        TextEditingController(text: content?.feedbackNarrative ?? '');

    _status = content?.status ?? 'draft';
    _confirmedAt = content?.confirmedAt;

    _notesController.addListener(_onFieldEdited);
    _objectivesController.addListener(_onFieldEdited);
    _outcomesController.addListener(_onFieldEdited);
    _narrativeController.addListener(_onFieldEdited);
  }

  void _onFieldEdited() {
    if (_status == 'confirmed') {
      setState(() {
        _status = 'draft';
        _hasUnsavedEdits = true;
      });
    } else if (!_hasUnsavedEdits) {
      setState(() => _hasUnsavedEdits = true);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _objectivesController.dispose();
    _outcomesController.dispose();
    _narrativeController.dispose();
    super.dispose();
  }

  Future<void> _polishOrganizerNotes() async {
    final notes = _notesController.text.trim();
    if (notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please enter your organizer notes/account before polishing.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isPolishingNotes = true;
      _notesAiError = null;
    });

    final service = ref.read(reportAiServiceProvider);
    final res = await service.polishOrganizerNotes(
      eventId: widget.report.eventId,
      organizerNotes: notes,
    );

    if (!mounted) return;

    setState(() => _isPolishingNotes = false);

    res.when(
      ok: (polished) {
        setState(() {
          _notesController.text = polished;
          _status = 'draft';
          _hasUnsavedEdits = true;
          _notesAiError = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Organizer notes polished! You can review, edit, or draft from them.'),
            backgroundColor: AppColors.success,
          ),
        );
      },
      err: (f) {
        setState(() => _notesAiError = f.message);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'AI polishing failed: ${f.message}. You can edit them manually.'),
            backgroundColor: AppColors.danger,
          ),
        );
      },
    );
  }

  Future<void> _draftObjectivesAndOutcomes() async {
    final notes = _notesController.text.trim();
    if (notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please enter your organizer notes/account before drafting.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isDraftingObjectives = true;
      _objectivesAiError = null;
    });

    final service = ref.read(reportAiServiceProvider);
    final res = await service.draftObjectivesAndOutcomes(
      eventId: widget.report.eventId,
      organizerNotes: notes,
      category: widget.report.categoryName,
      registrationsCount: widget.report.registrationsCount,
      attendanceCount: widget.report.attendanceCount,
      attendancePercentage: widget.report.attendancePercentage,
      guests: widget.report.guests,
    );

    if (!mounted) return;

    setState(() => _isDraftingObjectives = false);

    res.when(
      ok: (draft) {
        setState(() {
          _objectivesController.text = draft.objectives;
          _outcomesController.text = draft.outcomes;
          _status = 'draft';
          _hasUnsavedEdits = true;
          _objectivesAiError = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Objectives & Outcomes drafted! Please review, edit, and confirm.'),
            backgroundColor: AppColors.success,
          ),
        );
      },
      err: (f) {
        setState(() => _objectivesAiError = f.message);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'AI drafting failed: ${f.message}. You can enter them manually.'),
            backgroundColor: AppColors.danger,
          ),
        );
      },
    );
  }

  Future<void> _draftFeedbackNarrative() async {
    setState(() {
      _isDraftingNarrative = true;
      _narrativeAiError = null;
    });

    final service = ref.read(reportAiServiceProvider);
    final res =
        await service.draftFeedbackNarrative(widget.report.eventId);

    if (!mounted) return;

    setState(() => _isDraftingNarrative = false);

    res.when(
      ok: (narrative) {
        setState(() {
          _narrativeController.text = narrative;
          _status = 'draft';
          _hasUnsavedEdits = true;
          _narrativeAiError = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Feedback Narrative drafted! Please review and refine.'),
            backgroundColor: AppColors.success,
          ),
        );
      },
      err: (f) {
        setState(() => _narrativeAiError = f.message);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'AI drafting failed: ${f.message}. You can enter it manually.'),
            backgroundColor: AppColors.danger,
          ),
        );
      },
    );
  }

  Future<void> _saveContent({required bool confirmFinal}) async {
    if (confirmFinal) {
      if (_objectivesController.text.trim().isEmpty ||
          _outcomesController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Please provide both Objectives and Outcomes before confirming.'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    final content = EventReportContent(
      eventId: widget.report.eventId,
      organizerNotes: _notesController.text.trim(),
      objectives: _objectivesController.text.trim(),
      outcomes: _outcomesController.text.trim(),
      feedbackNarrative: _narrativeController.text.trim(),
      status: confirmFinal ? 'confirmed' : 'draft',
    );

    final service = ref.read(reportAiServiceProvider);
    final res =
        await service.saveReportContent(widget.report.eventId, content);

    if (!mounted) return;

    setState(() => _isSaving = false);

    res.when(
      ok: (saved) {
        setState(() {
          _status = saved.status;
          _confirmedAt = saved.confirmedAt;
          _hasUnsavedEdits = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              confirmFinal
                  ? 'Report confirmed as final! Approved for institutional submission.'
                  : 'Report draft saved successfully.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      },
      err: (f) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save report: ${f.message}'),
            backgroundColor: AppColors.danger,
          ),
        );
      },
    );
  }

  Future<void> _downloadReportDocx() async {
    if (_status != 'confirmed') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Report must be confirmed as final before downloading.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isDownloadingDocx = true);

    final service = ref.read(reportAiServiceProvider);
    final res = await service.generateReportDocx(widget.report.eventId);

    if (!mounted) return;

    setState(() => _isDownloadingDocx = false);

    await res.when(
      ok: (signedUrl) async {
        final downloadService = ref.read(downloadServiceProvider);
        final safeTitle = widget.report.title
            .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
            .trim();
        final fileName =
            'Event_Report_${safeTitle.isNotEmpty ? safeTitle : widget.report.eventId}.docx';

        final opened = await downloadService.downloadAndOpen(
          url: signedUrl,
          suggestedFileName: fileName,
        );

        if (!mounted) return;

        if (opened) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Downloading and opening official report document...'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open downloaded report document.'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
      err: (f) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(f.message),
            backgroundColor: AppColors.danger,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEE, d MMM yyyy · h:mm a');
    final isConfirmed = _status == 'confirmed';

    return DraggableScrollableSheet(
      initialChildSize: 0.90,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag Handle & Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: AppRadius.full,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: AppRadius.md,
                          ),
                          child: const Icon(
                            Icons.assessment_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Event Report',
                                    style: AppTextStyles.title,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  AppBadge(
                                    label: isConfirmed
                                        ? 'Confirmed Final'
                                        : 'Draft (In Review)',
                                    tone: isConfirmed
                                        ? AppBadgeTone.success
                                        : AppBadgeTone.neutral,
                                  ),
                                ],
                              ),
                              Text(
                                widget.report.title,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (isConfirmed)
                          IconButton(
                            icon: _isDownloadingDocx
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : const Icon(
                                    Icons.download_for_offline_outlined,
                                    color: AppColors.primary,
                                  ),
                            tooltip: 'Download Word Report (.docx)',
                            onPressed: _isDownloadingDocx
                                ? null
                                : _downloadReportDocx,
                          ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),

              // Scrollable Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    // Stage 2 Info / Status Banner
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isConfirmed
                            ? AppColors.successBg
                            : AppColors.primaryLight.withValues(alpha: 0.4),
                        borderRadius: AppRadius.md,
                        border: Border.all(
                          color: isConfirmed
                              ? AppColors.success.withValues(alpha: 0.3)
                              : AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isConfirmed
                                ? Icons.verified_rounded
                                : Icons.auto_awesome,
                            color: isConfirmed
                                ? AppColors.success
                                : AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              isConfirmed
                                  ? 'Report Content Confirmed as Final — Attributed & approved for institutional leadership${_confirmedAt != null ? ' (${DateFormat('d MMM yyyy, h:mm a').format(_confirmedAt!)})' : ''}.'
                                  : 'Stage 2 Active — Use AI drafting to compose Objectives, Outcomes, and Feedback Narrative. Review, edit, and confirm before final submission.',
                              style: AppTextStyles.caption.copyWith(
                                color: isConfirmed
                                    ? AppColors.success
                                    : AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // 1. Event Overview & Schedule
                    _buildSectionHeader('1. Event Overview & Schedule'),
                    _buildCard(
                      children: [
                        _buildDetailRow('Event ID', widget.report.eventId),
                        _buildDetailRow('Title', widget.report.title),
                        _buildDetailRow(
                            'Organizing Club', widget.report.clubName),
                        _buildDetailRow('Category', widget.report.categoryName),
                        _buildDetailRow('Venue', widget.report.venue),
                        _buildDetailRow(
                            'Start Time', dateFmt.format(widget.report.startAt)),
                        _buildDetailRow(
                            'End Time', dateFmt.format(widget.report.endAt)),
                        if (widget.report.fullDescription.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          const Text(
                            'Description:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.report.fullDescription,
                            style: AppTextStyles.bodySecondary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // 2. Participation Summary
                    _buildSectionHeader('2. Participation Summary'),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricBox(
                            'Registered',
                            '${widget.report.registrationsCount}',
                            Icons.how_to_reg_outlined,
                            AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _buildMetricBox(
                            'Attended',
                            '${widget.report.attendanceCount}',
                            Icons.check_circle_outline,
                            AppColors.success,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _buildMetricBox(
                            'Attendance Rate',
                            '${widget.report.attendancePercentage}%',
                            Icons.percent_rounded,
                            AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // 3. Demographic Breakdown (Attended Students)
                    _buildSectionHeader('3. Attendee Demographics'),
                    _buildBreakdownGroup(
                        'By Programme', widget.report.programmeBreakdown),
                    const SizedBox(height: AppSpacing.sm),
                    _buildBreakdownGroup(
                        'By Branch', widget.report.branchBreakdown),
                    const SizedBox(height: AppSpacing.sm),
                    _buildBreakdownGroup('By Academic Year',
                        widget.report.academicYearBreakdown),
                    const SizedBox(height: AppSpacing.lg),

                    // 4. Guest / Speaker Details
                    _buildSectionHeader('4. Guests & Speakers'),
                    if (widget.report.guests.isEmpty)
                      _buildEmptyItem(
                          'No guests or speakers listed for this event.')
                    else
                      ...widget.report.guests.map((g) => _buildGuestCard(g)),
                    const SizedBox(height: AppSpacing.lg),

                    // 5. Organizer Notes & Context
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionHeader('5. Organizer Account & Notes'),
                        TextButton.icon(
                          onPressed: _isPolishingNotes
                              ? null
                              : _polishOrganizerNotes,
                          icon: _isPolishingNotes
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome, size: 16),
                          label: Text(
                            _isPolishingNotes
                                ? 'Polishing...'
                                : 'Polish with AI',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    if (_notesAiError != null) ...[
                      _buildInlineErrorBanner(
                        'AI polishing unavailable: $_notesAiError. You may write or edit the notes manually below.',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    _buildCard(
                      children: [
                        Text(
                          'Provide key highlights, session flow, topics covered, and observations. AI drafting grounds its content strictly in these notes without hallucinating facts.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 4,
                          minLines: 2,
                          decoration: InputDecoration(
                            hintText:
                                'e.g. Conducted a 36-hour hackathon with 4 rounds of mentoring. Top themes included AI for campus logistics. Students built 8 working MVPs...',
                            hintStyle: AppTextStyles.caption.copyWith(
                              color: AppColors.textMuted,
                            ),
                            filled: true,
                            fillColor: AppColors.surfaceElevated,
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.sm,
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: AppRadius.sm,
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                          ),
                          style: AppTextStyles.body,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // 6. Objectives & Key Outcomes (AI Draftable + Editable)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionHeader('6. Objectives & Key Outcomes'),
                        TextButton.icon(
                          onPressed: _isDraftingObjectives
                              ? null
                              : _draftObjectivesAndOutcomes,
                          icon: _isDraftingObjectives
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome, size: 16),
                          label: Text(
                            _isDraftingObjectives
                                ? 'Drafting...'
                                : 'Draft with AI',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    if (_objectivesAiError != null) ...[
                      _buildInlineErrorBanner(
                        'AI drafting unavailable: $_objectivesAiError. You may write or edit the sections manually below.',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    _buildCard(
                      children: [
                        const Text(
                          'Event Objectives (Intended Goals)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _objectivesController,
                          maxLines: 5,
                          minLines: 3,
                          decoration: InputDecoration(
                            hintText:
                                '• State primary technical/academic objectives...\n• State participant skills targeted...',
                            hintStyle: AppTextStyles.caption.copyWith(
                              color: AppColors.textMuted,
                            ),
                            filled: true,
                            fillColor: AppColors.surfaceElevated,
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.sm,
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: AppRadius.sm,
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                          ),
                          style: AppTextStyles.body,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Text(
                          'Key Outcomes & Practical Impact',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _outcomesController,
                          maxLines: 5,
                          minLines: 3,
                          decoration: InputDecoration(
                            hintText:
                                '• State measurable deliverables achieved...\n• State participant engagement impact...',
                            hintStyle: AppTextStyles.caption.copyWith(
                              color: AppColors.textMuted,
                            ),
                            filled: true,
                            fillColor: AppColors.surfaceElevated,
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.sm,
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: AppRadius.sm,
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                          ),
                          style: AppTextStyles.body,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // 7. Student Feedback & Narrative
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionHeader('7. Student Feedback & Narrative'),
                        TextButton.icon(
                          onPressed: _isDraftingNarrative
                              ? null
                              : _draftFeedbackNarrative,
                          icon: _isDraftingNarrative
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome, size: 16),
                          label: Text(
                            _isDraftingNarrative
                                ? 'Drafting...'
                                : 'Draft Narrative',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    if (_narrativeAiError != null) ...[
                      _buildInlineErrorBanner(
                        'AI drafting unavailable: $_narrativeAiError. You may write or edit the narrative manually below.',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    _buildCard(
                      children: [
                        // Rating row & distribution
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      widget.report.feedback.averageRating > 0
                                          ? widget.report.feedback.averageRating
                                              .toStringAsFixed(1)
                                          : 'N/A',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Colors.amber,
                                      size: 26,
                                    ),
                                  ],
                                ),
                                Text(
                                  '${widget.report.feedback.reviewCount} review(s)',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [5, 4, 3, 2, 1].map((stars) {
                                final count = widget.report.feedback
                                        .ratingDistribution[stars] ??
                                    0;
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 1),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$stars ★',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 80,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceElevated,
                                          borderRadius: AppRadius.full,
                                        ),
                                        alignment: Alignment.centerLeft,
                                        child: FractionallySizedBox(
                                          widthFactor: widget.report.feedback
                                                      .reviewCount >
                                                  0
                                              ? (count /
                                                  widget.report.feedback
                                                      .reviewCount)
                                              : 0.0,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.amber,
                                              borderRadius: AppRadius.full,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      SizedBox(
                                        width: 16,
                                        child: Text(
                                          '$count',
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.textSecondary,
                                            fontSize: 11,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: AppSpacing.md),

                        const Text(
                          'Feedback Narrative (Executive Summary)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Anonymously synthesized sentiment across student reviews. Zero student PII is exposed.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: _narrativeController,
                          maxLines: 4,
                          minLines: 2,
                          decoration: InputDecoration(
                            hintText:
                                'Overall student sentiment, recurring praises, and constructive recommendations...',
                            hintStyle: AppTextStyles.caption.copyWith(
                              color: AppColors.textMuted,
                            ),
                            filled: true,
                            fillColor: AppColors.surfaceElevated,
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.sm,
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: AppRadius.sm,
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                          ),
                          style: AppTextStyles.body,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // 8. Organizer Details
                    _buildSectionHeader('8. Organizer Details'),
                    _buildCard(
                      children: [
                        _buildDetailRow(
                            'Contact Name', widget.report.organizer.name),
                        _buildDetailRow(
                            'Club', widget.report.organizer.clubName),
                        _buildDetailRow(
                            'Email', widget.report.organizer.contactEmail),
                        if (widget.report.organizer.contactPhone != null &&
                            widget.report.organizer.contactPhone!.isNotEmpty)
                          _buildDetailRow(
                              'Phone', widget.report.organizer.contactPhone!),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Review & Confirmation Actions
                    _buildConfirmationCard(isConfirmed),
                    const SizedBox(height: AppSpacing.lg),

                    // Timestamp
                    Center(
                      child: Text(
                        'Report aggregated at ${DateFormat('y-MM-dd HH:mm:ss').format(widget.report.generatedAt)}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConfirmationCard(bool isConfirmed) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lg,
        border: Border.all(
          color: isConfirmed
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isConfirmed ? Icons.check_circle_rounded : Icons.edit_document,
                color: isConfirmed ? AppColors.success : AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                isConfirmed ? 'Report Finalized' : 'Review & Confirm',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isConfirmed
                ? 'This report has been reviewed and confirmed. Any subsequent edits will revert its status to draft.'
                : 'Confirming marks the Objectives, Outcomes, and Feedback Narrative as officially verified by the organizer for institutional archiving.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppSecondaryButton(
                  label: _hasUnsavedEdits ? 'Save Draft' : 'Draft Saved',
                  onPressed: (_isSaving || !_hasUnsavedEdits)
                      ? null
                      : () => _saveContent(confirmFinal: false),
                  icon: const Icon(Icons.save_outlined, size: 18),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppPrimaryButton(
                  label: isConfirmed ? 'Re-confirm Final' : 'Confirm as Final',
                  isLoading: _isSaving,
                  onPressed: _isSaving
                      ? null
                      : () => _saveContent(confirmFinal: true),
                  icon: const Icon(Icons.verified_rounded, size: 18),
                ),
              ),
            ],
          ),
          if (isConfirmed) ...[
            const SizedBox(height: AppSpacing.md),
            AppPrimaryButton(
              label: _isDownloadingDocx
                  ? 'Generating Document...'
                  : 'Download Word Report (.docx)',
              isLoading: _isDownloadingDocx,
              onPressed: (_isSaving || _isDownloadingDocx)
                  ? null
                  : _downloadReportDocx,
              icon: const Icon(Icons.description_outlined, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInlineErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: AppRadius.sm,
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownGroup(String title, List<DemographicItem> items) {
    return _buildCard(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (items.isEmpty)
          Text(
            'No attendee data recorded.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: items.map((item) {
              return AppBadge(
                label: '${item.label}: ${item.count} (${item.percentage}%)',
                tone: AppBadgeTone.primary,
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildGuestCard(EventGuest guest) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_pin_rounded,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guest.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${guest.designation} · ${guest.organization}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyItem(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
