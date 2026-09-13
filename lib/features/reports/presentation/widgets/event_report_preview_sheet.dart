import 'package:campus_event_hub/app/theme.dart';
import 'package:campus_event_hub/core/widgets/app_badge.dart';
import 'package:campus_event_hub/features/events/domain/event.dart';
import 'package:campus_event_hub/features/reports/domain/event_report_data.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventReportPreviewSheet extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEE, d MMM yyyy · h:mm a');

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
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
                              const Text(
                                'Event Report Preview',
                                style: AppTextStyles.title,
                              ),
                              Text(
                                report.title,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
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
                    // Stage Info Banner
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.5),
                        borderRadius: AppRadius.md,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Stage 1 Aggregation Complete — All Dean-mandated data points verified and ready for report export.',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
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
                        _buildDetailRow('Event ID', report.eventId),
                        _buildDetailRow('Title', report.title),
                        _buildDetailRow('Organizing Club', report.clubName),
                        _buildDetailRow('Category', report.categoryName),
                        _buildDetailRow('Venue', report.venue),
                        _buildDetailRow('Start Time', dateFmt.format(report.startAt)),
                        _buildDetailRow('End Time', dateFmt.format(report.endAt)),
                        if (report.fullDescription.isNotEmpty) ...[
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
                            report.fullDescription,
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
                            '${report.registrationsCount}',
                            Icons.how_to_reg_outlined,
                            AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _buildMetricBox(
                            'Attended',
                            '${report.attendanceCount}',
                            Icons.check_circle_outline,
                            AppColors.success,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _buildMetricBox(
                            'Attendance Rate',
                            '${report.attendancePercentage}%',
                            Icons.percent_rounded,
                            AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // 3. Demographic Breakdown (Attended Students)
                    _buildSectionHeader('3. Attendee Demographics'),
                    _buildBreakdownGroup('By Programme', report.programmeBreakdown),
                    const SizedBox(height: AppSpacing.sm),
                    _buildBreakdownGroup('By Branch', report.branchBreakdown),
                    const SizedBox(height: AppSpacing.sm),
                    _buildBreakdownGroup('By Academic Year', report.academicYearBreakdown),
                    const SizedBox(height: AppSpacing.lg),

                    // 4. Guest / Speaker Details
                    _buildSectionHeader('4. Guests & Speakers'),
                    if (report.guests.isEmpty)
                      _buildEmptyItem('No guests or speakers listed for this event.')
                    else
                      ...report.guests.map((g) => _buildGuestCard(g)),
                    const SizedBox(height: AppSpacing.lg),

                    // 5. Feedback & Reviews
                    _buildSectionHeader('5. Student Feedback & Ratings'),
                    _buildCard(
                      children: [
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      report.feedback.averageRating > 0
                                          ? report.feedback.averageRating.toStringAsFixed(1)
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
                                  '${report.feedback.reviewCount} review(s)',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            // Distribution bars
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [5, 4, 3, 2, 1].map((stars) {
                                final count =
                                    report.feedback.ratingDistribution[stars] ?? 0;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 1),
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
                                          widthFactor: report.feedback.reviewCount > 0
                                              ? (count / report.feedback.reviewCount)
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
                        if (report.feedback.reviews.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          const Divider(height: 1, color: AppColors.border),
                          const SizedBox(height: AppSpacing.sm),
                          const Text(
                            'Comments:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          ...report.feedback.reviews.map((r) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Container(
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceElevated,
                                    borderRadius: AppRadius.sm,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            r.studentName ?? 'Anonymous Student',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const Spacer(),
                                          ...List.generate(
                                            r.rating,
                                            (_) => const Icon(
                                              Icons.star_rounded,
                                              size: 14,
                                              color: Colors.amber,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (r.comment.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          r.comment,
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              )),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // 6. Organizer Details
                    _buildSectionHeader('6. Organizer Details'),
                    _buildCard(
                      children: [
                        _buildDetailRow('Contact Name', report.organizer.name),
                        _buildDetailRow('Club', report.organizer.clubName),
                        _buildDetailRow('Email', report.organizer.contactEmail),
                        if (report.organizer.contactPhone != null &&
                            report.organizer.contactPhone!.isNotEmpty)
                          _buildDetailRow('Phone', report.organizer.contactPhone!),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Timestamp
                    Center(
                      child: Text(
                        'Report data aggregated at ${DateFormat('y-MM-dd HH:mm:ss').format(report.generatedAt)}',
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
            width: 110,
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
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
