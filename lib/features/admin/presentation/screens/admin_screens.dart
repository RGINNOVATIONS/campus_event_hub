import 'package:campus_event_hub/app/providers.dart';
import 'package:campus_event_hub/app/theme.dart';
import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/core/widgets/widgets.dart';
import 'package:campus_event_hub/features/admin/domain/admin_repository.dart';
import 'package:campus_event_hub/features/events/presentation/controllers/events_controllers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final adminDashboardProvider =
    FutureProvider.autoDispose<AdminDashboardCounts>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final result = await repo.dashboardCounts();
  return result.when(ok: (v) => v, err: (f) => throw f);
});

final pendingEventsProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final result = await repo.pendingEvents();
  return result.when(ok: (v) => v, err: (f) => throw f);
});

final clubsProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final result = await repo.clubs();
  return result.when(ok: (v) => v, err: (f) => throw f);
});

final calendarEventsProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final result = await repo.allEventsForCalendar();
  return result.when(ok: (v) => v, err: (f) => throw f);
});

// ==========================================
// 1. ADMIN DASHBOARD SCREEN
// ==========================================
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countsAsync = ref.watch(adminDashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Administrator Dashboard'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: countsAsync.when(
        loading: () =>
            const LoadingState(message: 'Loading administrator metrics...'),
        error: (e, _) => ErrorState(
          message: 'Could not load dashboard.',
          onRetry: () => ref.invalidate(adminDashboardProvider),
        ),
        data: (counts) {
          final isDesktop =
              MediaQuery.of(context).size.width >= AppBreakpoints.desktop;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // Admin Hero Banner
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
                            'Administrative Governance',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Campus Event Oversight',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Review submissions, verify student organizations, and oversee calendar scheduling.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              const SectionHeader(
                title: 'Key Statistics',
                subtitle: 'Platform-wide event and organization metrics',
              ),
              const SizedBox(height: AppSpacing.md),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isDesktop ? 4 : 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: isDesktop ? 1.8 : 1.4,
                children: [
                  AppStatCard(
                    title: 'Pending Events',
                    value: '${counts.pendingEvents}',
                    icon: const Icon(Icons.pending_actions_rounded),
                    filled: counts.pendingEvents > 0,
                  ),
                  AppStatCard(
                    title: 'Published Events',
                    value: '${counts.publishedEvents}',
                    icon: const Icon(Icons.campaign_rounded),
                  ),
                  AppStatCard(
                    title: 'Verified Clubs',
                    value: '${counts.verifiedClubs}',
                    icon: const Icon(Icons.verified_outlined),
                  ),
                  AppStatCard(
                    title: 'Total Students',
                    value: '${counts.totalStudents}',
                    icon: const Icon(Icons.school_outlined),
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

// ==========================================
// 2. PENDING EVENTS SCREEN
// ==========================================
class PendingEventsScreen extends ConsumerWidget {
  const PendingEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(pendingEventsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pending Events'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: eventsAsync.when(
        loading: () =>
            const LoadingState(message: 'Loading pending submissions...'),
        error: (e, _) => ErrorState(
          message: 'Could not load pending events.',
          onRetry: () => ref.invalidate(pendingEventsProvider),
        ),
        data: (events) {
          if (events.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 48,
                      color: AppColors.success,
                    ),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      'Nothing pending review.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      'All submitted organizer events have been reviewed.',
                      style: AppTextStyles.bodySecondary,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, i) {
              final e = events[i];
              return Material(
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
                            label: e.clubName,
                            tone: AppBadgeTone.primary,
                          ),
                          const Spacer(),
                          const AppBadge(
                            label: 'Pending Approval',
                            tone: AppBadgeTone.warning,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        e.title,
                        style: AppTextStyles.title,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 14, color: AppColors.textMuted),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            DateFormat('d MMM, h:mm a').format(e.startAt),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          const Icon(Icons.location_on_outlined,
                              size: 14, color: AppColors.textMuted),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              e.venue,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        e.shortDescription,
                        style: AppTextStyles.bodySecondary,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _reject(context, ref, e.id),
                              child: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final res = await ref
                                    .read(adminRepositoryProvider)
                                    .approveEvent(e.id);
                                res.when(
                                  ok: (_) {
                                    ref.invalidate(pendingEventsProvider);
                                    ref.invalidate(adminDashboardProvider);
                                    ref.invalidate(upcomingEventsProvider);
                                    ref.invalidate(calendarEventsProvider);
                                  },
                                  err: (f) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(f.message)));
                                    }
                                  },
                                );
                              },
                              child: const Text('Approve'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _reject(
      BuildContext context, WidgetRef ref, String eventId) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
        title: const Text('Rejection reason'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
              hintText: 'Explain what needs to change...'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;
    final res =
        await ref.read(adminRepositoryProvider).rejectEvent(eventId, reason);
    res.when(
      ok: (_) {
        ref.invalidate(pendingEventsProvider);
        ref.invalidate(adminDashboardProvider);
      },
      err: (f) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(f.message)));
        }
      },
    );
  }
}

// ==========================================
// 3. CLUBS SCREEN
// ==========================================
class ClubsScreen extends ConsumerWidget {
  const ClubsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubsAsync = ref.watch(clubsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Clubs'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: clubsAsync.when(
        loading: () => const LoadingState(message: 'Loading campus clubs...'),
        error: (e, _) => ErrorState(
          message: 'Could not load clubs.',
          onRetry: () => ref.invalidate(clubsProvider),
        ),
        data: (clubs) {
          if (clubs.isEmpty) {
            return const EmptyState(
              icon: Icon(Icons.groups_outlined),
              title: 'No Clubs Registered',
              description: 'No student clubs have registered yet.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: clubs.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, i) {
              final c = clubs[i];
              final isPending = c.status == ClubStatus.pending;
              final isVerified = c.status == ClubStatus.verified;

              return Material(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: AppColors.border),
                  borderRadius: AppRadius.lg,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isVerified
                              ? AppColors.primaryLight
                              : AppColors.surfaceElevated,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          c.name.isNotEmpty ? c.name[0].toUpperCase() : 'C',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isVerified
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    c.name,
                                    style: AppTextStyles.title,
                                  ),
                                ),
                                AppBadge(
                                  label: c.status.name,
                                  tone: isVerified
                                      ? AppBadgeTone.success
                                      : (isPending
                                          ? AppBadgeTone.warning
                                          : AppBadgeTone.danger),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              c.description,
                              style: AppTextStyles.bodySecondary,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (isPending) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.close,
                                  color: AppColors.danger),
                              tooltip: 'Reject Club',
                              onPressed: () async {
                                final res = await ref
                                    .read(adminRepositoryProvider)
                                    .rejectClub(c.id);
                                res.when(
                                  ok: (_) => ref.invalidate(clubsProvider),
                                  err: (f) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(f.message)));
                                    }
                                  },
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.check,
                                  color: AppColors.success),
                              tooltip: 'Verify Club',
                              onPressed: () async {
                                final res = await ref
                                    .read(adminRepositoryProvider)
                                    .verifyClub(c.id);
                                res.when(
                                  ok: (_) {
                                    ref.invalidate(clubsProvider);
                                    ref.invalidate(adminDashboardProvider);
                                  },
                                  err: (f) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(f.message)));
                                    }
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ==========================================
// 4. ADMIN CALENDAR SCREEN
// ==========================================
class AdminCalendarScreen extends ConsumerWidget {
  const AdminCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(calendarEventsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Official Event Calendar'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: eventsAsync.when(
        loading: () =>
            const LoadingState(message: 'Loading calendar schedule...'),
        error: (e, _) => ErrorState(
          message: 'Could not load the calendar.',
          onRetry: () => ref.invalidate(calendarEventsProvider),
        ),
        data: (events) {
          if (events.isEmpty) {
            return const EmptyState(
              icon: Icon(Icons.calendar_month_outlined),
              title: 'No Scheduled Events',
              description: 'There are no events on the campus calendar yet.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, i) {
              final e = events[i];
              return Material(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: AppColors.border),
                  borderRadius: AppRadius.lg,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      // Date Block
                      Container(
                        width: 52,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: AppRadius.md,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat('d').format(e.startAt),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              DateFormat('MMM').format(e.startAt).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),

                      // Event details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${e.clubName} · ${e.venue}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Cancel action
                      IconButton(
                        icon: const Icon(Icons.block, color: AppColors.danger),
                        tooltip: 'Cancel / Unpublish',
                        onPressed: () => _confirmCancel(context, ref, e.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmCancel(
      BuildContext context, WidgetRef ref, String eventId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
        title: const Text('Cancel this event?'),
        content: const Text(
          'Enrolled students will be notified that the event was cancelled.',
          style: AppTextStyles.bodySecondary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Back'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Event'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final res = await ref.read(adminRepositoryProvider).cancelEvent(eventId);
    res.when(
      ok: (_) {
        ref.invalidate(calendarEventsProvider);
        ref.invalidate(adminDashboardProvider);
        ref.invalidate(upcomingEventsProvider);
      },
      err: (f) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(f.message)));
        }
      },
    );
  }
}
