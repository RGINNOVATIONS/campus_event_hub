import 'package:campus_event_hub/app/theme.dart';
import 'package:flutter/material.dart';

class ErrorState extends StatelessWidget {
  final String? title;
  final String message;
  final VoidCallback onRetry;
  final String retryLabel;
  final IconData icon;

  const ErrorState({
    super.key,
    this.title,
    required this.message,
    required this.onRetry,
    this.retryLabel = 'Retry',
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.lg,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.error, size: 40),
              const SizedBox(height: AppSpacing.md),
              if (title != null) ...[
                Text(title!,
                    textAlign: TextAlign.center, style: AppTextStyles.title),
                const SizedBox(height: AppSpacing.sm),
              ],
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySecondary,
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(onPressed: onRetry, child: Text(retryLabel)),
            ],
          ),
        ),
      ),
    );
  }
}
