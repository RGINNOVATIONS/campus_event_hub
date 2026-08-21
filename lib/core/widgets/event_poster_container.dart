import 'package:cached_network_image/cached_network_image.dart';
import 'package:campus_pulse/app/theme.dart';
import 'package:flutter/material.dart';

class EventPosterContainer extends StatelessWidget {
  final String? imageUrl;
  final double aspectRatio;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const EventPosterContainer({
    super.key,
    this.imageUrl,
    this.aspectRatio = 16 / 9,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppRadius.lg;
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: radius,
        child: Container(
          color: AppColors.surfaceSubtle,
          child: imageUrl == null || imageUrl!.trim().isEmpty
              ? const _PosterFallback()
              : CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: fit,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, _) => const _PosterLoading(),
                  errorWidget: (context, _, __) => const _PosterError(),
                ),
        ),
      ),
    );
  }
}

class _PosterLoading extends StatelessWidget {
  const _PosterLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox.square(
        dimension: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _PosterFallback extends StatelessWidget {
  const _PosterFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.event, color: AppColors.textMuted, size: 36),
    );
  }
}

class _PosterError extends StatelessWidget {
  const _PosterError();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.broken_image_outlined,
          color: AppColors.textMuted, size: 36),
    );
  }
}
