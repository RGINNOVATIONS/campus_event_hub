import 'package:campus_pulse/app/providers.dart';
import 'package:campus_pulse/app/theme.dart';
import 'package:campus_pulse/core/widgets/widgets.dart';
import 'package:campus_pulse/features/auth/domain/profile.dart';
import 'package:campus_pulse/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _collegeId = TextEditingController();
  final _department = TextEditingController();
  final _academicYear = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _acceptedTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  List<String> _allowedDomains = [];

  @override
  void initState() {
    super.initState();
    ref.read(authRepositoryProvider).allowedEmailDomains().then((d) {
      if (mounted) setState(() => _allowedDomains = d);
    });
  }

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _collegeId.dispose();
    _department.dispose();
    _academicYear.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(authControllerProvider);

    return Scaffold(
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
          child: Column(
            children: [
              // ── Custom header ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => context.canPop()
                          ? context.pop()
                          : context.go('/login'),
                      borderRadius: AppRadius.md,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadius.md,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          size: 20,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create account',
                          style: AppTextStyles.title.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Text(
                          'CampusPulse · SVKM NMIMS',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                    const Spacer(),
                    const AppBadge(
                      label: 'Verified access',
                      tone: AppBadgeTone.success,
                      icon: Icon(Icons.verified_user_outlined),
                    ),
                  ],
                ),
              ),

              // ── Form body ────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadius.lg,
                          border: Border.all(color: AppColors.border),
                          boxShadow: AppShadows.lg,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Header inside card
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.xl),
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryLighter,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(AppRadius.large),
                                    topRight: Radius.circular(AppRadius.large),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Your campus identity',
                                      style: AppTextStyles.headline.copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    const Text(
                                      'Use your official college identity to join events, follow clubs, and receive updates.',
                                      style: AppTextStyles.bodySecondary,
                                    ),
                                  ],
                                ),
                              ),

                              // Form fields
                              Padding(
                                padding: const EdgeInsets.all(AppSpacing.xl),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Personal info section
                                    const _FormSectionLabel(
                                      icon: Icons.person_outline,
                                      label: 'Personal information',
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        final twoColumns =
                                            constraints.maxWidth >= 560;
                                        final personalFields = [
                                          TextFormField(
                                            controller: _fullName,
                                            decoration: const InputDecoration(
                                              labelText: 'Full name',
                                              prefixIcon:
                                                  Icon(Icons.person_outline),
                                            ),
                                            validator: (v) =>
                                                (v == null || v.trim().isEmpty)
                                                    ? 'Required'
                                                    : null,
                                          ),
                                          TextFormField(
                                            controller: _email,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            decoration: const InputDecoration(
                                              labelText: 'College email',
                                              prefixIcon:
                                                  Icon(Icons.mail_outline),
                                            ),
                                            validator: (v) =>
                                                CollegeEmailValidator.validate(
                                                    v ?? '', _allowedDomains),
                                          ),
                                          TextFormField(
                                            controller: _collegeId,
                                            decoration: const InputDecoration(
                                              labelText:
                                                  'Student / employee ID',
                                              prefixIcon:
                                                  Icon(Icons.badge_outlined),
                                            ),
                                            validator: (v) =>
                                                (v == null || v.trim().isEmpty)
                                                    ? 'Required'
                                                    : null,
                                          ),
                                          TextFormField(
                                            controller: _department,
                                            decoration: const InputDecoration(
                                              labelText: 'Department',
                                              prefixIcon: Icon(
                                                  Icons.apartment_outlined),
                                            ),
                                            validator: (v) =>
                                                (v == null || v.trim().isEmpty)
                                                    ? 'Required'
                                                    : null,
                                          ),
                                          TextFormField(
                                            controller: _academicYear,
                                            decoration: const InputDecoration(
                                              labelText: 'Academic year',
                                              prefixIcon: Icon(Icons
                                                  .calendar_month_outlined),
                                            ),
                                            validator: (v) =>
                                                (v == null || v.trim().isEmpty)
                                                    ? 'Required'
                                                    : null,
                                          ),
                                        ];

                                        if (!twoColumns) {
                                          return Column(
                                            children: [
                                              for (final f
                                                  in personalFields) ...[
                                                f,
                                                const SizedBox(
                                                    height: AppSpacing.md),
                                              ],
                                            ],
                                          );
                                        }

                                        return Wrap(
                                          spacing: AppSpacing.md,
                                          runSpacing: AppSpacing.md,
                                          children: [
                                            for (final f in personalFields)
                                              SizedBox(
                                                width: (constraints.maxWidth -
                                                        AppSpacing.md) /
                                                    2,
                                                child: f,
                                              ),
                                          ],
                                        );
                                      },
                                    ),

                                    const SizedBox(height: AppSpacing.xl),

                                    // Credentials section
                                    const _FormSectionLabel(
                                      icon: Icons.lock_outline,
                                      label: 'Security credentials',
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        final twoColumns =
                                            constraints.maxWidth >= 560;
                                        final credFields = [
                                          TextFormField(
                                            controller: _password,
                                            obscureText: _obscurePassword,
                                            decoration: InputDecoration(
                                              labelText: 'Password',
                                              prefixIcon: const Icon(
                                                  Icons.lock_outline),
                                              suffixIcon: IconButton(
                                                icon: Icon(
                                                  _obscurePassword
                                                      ? Icons
                                                          .visibility_off_outlined
                                                      : Icons
                                                          .visibility_outlined,
                                                ),
                                                onPressed: () => setState(() =>
                                                    _obscurePassword =
                                                        !_obscurePassword),
                                              ),
                                            ),
                                            validator: (v) =>
                                                (v == null || v.length < 8)
                                                    ? 'At least 8 characters'
                                                    : null,
                                          ),
                                          TextFormField(
                                            controller: _confirmPassword,
                                            obscureText: _obscureConfirm,
                                            decoration: InputDecoration(
                                              labelText: 'Confirm password',
                                              prefixIcon: const Icon(
                                                  Icons.lock_reset_outlined),
                                              suffixIcon: IconButton(
                                                icon: Icon(
                                                  _obscureConfirm
                                                      ? Icons
                                                          .visibility_off_outlined
                                                      : Icons
                                                          .visibility_outlined,
                                                ),
                                                onPressed: () => setState(() =>
                                                    _obscureConfirm =
                                                        !_obscureConfirm),
                                              ),
                                            ),
                                            validator: (v) =>
                                                v != _password.text
                                                    ? 'Passwords do not match'
                                                    : null,
                                          ),
                                        ];

                                        if (!twoColumns) {
                                          return Column(
                                            children: [
                                              for (final f in credFields) ...[
                                                f,
                                                const SizedBox(
                                                    height: AppSpacing.md),
                                              ],
                                            ],
                                          );
                                        }

                                        return Wrap(
                                          spacing: AppSpacing.md,
                                          runSpacing: AppSpacing.md,
                                          children: [
                                            for (final f in credFields)
                                              SizedBox(
                                                width: (constraints.maxWidth -
                                                        AppSpacing.md) /
                                                    2,
                                                child: f,
                                              ),
                                          ],
                                        );
                                      },
                                    ),

                                    const SizedBox(height: AppSpacing.md),

                                    // Terms checkbox
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: AppRadius.md,
                                        border:
                                            Border.all(color: AppColors.border),
                                      ),
                                      child: CheckboxListTile(
                                        value: _acceptedTerms,
                                        onChanged: (v) => setState(
                                            () => _acceptedTerms = v ?? false),
                                        title: const Text(
                                          'I accept the Terms of Use',
                                          style: AppTextStyles.label,
                                        ),
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: AppSpacing.md),
                                        activeColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: AppRadius.md),
                                      ),
                                    ),

                                    // Error
                                    if (actionState.errorMessage != null) ...[
                                      const SizedBox(height: AppSpacing.md),
                                      _AuthError(
                                          message: actionState.errorMessage!),
                                    ],

                                    const SizedBox(height: AppSpacing.xl),

                                    // Register button
                                    AppPrimaryButton(
                                      label: 'Create account',
                                      icon: const Icon(Icons.arrow_forward),
                                      isLoading: actionState.isLoading,
                                      fullWidth: true,
                                      onPressed: actionState.isLoading ||
                                              !_acceptedTerms
                                          ? null
                                          : _submit,
                                    ),

                                    const SizedBox(height: AppSpacing.md),

                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'Already have an account?',
                                          style: AppTextStyles.bodySecondary,
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              context.push('/login'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: AppColors.primary,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: AppSpacing.sm),
                                          ),
                                          child: const Text(
                                            'Sign in',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authControllerProvider.notifier).register(
          fullName: _fullName.text.trim(),
          collegeEmail: _email.text.trim(),
          collegeId: _collegeId.text.trim(),
          department: _department.text.trim(),
          academicYear: _academicYear.text.trim(),
          password: _password.text,
        );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _FormSectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FormSectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(width: AppSpacing.md),
        const Expanded(
          child: Divider(
            color: AppColors.border,
            height: 1,
          ),
        ),
      ],
    );
  }
}

// ── Auth error ────────────────────────────────────────────────────────────────

class _AuthError extends StatelessWidget {
  final String message;

  const _AuthError({required this.message});

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
