import 'package:campus_event_hub/app/theme.dart';
import 'package:campus_event_hub/core/widgets/widgets.dart';
import 'package:campus_event_hub/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset password'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.background, AppColors.primaryLighter],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.lg,
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.lg,
                  ),
                  child: _sent
                      ? Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: EmptyState(
                            icon: const Icon(Icons.mark_email_read_outlined),
                            title: 'Reset link sent',
                            description:
                                'If an account exists for that email, a reset link has been sent. Check your inbox.',
                            action: AppSecondaryButton(
                              label: 'Back to sign in',
                              icon: const Icon(Icons.arrow_back),
                              iconPosition: AppButtonIconPosition.left,
                              fullWidth: true,
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Icon
                              Align(
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: AppRadius.lg,
                                  ),
                                  child: const Icon(
                                    Icons.lock_reset_outlined,
                                    color: AppColors.primary,
                                    size: 32,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),

                              Text(
                                'Reset your password',
                                style: AppTextStyles.headline.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              const Text(
                                'Enter your college email and we will send a secure reset link to your inbox.',
                                style: AppTextStyles.bodySecondary,
                              ),
                              const SizedBox(height: AppSpacing.xl),

                              const AppBadge(
                                label: 'Account recovery',
                                tone: AppBadgeTone.neutral,
                                icon: Icon(Icons.security_outlined),
                              ),
                              const SizedBox(height: AppSpacing.lg),

                              TextField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'College email',
                                  prefixIcon: Icon(Icons.mail_outline),
                                ),
                              ),

                              if (actionState.errorMessage != null) ...[
                                const SizedBox(height: AppSpacing.md),
                                _ResetError(message: actionState.errorMessage!),
                              ],

                              const SizedBox(height: AppSpacing.lg),

                              AppPrimaryButton(
                                label: 'Send reset link',
                                icon: const Icon(Icons.send_outlined),
                                isLoading: actionState.isLoading,
                                fullWidth: true,
                                onPressed: actionState.isLoading
                                    ? null
                                    : () async {
                                        final ok = await ref
                                            .read(
                                                authControllerProvider.notifier)
                                            .sendPasswordReset(
                                              _email.text.trim(),
                                            );
                                        if (ok && mounted) {
                                          setState(() => _sent = true);
                                        }
                                      },
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResetError extends StatelessWidget {
  final String message;

  const _ResetError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: AppRadius.sm,
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
