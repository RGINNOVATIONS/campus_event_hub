import 'package:campus_event_hub/app/theme.dart';
import 'package:flutter/material.dart';

class LoadingState extends StatelessWidget {
  final String? message;
  final bool compact;

  const LoadingState({super.key, this.message, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: compact ? 22 : 32,
          child: const CircularProgressIndicator(strokeWidth: 2.5),
        ),
        if (message != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary,
          ),
        ],
      ],
    );

    if (compact) return content;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: content,
      ),
    );
  }
}
