import 'package:campus_pulse/app/theme.dart';
import 'package:campus_pulse/core/widgets/widgets.dart';
import 'package:campus_pulse/features/notifications/domain/notification_repository.dart';
import 'package:campus_pulse/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class NotificationCentreScreen extends ConsumerWidget {
  const NotificationCentreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
        actions: [
          state.whenOrNull(
                data: (items) => items.isNotEmpty
                    ? TextButton.icon(
                        onPressed: () => ref
                            .read(notificationsControllerProvider.notifier)
                            .markAllRead(),
                        icon: const Icon(Icons.done_all, size: 16),
                        label: const Text('Mark all read'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          textStyle: AppTextStyles.label,
                        ),
                      )
                    : null,
              ) ??
              const SizedBox.shrink(),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: state.when(
        loading: () => const LoadingState(message: 'Loading notifications...'),
        error: (e, _) => ErrorState(
          message: 'Could not load notifications.',
          onRetry: () =>
              ref.read(notificationsControllerProvider.notifier).refresh(),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icon(Icons.notifications_none_outlined),
              title: 'No notifications yet',
              description:
                  'You will be notified when events you follow are published or updated.',
            );
          }

          // Group into Today vs Earlier
          final today = DateTime.now();
          final todayItems =
              items.where((n) => _isToday(n.createdAt, today)).toList();
          final earlierItems =
              items.where((n) => !_isToday(n.createdAt, today)).toList();

          return RefreshIndicator(
            onRefresh: () async =>
                ref.read(notificationsControllerProvider.notifier).refresh(),
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.only(
                top: AppSpacing.lg,
                bottom: AppSpacing.xl,
              ),
              children: [
                if (todayItems.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: SectionHeader(
                      title: 'Today',
                      subtitle: '${todayItems.where((n) => !n.isRead).length}'
                          ' unread',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...todayItems.map(
                    (n) => _NotificationItem(
                      notification: n,
                      onTap: () => _handleTap(context, ref, n),
                    ),
                  ),
                ],
                if (earlierItems.isNotEmpty) ...[
                  if (todayItems.isNotEmpty)
                    const SizedBox(height: AppSpacing.lg),
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: SectionHeader(title: 'Earlier'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...earlierItems.map(
                    (n) => _NotificationItem(
                      notification: n,
                      onTap: () => _handleTap(context, ref, n),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  bool _isToday(DateTime dt, DateTime today) {
    return dt.year == today.year &&
        dt.month == today.month &&
        dt.day == today.day;
  }

  void _handleTap(
    BuildContext context,
    WidgetRef ref,
    NotificationModel n,
  ) {
    ref.read(notificationsControllerProvider.notifier).markRead(n.id);
    if (n.eventId != null) context.push('/event/${n.eventId}');
  }
}

// ── Notification item ─────────────────────────────────────────────────────────

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationItem({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final timestamp = DateFormat('d MMM, h:mm a').format(n.createdAt);
    final icon = _iconForType(n.type);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: AppNotificationCard(
        title: n.title,
        body: n.body,
        timestamp: timestamp,
        isRead: n.isRead,
        icon: Icon(icon),
        onTap: n.eventId != null ? onTap : null,
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'event_published':
        return Icons.event_available_outlined;
      case 'event_updated':
        return Icons.edit_calendar_outlined;
      case 'enrolment_confirmed':
        return Icons.check_circle_outline;
      case 'certificate_issued':
        return Icons.workspace_premium_outlined;
      case 'club_event':
        return Icons.groups_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }
}
