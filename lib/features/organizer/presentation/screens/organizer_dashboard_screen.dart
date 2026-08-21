import 'package:campus_pulse/app/providers.dart';
import 'package:campus_pulse/app/theme.dart';
import 'package:campus_pulse/core/widgets/widgets.dart';
import 'package:campus_pulse/features/organizer/domain/organizer_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final organizerDashboardProvider =
    FutureProvider.autoDispose<OrganizerDashboardCounts>((ref) async {
  final repo = ref.watch(organizerRepositoryProvider);
  final result = await repo.dashboardCounts();
  return result.when(ok: (v) => v, err: (f) => throw f);
});

class OrganizerDashboardScreen extends ConsumerWidget {
  final VoidCallback onCreateEvent;
  final VoidCallback onScanAttendance;
  final VoidCallback onMyEvents;
  const OrganizerDashboardScreen(
      {super.key,
      required this.onCreateEvent,
      required this.onScanAttendance,
      required this.onMyEvents});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countsAsync = ref.watch(organizerDashboardProvider);
    final profile = ref.watch(currentProfileProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Organizer Dashboard'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: countsAsync.when(
        loading: () =>
            const LoadingState(message: 'Loading dashboard statistics...'),
        error: (e, _) => ErrorState(
          message: 'Could not load dashboard.',
          onRetry: () => ref.invalidate(organizerDashboardProvider),
        ),
        data: (counts) {
          final isDesktop =
              MediaQuery.of(context).size.width >= AppBreakpoints.desktop;
          final isTablet =
              MediaQuery.of(context).size.width >= AppBreakpoints.tablet;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // Welcome Hero banner
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppRadius.lg,
                  boxShadow: AppShadows.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: AppRadius.sm,
                          ),
                          child: const Text(
                            'Organizer Portal',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.insights_rounded,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Welcome back, ${profile?.fullName ?? 'Organizer'}',
                      style: AppTextStyles.headline.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Track your event metrics, manage submissions, and verify student attendance.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Overview Section Header
              const SectionHeader(
                title: 'Event Overview',
                subtitle:
                    'Real-time performance across all your club activities',
              ),
              const SizedBox(height: AppSpacing.md),

              // Stats Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = isDesktop ? 3 : (isTablet ? 3 : 2);
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: isDesktop ? 2.2 : (isTablet ? 1.5 : 1.25),
                    children: [
                      AppStatCard(
                        title: 'Total Events',
                        value: '${counts.totalEvents}',
                        icon: const Icon(Icons.event_note_rounded),
                        filled: true,
                        onTap: onMyEvents,
                      ),
                      AppStatCard(
                        title: 'Pending Review',
                        value: '${counts.pendingApprovals}',
                        icon: const Icon(Icons.hourglass_top_rounded),
                        onTap: onMyEvents,
                      ),
                      AppStatCard(
                        title: 'Published',
                        value: '${counts.published}',
                        icon: const Icon(Icons.campaign_rounded),
                        onTap: onMyEvents,
                      ),
                      AppStatCard(
                        title: 'Completed',
                        value: '${counts.completed}',
                        icon: const Icon(Icons.task_alt_rounded),
                        onTap: onMyEvents,
                      ),
                      AppStatCard(
                        title: 'Registrations',
                        value: '${counts.totalRegistrations}',
                        icon: const Icon(Icons.people_alt_outlined),
                        onTap: onMyEvents,
                      ),
                      AppStatCard(
                        title: 'Attendees Checked In',
                        value: '${counts.totalAttendees}',
                        icon: const Icon(Icons.how_to_reg_rounded),
                        onTap: onScanAttendance,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: AppSpacing.xl),

              // Quick Actions
              const SectionHeader(
                title: 'Quick Operations',
                subtitle: 'Direct shortcuts for event publishing and check-in',
              ),
              const SizedBox(height: AppSpacing.md),

              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.add_circle_outline_rounded,
                      title: 'Create Event',
                      description: 'Draft & submit a new campus event',
                      buttonLabel: 'New Event',
                      isPrimary: true,
                      onTap: onCreateEvent,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.qr_code_scanner_rounded,
                      title: 'Scan QR Entry',
                      description: 'Verify attendee pass codes live',
                      buttonLabel: 'Open Scanner',
                      isPrimary: false,
                      onTap: onScanAttendance,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xxl),
            ],
          );
        },
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
            border: Border.all(
              color: isPrimary
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : AppColors.border,
            ),
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isPrimary
                      ? AppColors.primaryLight
                      : AppColors.surfaceElevated,
                  borderRadius: AppRadius.sm,
                ),
                child: Icon(
                  icon,
                  color: isPrimary ? AppColors.primary : AppColors.textPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: AppTextStyles.title,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                description,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.lg),
              isPrimary
                  ? AppPrimaryButton(
                      label: buttonLabel,
                      fullWidth: true,
                      onPressed: onTap,
                    )
                  : AppSecondaryButton(
                      label: buttonLabel,
                      fullWidth: true,
                      onPressed: onTap,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
