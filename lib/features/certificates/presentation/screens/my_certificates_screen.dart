import 'package:campus_pulse/app/providers.dart';
import 'package:campus_pulse/app/theme.dart';
import 'package:campus_pulse/core/widgets/widgets.dart';
import 'package:campus_pulse/features/certificates/domain/certificate_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

final myCertificatesProvider =
    FutureProvider.autoDispose<List<CertificateModel>>((ref) async {
  final repo = ref.watch(certificateRepositoryProvider);
  final result = await repo.myCertificates();
  return result.when(ok: (v) => v, err: (f) => throw f);
});

class MyCertificatesScreen extends ConsumerWidget {
  const MyCertificatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final certsAsync = ref.watch(myCertificatesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Certificates'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: certsAsync.when(
        loading: () =>
            const LoadingState(message: 'Loading your certificates...'),
        error: (e, _) => ErrorState(
          message: 'Could not load certificates.',
          onRetry: () => ref.invalidate(myCertificatesProvider),
        ),
        data: (certs) {
          if (certs.isEmpty) {
            return const EmptyState(
              icon: Icon(Icons.workspace_premium_outlined),
              title: 'Certificate not issued yet.',
              description:
                  'Attend and complete events to earn participation certificates. They will appear here once issued.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myCertificatesProvider),
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width >=
                              AppBreakpoints.wide
                          ? AppSpacing.maxContentWidth
                          : double.infinity,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: 'Earned Certificates',
                            subtitle:
                                '${certs.length} ${certs.length == 1 ? 'certificate' : 'certificates'} issued',
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          ...certs.map(
                            (cert) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.md),
                              child: _CertificateItemCard(certificate: cert),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Certificate item card ─────────────────────────────────────────────────────

class _CertificateItemCard extends ConsumerStatefulWidget {
  final CertificateModel certificate;
  const _CertificateItemCard({required this.certificate});

  @override
  ConsumerState<_CertificateItemCard> createState() =>
      _CertificateItemCardState();
}

class _CertificateItemCardState extends ConsumerState<_CertificateItemCard> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final cert = widget.certificate;
    final issuedLabel =
        'Issued ${DateFormat('d MMM yyyy').format(cert.issuedAt)}';

    return CertificateCard(
      title: cert.eventTitle,
      code: cert.certificateCode,
      issuedAt: issuedLabel,
      onDownload: _loading ? null : _download,
    );
  }

  Future<void> _download() async {
    setState(() => _loading = true);
    final repo = ref.read(certificateRepositoryProvider);
    // Capture messenger before async gap to satisfy use_build_context_synchronously
    final messenger = ScaffoldMessenger.of(context);
    final result = await repo.signedDownloadUrl(widget.certificate.id);
    if (!mounted) return;
    setState(() => _loading = false);

    result.when(
      ok: (url) async {
        final uri = Uri.tryParse(url);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          messenger.showSnackBar(
            const SnackBar(
                content: Text('Certificate downloaded (demo mode).')),
          );
        }
      },
      err: (f) {
        messenger.showSnackBar(SnackBar(content: Text(f.message)));
      },
    );
  }
}
