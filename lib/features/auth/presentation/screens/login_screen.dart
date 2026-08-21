import 'package:campus_pulse/app/providers.dart';
import 'package:campus_pulse/app/theme.dart';
import 'package:campus_pulse/core/widgets/widgets.dart';
import 'package:campus_pulse/features/auth/data/demo_auth_repository.dart';
import 'package:campus_pulse/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(authControllerProvider);
    final isDemo = ref.watch(demoModeProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.background, AppColors.primaryLighter],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    // ── Branding hero ──────────────────────────────────
                    _BrandingHero(pulseAnimation: _pulseAnimation),
                    const SizedBox(height: AppSpacing.xl),

                    // ── Card ───────────────────────────────────────────
                    Container(
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
                            // Demo banner
                            if (isDemo)
                              _DemoBanner(onPick: _fillDemo)
                            else
                              const SizedBox(height: AppSpacing.xl),

                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                AppSpacing.xl,
                                isDemo ? AppSpacing.md : 0,
                                AppSpacing.xl,
                                AppSpacing.xl,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Sign in to your account',
                                    style: AppTextStyles.title.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  const Text(
                                    'Use your official college email and password.',
                                    style: AppTextStyles.bodySecondary,
                                  ),
                                  const SizedBox(height: AppSpacing.xl),

                                  // Email field
                                  TextFormField(
                                    controller: _email,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                      labelText: 'College email',
                                      prefixIcon: Icon(Icons.mail_outline),
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'Enter your college email'
                                            : null,
                                  ),
                                  const SizedBox(height: AppSpacing.md),

                                  // Password field
                                  TextFormField(
                                    controller: _password,
                                    obscureText: _obscure,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      prefixIcon:
                                          const Icon(Icons.lock_outline),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscure
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                        ),
                                        onPressed: () => setState(
                                            () => _obscure = !_obscure),
                                      ),
                                    ),
                                    validator: (v) => (v == null || v.isEmpty)
                                        ? 'Enter your password'
                                        : null,
                                  ),

                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () =>
                                          context.push('/forgot-password'),
                                      style: TextButton.styleFrom(
                                        foregroundColor:
                                            AppColors.textSecondary,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.sm,
                                          vertical: AppSpacing.xs,
                                        ),
                                      ),
                                      child: const Text(
                                        'Forgot password?',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),

                                  // Error message
                                  if (actionState.errorMessage != null) ...[
                                    const SizedBox(height: AppSpacing.sm),
                                    _AuthMessage(
                                      message: actionState.errorMessage!,
                                      icon: Icons.error_outline,
                                      color: AppColors.danger,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                  ],

                                  const SizedBox(height: AppSpacing.md),

                                  // Sign in button
                                  AppPrimaryButton(
                                    label: 'Sign in',
                                    icon: const Icon(Icons.arrow_forward),
                                    isLoading: actionState.isLoading,
                                    fullWidth: true,
                                    onPressed:
                                        actionState.isLoading ? null : _submit,
                                  ),

                                  const SizedBox(height: AppSpacing.lg),

                                  // Register link
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      const Text(
                                        "Don't have an account?",
                                        style: AppTextStyles.bodySecondary,
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            context.push('/register'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppColors.primary,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.sm,
                                          ),
                                        ),
                                        child: const Text(
                                          'Register',
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _fillDemo(String email) {
    _email.text = email;
    _password.text = DemoAccounts.demoPassword;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authControllerProvider.notifier)
        .login(_email.text, _password.text);
  }
}

// ── Branding hero ──────────────────────────────────────────────────────────────

class _BrandingHero extends StatelessWidget {
  final Animation<double> pulseAnimation;

  const _BrandingHero({required this.pulseAnimation});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Animated logo icon
        ScaleTransition(
          scale: pulseAnimation,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: AppRadius.lg,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.school_rounded,
              color: AppColors.textOnPrimary,
              size: 36,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'CampusPulse',
          style: AppTextStyles.display.copyWith(
            color: AppColors.primary,
            fontSize: 28,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.full,
            border: Border.all(color: AppColors.border),
          ),
          child: const Text(
            'SVKM NMIMS Shirpur Campus',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Auth message (error / success) ────────────────────────────────────────────

class _AuthMessage extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;

  const _AuthMessage({
    required this.message,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.sm,
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Demo banner ───────────────────────────────────────────────────────────────

class _DemoBanner extends StatelessWidget {
  final void Function(String email) onPick;

  const _DemoBanner({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppRadius.large),
          topRight: Radius.circular(AppRadius.large),
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.warning.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.bolt_rounded,
                color: AppColors.warning,
                size: 16,
              ),
              SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  'Demo mode — tap a role to autofill',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _DemoChip(
                icon: Icons.person_outline,
                label: 'Student',
                onTap: () => onPick(DemoAccounts.student.collegeEmail),
              ),
              _DemoChip(
                icon: Icons.groups_outlined,
                label: 'Organizer',
                onTap: () => onPick(DemoAccounts.organizer.collegeEmail),
              ),
              _DemoChip(
                icon: Icons.admin_panel_settings_outlined,
                label: 'Admin',
                onTap: () => onPick(DemoAccounts.admin.collegeEmail),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DemoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DemoChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.full,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.full,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
