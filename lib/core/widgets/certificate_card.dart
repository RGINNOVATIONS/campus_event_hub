import 'package:campus_event_hub/app/theme.dart';
import 'package:flutter/material.dart';

class CertificateCard extends StatelessWidget {
  final String title;
  final String code;
  final String? issuedAt;
  final VoidCallback? onDownload;
  final VoidCallback? onTap;

  const CertificateCard({
    super.key,
    required this.title,
    required this.code,
    this.issuedAt,
    this.onDownload,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.lg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lg,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: AppRadius.lg,
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.primary),
                    ),
                    if (issuedAt != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(issuedAt!, style: AppTextStyles.caption),
                    ],
                  ],
                ),
              ),
              if (onDownload != null) ...[
                const SizedBox(width: AppSpacing.md),
                IconButton(
                  onPressed: onDownload,
                  tooltip: 'Download certificate',
                  icon: const Icon(Icons.download_outlined),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
