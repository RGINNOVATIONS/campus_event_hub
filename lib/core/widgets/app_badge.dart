import 'package:campus_event_hub/app/theme.dart';
import 'package:flutter/material.dart';

enum AppBadgeTone { neutral, primary, success, warning, danger }

class AppBadge extends StatelessWidget {
  final String label;
  final AppBadgeTone tone;
  final Widget? icon;

  const AppBadge({
    super.key,
    required this.label,
    this.tone = AppBadgeTone.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _BadgeColors.forTone(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: AppRadius.full,
        border:
            colors.border == null ? null : Border.all(color: colors.border!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            IconTheme.merge(
              data: IconThemeData(size: 13, color: colors.foreground),
              child: icon!,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: colors.foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeColors {
  final Color background;
  final Color foreground;
  final Color? border;

  const _BadgeColors(this.background, this.foreground, [this.border]);

  static _BadgeColors forTone(AppBadgeTone tone) {
    switch (tone) {
      case AppBadgeTone.primary:
        return const _BadgeColors(AppColors.primaryLight, AppColors.primary);
      case AppBadgeTone.success:
        return const _BadgeColors(AppColors.successBg, AppColors.success);
      case AppBadgeTone.warning:
        return const _BadgeColors(AppColors.warningBg, AppColors.warning);
      case AppBadgeTone.danger:
        return const _BadgeColors(AppColors.dangerBg, AppColors.danger);
      case AppBadgeTone.neutral:
        return const _BadgeColors(
          AppColors.background,
          AppColors.textSecondary,
          AppColors.border,
        );
    }
  }
}
