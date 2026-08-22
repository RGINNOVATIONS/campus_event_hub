import 'package:campus_event_hub/app/theme.dart';
import 'package:flutter/material.dart';

class AppStatCard extends StatelessWidget {
  final String title;
  final String value;
  final Widget? icon;
  final String? subtitle;
  final bool filled;
  final VoidCallback? onTap;

  const AppStatCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.subtitle,
    this.filled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background = filled ? AppColors.primary : AppColors.surface;
    final foreground = filled ? AppColors.textOnPrimary : AppColors.textPrimary;
    final secondary = filled
        ? AppColors.textOnPrimary.withValues(alpha: 0.78)
        : AppColors.textSecondary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 180;
        return Material(
          color: background,
          borderRadius: AppRadius.lg,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.lg,
            child: Container(
              padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: AppRadius.lg,
                border: Border.all(
                  color: filled ? AppColors.primary : AppColors.border,
                ),
                boxShadow: AppShadows.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null)
                    IconTheme.merge(
                      data: IconThemeData(
                        size: compact ? 18 : 22,
                        color: filled
                            ? AppColors.textOnPrimary
                            : AppColors.primary,
                      ),
                      child: icon!,
                    ),
                  if (icon != null) const SizedBox(height: AppSpacing.md),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headline.copyWith(color: foreground),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(color: secondary),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(color: secondary),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
