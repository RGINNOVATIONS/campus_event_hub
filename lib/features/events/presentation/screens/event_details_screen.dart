import 'package:campus_event_hub/app/providers.dart';
import 'package:campus_event_hub/app/theme.dart';
import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/core/widgets/app_badge.dart';
import 'package:campus_event_hub/core/widgets/app_button.dart';
import 'package:campus_event_hub/core/widgets/error_state.dart';
import 'package:campus_event_hub/core/widgets/event_poster_container.dart';
import 'package:campus_event_hub/core/widgets/loading_state.dart';
import 'package:campus_event_hub/core/widgets/section_header.dart';
import 'package:campus_event_hub/features/events/domain/event.dart';
import 'package:campus_event_hub/features/events/presentation/controllers/events_controllers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class EventDetailsScreen extends ConsumerWidget {
  final String eventId;

  const EventDetailsScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventByIdProvider(eventId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Add to calendar',
            onPressed: () async {
              final event = ref.read(eventByIdProvider(eventId)).valueOrNull;
              if (event == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('This event is not available.')),
                );
                return;
              }

              final result = await ref
                  .read(calendarServiceProvider)
                  .addEventToCalendar(event);
              if (context.mounted) {
                result.when(
                  ok: (_) => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Event added to your calendar.')),
                  ),
                  err: (failure) => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(failure.message)),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: eventAsync.when(
        loading: () => const LoadingState(message: 'Loading event details...'),
        error: (e, _) => ErrorState(
          title: 'Event unavailable',
          message: 'Could not load this event.',
          onRetry: () => ref.invalidate(eventByIdProvider(eventId)),
        ),
        data: (event) => _EventDetailsBody(event: event),
      ),
    );
  }
}

class _EventDetailsBody extends ConsumerWidget {
  final EventModel event;

  const _EventDetailsBody({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final isStudent = profile?.role == UserRole.student;

    final favourites = ref.watch(favouritesProvider).valueOrNull ?? {};
    final enrolments = ref.watch(enrolmentsProvider).valueOrNull ?? {};
    final isFavourite = favourites.contains(event.id);
    final isEnrolled = enrolments.containsKey(event.id);
    final buttonState = EnrolmentEligibility.buttonStateFor(
      event: event,
      isEnrolled: isEnrolled,
      now: DateTime.now(),
    );

    Future<void> enroll() async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
          title: const Text('Confirm Enrollment'),
          content: const Text(
            'Are you sure you want to enroll in this event?',
            style: AppTextStyles.bodySecondary,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Enroll'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      final error = await ref.read(enrolmentsProvider.notifier).enrol(event.id);
      if (context.mounted && error != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      } else if (context.mounted) {
        context.push('/student/my-events/${event.id}/qr');
      }
    }

    void viewQr() => context.push('/student/my-events/${event.id}/qr');
    void toggleFavourite() =>
        ref.read(favouritesProvider.notifier).toggle(event.id);

    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.only(bottom: isStudent ? 112 : AppSpacing.xl),
          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    EventPosterContainer(
                      imageUrl: event.posterPath,
                      fit: BoxFit.contain,
                      aspectRatio: MediaQuery.of(context).size.width >=
                              AppBreakpoints.tablet
                          ? 16 / 7
                          : 16 / 9,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide =
                            constraints.maxWidth >= AppBreakpoints.desktop;
                        final content = _EventContent(event: event);
                        final summary = _EventSummaryCard(event: event);

                        if (!wide) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              summary,
                              const SizedBox(height: AppSpacing.lg),
                              content,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 7, child: content),
                            const SizedBox(width: AppSpacing.xl),
                            Expanded(flex: 4, child: summary),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (isStudent)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomActionBar(
              state: buttonState,
              isFavourite: isFavourite,
              onEnroll: enroll,
              onViewQr: viewQr,
              onToggleFavourite: toggleFavourite,
            ),
          ),
      ],
    );
  }
}

class _EventContent extends StatelessWidget {
  final EventModel event;

  const _EventContent({required this.event});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'About this event'),
        const SizedBox(height: AppSpacing.sm),
        Text(event.fullDescription, style: AppTextStyles.bodySecondary),
        _Section(title: 'Eligibility', body: event.eligibility),
        _Section(title: 'Rules', body: event.rules),
        if (event.feeText != null && event.feeText!.trim().isNotEmpty)
          _Section(title: 'Fee', body: event.feeText!),
        _Section(
          title: 'Organizer contact',
          body: '${event.contactName}\n${event.contactEmail}'
              '${event.contactPhone != null ? '\n${event.contactPhone}' : ''}',
        ),
        if (event.status == EventStatus.rejected &&
            event.rejectionReason != null)
          _Section(title: 'Rejection reason', body: event.rejectionReason!),
      ],
    );
  }
}

class _EventSummaryCard extends StatelessWidget {
  final EventModel event;

  const _EventSummaryCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEEE, d MMMM yyyy');
    final timeFmt = DateFormat('h:mm a');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lg,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBadge(label: event.categoryName, tone: AppBadgeTone.primary),
          const SizedBox(height: AppSpacing.lg),
          Text(event.title, style: AppTextStyles.headline),
          const SizedBox(height: AppSpacing.md),
          Text(event.shortDescription, style: AppTextStyles.bodySecondary),
          const SizedBox(height: AppSpacing.xl),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Date',
            text: dateFmt.format(event.startAt),
          ),
          _InfoRow(
            icon: Icons.access_time,
            label: 'Time',
            text:
                '${timeFmt.format(event.startAt)} - ${timeFmt.format(event.endAt)}',
          ),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Venue',
            text: event.venue,
          ),
          InkWell(
            onTap: () => context.push('/student/clubs/${event.clubId}'),
            borderRadius: AppRadius.md,
            child: _InfoRow(
              icon: Icons.groups_outlined,
              label: 'Organizer',
              text: '${event.clubName}  >',
              linkStyle: true,
            ),
          ),
          _InfoRow(
            icon: Icons.timer_outlined,
            label: 'Registration Deadline',
            text: dateFmt.format(event.registrationDeadline),
          ),
        ],
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final EnrollButtonState state;
  final bool isFavourite;
  final VoidCallback onEnroll;
  final VoidCallback onViewQr;
  final VoidCallback onToggleFavourite;

  const _BottomActionBar({
    required this.state,
    required this.isFavourite,
    required this.onEnroll,
    required this.onViewQr,
    required this.onToggleFavourite,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: _EnrollButton(
                state: state,
                onEnroll: onEnroll,
                onViewQr: onViewQr,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: _FavouriteActionButton(
                isFavourite: isFavourite,
                onTap: onToggleFavourite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnrollButton extends StatelessWidget {
  final EnrollButtonState state;
  final VoidCallback onEnroll;
  final VoidCallback onViewQr;

  const _EnrollButton({
    required this.state,
    required this.onEnroll,
    required this.onViewQr,
  });

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case EnrollButtonState.enroll:
        return AppPrimaryButton(
          label: 'Enroll',
          onPressed: onEnroll,
          fullWidth: true,
          icon: const Icon(Icons.arrow_forward),
        );
      case EnrollButtonState.viewQr:
        return AppPrimaryButton(
          label: 'View QR',
          onPressed: onViewQr,
          fullWidth: true,
          icon: const Icon(Icons.qr_code_2),
        );
      case EnrollButtonState.registrationClosed:
        return const AppPrimaryButton(
          label: 'Registration Closed',
          onPressed: null,
          fullWidth: true,
        );
      case EnrollButtonState.eventCancelled:
        return const AppPrimaryButton(
          label: 'Event Cancelled',
          onPressed: null,
          fullWidth: true,
        );
      case EnrollButtonState.completed:
        return const AppPrimaryButton(
          label: 'Event Completed',
          onPressed: null,
          fullWidth: true,
        );
    }
  }
}

class _FavouriteActionButton extends StatelessWidget {
  final bool isFavourite;
  final VoidCallback onTap;

  const _FavouriteActionButton({
    required this.isFavourite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppSecondaryButton(
      label: isFavourite ? 'Favourited' : 'Favourite',
      onPressed: onTap,
      fullWidth: true,
      icon: Icon(isFavourite ? Icons.favorite : Icons.favorite_border),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String text;
  final bool linkStyle;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.text,
    this.linkStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 17, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  text,
                  style: AppTextStyles.label.copyWith(
                    color:
                        linkStyle ? AppColors.primary : AppColors.textPrimary,
                    decoration: linkStyle
                        ? TextDecoration.underline
                        : TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          Text(body, style: AppTextStyles.bodySecondary),
        ],
      ),
    );
  }
}
