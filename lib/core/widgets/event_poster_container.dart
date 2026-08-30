import 'package:cached_network_image/cached_network_image.dart';
import 'package:campus_event_hub/app/theme.dart';
import 'package:campus_event_hub/core/demo/demo_data_store.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    final url = imageUrl?.trim();

    Widget content;
    if (url == null || url.isEmpty) {
      content = const _PosterFallback();
    } else if (DemoDataStore.instance.posterBytesByPath.containsKey(url)) {
      content = Image.memory(
        DemoDataStore.instance.posterBytesByPath[url]!,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => const _PosterError(),
      );
    } else if (url.startsWith('assets/')) {
      content = Image.asset(
        url,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => const _PosterError(),
      );
    } else if (url.startsWith('http://') || url.startsWith('https://')) {
      content = CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, _) => const _PosterLoading(),
        errorWidget: (context, _, __) => const _PosterError(),
      );
    } else {
      // Relative storage path: resolve via Supabase Storage if initialized
      content = FutureBuilder<String>(
        future: _resolveStorageUrl(url),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _PosterLoading();
          }
          final resolved = snapshot.data;
          if (resolved != null && resolved.isNotEmpty) {
            return CachedNetworkImage(
              imageUrl: resolved,
              fit: fit,
              width: double.infinity,
              height: double.infinity,
              placeholder: (context, _) => const _PosterLoading(),
              errorWidget: (context, _, __) => const _PosterError(),
            );
          }
          return const _PosterFallback();
        },
      );
    }

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: radius,
        child: Container(
          color: AppColors.surfaceSubtle,
          child: content,
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

Future<String> _resolveStorageUrl(String path) async {
  try {
    final cleanPath = path.contains('/event-posters/')
        ? path.split('/event-posters/').last.split('?').first
        : path.trim();
    if (cleanPath.isEmpty) return '';
    return await Supabase.instance.client.storage
        .from('event-posters')
        .createSignedUrl(cleanPath, 86400);
  } catch (_) {
    return '';
  }
}
