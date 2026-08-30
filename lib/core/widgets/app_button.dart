import 'package:campus_event_hub/app/theme.dart';
import 'package:flutter/material.dart';

enum AppButtonIconPosition { left, right }

class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final bool fullWidth;
  final bool compact;
  final AppButtonIconPosition iconPosition;

  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.compact = false,
    this.iconPosition = AppButtonIconPosition.right,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: compact ? 40 : 48,
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.primaryLight,
          disabledForegroundColor: AppColors.textMuted,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AppSpacing.lg : AppSpacing.xl,
          ),
        ),
        child: _ButtonContent(
          label: label,
          icon: icon,
          isLoading: isLoading,
          iconPosition: iconPosition,
          loadingColor: AppColors.textOnPrimary,
        ),
      ),
    );
  }
}

class AppSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool fullWidth;
  final bool compact;
  final AppButtonIconPosition iconPosition;

  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.fullWidth = false,
    this.compact = false,
    this.iconPosition = AppButtonIconPosition.left,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: compact ? 40 : 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.textMuted,
          side: const BorderSide(color: AppColors.borderStrong),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AppSpacing.lg : AppSpacing.xl,
          ),
        ),
        child: _ButtonContent(
          label: label,
          icon: icon,
          iconPosition: iconPosition,
          loadingColor: AppColors.primary,
        ),
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  final String label;
  final Widget? icon;
  final bool isLoading;
  final AppButtonIconPosition iconPosition;
  final Color loadingColor;

  const _ButtonContent({
    required this.label,
    this.icon,
    this.isLoading = false,
    required this.iconPosition,
    required this.loadingColor,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox.square(
        dimension: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: loadingColor),
      );
    }

    final text = Text(
      label,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 13,
        height: 1.2,
        fontWeight: FontWeight.w600,
      ),
    );

    if (icon == null) return text;

    final children = iconPosition == AppButtonIconPosition.left
        ? [
            IconTheme.merge(data: const IconThemeData(size: 18), child: icon!),
            text
          ]
        : [
            text,
            IconTheme.merge(data: const IconThemeData(size: 18), child: icon!)
          ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        children.first,
        const SizedBox(width: AppSpacing.sm),
        children.last,
      ],
    );
  }
}
