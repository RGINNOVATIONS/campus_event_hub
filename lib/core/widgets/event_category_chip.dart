import 'package:campus_pulse/app/theme.dart';
import 'package:flutter/material.dart';

class EventCategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool compact;
  final Widget? icon;
  final VoidCallback? onTap;

  const EventCategoryChip({
    super.key,
    required this.label,
    this.selected = false,
    this.compact = false,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background = selected ? AppColors.textPrimary : AppColors.surface;
    final foreground =
        selected ? AppColors.textOnPrimary : AppColors.textSecondary;

    return Material(
      color: background,
      borderRadius: AppRadius.full,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.full,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AppSpacing.md : AppSpacing.lg,
            vertical: compact ? 7 : 10,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.full,
            border: Border.all(
              color: selected ? AppColors.textPrimary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                IconTheme.merge(
                  data:
                      IconThemeData(size: compact ? 14 : 16, color: foreground),
                  child: icon!,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label.copyWith(color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
