import 'package:campus_event_hub/app/providers.dart';
import 'package:campus_event_hub/app/theme.dart';
import 'package:campus_event_hub/core/widgets/widgets.dart';
import 'package:campus_event_hub/features/certificates/domain/certificate_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CertificateVerifyScreen extends ConsumerStatefulWidget {
  final String? initialCode;
  const CertificateVerifyScreen({super.key, this.initialCode});

  @override
  ConsumerState<CertificateVerifyScreen> createState() =>
      _CertificateVerifyScreenState();
}

class _CertificateVerifyScreenState
    extends ConsumerState<CertificateVerifyScreen> {
  final _codeController = TextEditingController();
  CertificateVerification? _result;
  bool _loading = false;
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null && widget.initialCode!.isNotEmpty) {
      _codeController.text = widget.initialCode!;
      _verify();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _loading = true;
      _searched = true;
    });

    final repo = ref.read(certificateRepositoryProvider);
    final result = await repo.verifyByCode(code);

    if (!mounted) return;
    setState(() {
      _loading = false;
      _result = result.valueOrNull;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Verify Certificate'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Lookup input card
                Material(
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: AppColors.border),
                    borderRadius: AppRadius.lg,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Icon header
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.workspace_premium_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Text(
                          'Certificate Authenticity',
                          style: AppTextStyles.headline,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        const Text(
                          'Enter the unique certificate identification code to verify credentials and completion records.',
                          style: AppTextStyles.bodySecondary,
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Code input field
                        TextField(
                          controller: _codeController,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Certificate Code',
                            hintText: 'e.g. CP2025WH0421',
                            prefixIcon: const Icon(Icons.qr_code_2_rounded),
                            suffixIcon: _codeController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _codeController.clear();
                                      setState(() {
                                        _result = null;
                                        _searched = false;
                                      });
                                    },
                                  )
                                : null,
                          ),
                          onSubmitted: (_) => _verify(),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Verify button
                        AppPrimaryButton(
                          label: 'Verify Certificate',
                          icon: const Icon(Icons.verified_outlined, size: 18),
                          iconPosition: AppButtonIconPosition.left,
                          isLoading: _loading,
                          fullWidth: true,
                          onPressed: _loading ? null : _verify,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Result card
                if (_searched && !_loading && _result != null)
                  _VerificationResultCard(
                    result: _result!,
                    code: _codeController.text.trim(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VerificationResultCard extends StatelessWidget {
  final CertificateVerification result;
  final String code;

  const _VerificationResultCard({
    required this.result,
    required this.code,
  });

  @override
  Widget build(BuildContext context) {
    if (!result.isValid) {
      return Material(
        color: AppColors.dangerBg,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
          borderRadius: AppRadius.lg,
        ),
        child: const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.cancel_rounded, color: AppColors.error, size: 24),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invalid Certificate Code',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      'No valid certificate record was found matching this code. Please check the code for typos.',
                      style: AppTextStyles.bodySecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border),
        borderRadius: AppRadius.lg,
      ),
      child: Column(
        children: [
          // Valid Header banner
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.large),
              ),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.success.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 22),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Verified Official Certificate',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ),
                AppBadge(
                  label: 'Authentic',
                  tone: AppBadgeTone.success,
                ),
              ],
            ),
          ),

          // Details List
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.person_outline,
                  label: 'Student',
                  value: result.studentName ?? '—',
                ),
                const Divider(height: AppSpacing.lg, color: AppColors.border),
                _DetailRow(
                  icon: Icons.event_available_outlined,
                  label: 'Event',
                  value: result.eventName ?? '—',
                ),
                const Divider(height: AppSpacing.lg, color: AppColors.border),
                _DetailRow(
                  icon: Icons.groups_outlined,
                  label: 'Organizing Club',
                  value: result.organizerName ?? '—',
                ),
                if (result.eventDate != null) ...[
                  const Divider(height: AppSpacing.lg, color: AppColors.border),
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date Issued',
                    value: DateFormat('d MMMM yyyy').format(result.eventDate!),
                  ),
                ],
                const Divider(height: AppSpacing.lg, color: AppColors.border),
                _DetailRow(
                  icon: Icons.fingerprint,
                  label: 'Certificate Code',
                  value: code,
                  isMonospace: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isMonospace;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isMonospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: AppSpacing.md),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: isMonospace
                ? const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.primary,
                  )
                : AppTextStyles.label,
          ),
        ),
      ],
    );
  }
}

