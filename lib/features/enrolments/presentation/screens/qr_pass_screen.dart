import 'package:campus_pulse/app/providers.dart';
import 'package:campus_pulse/app/theme.dart';
import 'package:campus_pulse/core/domain/enums.dart';
import 'package:campus_pulse/core/widgets/widgets.dart';
import 'package:campus_pulse/features/events/presentation/controllers/events_controllers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrPassScreen extends ConsumerWidget {
  final String eventId;
  const QrPassScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventByIdProvider(eventId));
    final enrolments = ref.watch(enrolmentsProvider).valueOrNull ?? {};
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final enrolment = enrolments[eventId];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Event Pass'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: eventAsync.when(
        loading: () => const LoadingState(message: 'Loading your pass...'),
        error: (e, _) => ErrorState(
          message: 'Could not load this pass.',
          onRetry: () => ref.invalidate(eventByIdProvider(eventId)),
        ),
        data: (event) {
          if (enrolment == null) {
            return const EmptyState(
              icon: Icon(Icons.confirmation_number_outlined),
              title: 'Not registered',
              description: 'You are not registered for this event.',
            );
          }

          final isAttended =
              enrolment.attendanceStatus == AttendanceStatus.attended;
          final dateFmt = DateFormat('EEEE, d MMMM yyyy');
          final timeFmt = DateFormat('h:mm a');

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Material(
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: AppColors.border),
                    borderRadius: AppRadius.lg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Ticket Header with Category & Status
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(AppRadius.large),
                          ),
                        ),
                        child: Row(
                          children: [
                            AppBadge(
                              label: event.categoryName,
                              tone: AppBadgeTone.primary,
                            ),
                            const Spacer(),
                            AppBadge(
                              label: isAttended ? 'Checked in' : 'Registered',
                              tone: isAttended
                                  ? AppBadgeTone.success
                                  : AppBadgeTone.warning,
                              icon: Icon(
                                isAttended
                                    ? Icons.check_circle
                                    : Icons.access_time_rounded,
                                size: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Event & Attendee info
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.lg,
                        ),
                        child: Column(
                          children: [
                            Text(
                              event.title,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.headline,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              event.clubName,
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // Attendee card pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: AppRadius.md,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.person_outline,
                                      size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    profile?.fullName ?? 'Student',
                                    style: AppTextStyles.label,
                                  ),
                                  if (profile?.collegeId != null &&
                                      profile!.collegeId.isNotEmpty) ...[
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      '• ${profile.collegeId}',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // QR Code Frame
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: AppRadius.lg,
                                border: Border.all(color: AppColors.border),
                                boxShadow: AppShadows.md,
                              ),
                              child: QrImageView(
                                data: enrolment.qrToken,
                                size: 190,
                                backgroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // Dashed Divider / Ticket separation
                            const Divider(height: 1, color: AppColors.border),
                            const SizedBox(height: AppSpacing.lg),

                            // Event Timing & Venue details
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.calendar_today_outlined,
                                    size: 14, color: AppColors.textMuted),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  dateFmt.format(event.startAt),
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  '· ${timeFmt.format(event.startAt)}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.location_on_outlined,
                                    size: 14, color: AppColors.textMuted),
                                const SizedBox(width: AppSpacing.xs),
                                Flexible(
                                  child: Text(
                                    event.venue,
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // Instructions hint
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: AppRadius.sm,
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      size: 16, color: AppColors.textMuted),
                                  SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      'Present this QR pass at the entrance desk for attendance verification.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

