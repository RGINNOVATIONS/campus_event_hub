import 'package:campus_event_hub/app/theme.dart';
import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/core/widgets/app_badge.dart';
import 'package:campus_event_hub/core/widgets/event_poster_container.dart';
import 'package:campus_event_hub/features/events/domain/event.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final bool isFavourite;
  final bool showFavouriteButton;
  final VoidCallback onTap;
  final VoidCallback onToggleFavourite;

  const EventCard({
    super.key,
    required this.event,
    required this.isFavourite,
    this.showFavouriteButton = true,
    required this.onTap,
    required this.onToggleFavourite,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEE, d MMM');
    final timeFmt = DateFormat('h:mm a');
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.lg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lg,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.lg,
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  EventPosterContainer(
                    imageUrl: event.posterPath,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.large),
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.md,
                    top: AppSpacing.md,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppBadge(
                          label: event.categoryName,
                          tone: AppBadgeTone.primary,
                        ),
                        if (event.status == EventStatus.postponed) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const AppBadge(
                            label: 'Postponed',
                            tone: AppBadgeTone.warning,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (showFavouriteButton)
                    Positioned(
                      right: AppSpacing.sm,
                      top: AppSpacing.sm,
                      child: _FavouriteButton(
                        isFavourite: isFavourite,
                        onTap: onToggleFavourite,
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.title,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _MetaLine(
                      icon: Icons.calendar_today_outlined,
                      text:
                          '${dateFmt.format(event.startAt)} - ${timeFmt.format(event.startAt)}',
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _MetaLine(
                      icon: Icons.location_on_outlined,
                      text: event.venue,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.clubName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View Event',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            const Icon(
                              Icons.arrow_forward,
                              color: AppColors.primary,
                              size: 14,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _FavouriteButton extends StatelessWidget {
  final bool isFavourite;
  final VoidCallback onTap;

  const _FavouriteButton({required this.isFavourite, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface.withValues(alpha: 0.94),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Icon(
            isFavourite ? Icons.favorite : Icons.favorite_border,
            color: isFavourite ? AppColors.primary : AppColors.textSecondary,
            size: 20,
          ),
        ),
      ),
    );
  }
}
