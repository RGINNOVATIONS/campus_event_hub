import 'package:campus_pulse/app/providers.dart';
import 'package:campus_pulse/app/theme.dart';
import 'package:campus_pulse/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final isStudent = profile?.role.name == 'student';
    final initial = (profile?.fullName.isNotEmpty ?? false)
        ? profile!.fullName[0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Profile hero ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.xl,
                    AppSpacing.xl,
                    AppSpacing.xxl,
                  ),
                  child: Column(
                    children: [
                      // Avatar circle
                      Container(
                        width: 80,
                        height: 80,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color:
                              AppColors.textOnPrimary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                AppColors.textOnPrimary.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          initial,
                          style: AppTextStyles.headline.copyWith(
                            color: AppColors.textOnPrimary,
                            fontSize: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Name
                      Text(
                        profile?.fullName ?? 'Loading...',
                        style: AppTextStyles.title.copyWith(
                          color: AppColors.textOnPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      // Email
                      Text(
                        profile?.collegeEmail ?? '',
                        style: AppTextStyles.bodySecondary.copyWith(
                          color:
                              AppColors.textOnPrimary.withValues(alpha: 0.75),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Role badge
                      if (profile != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color:
                                AppColors.textOnPrimary.withValues(alpha: 0.15),
                            borderRadius: AppRadius.full,
                            border: Border.all(
                              color: AppColors.textOnPrimary
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            profile.role.name[0].toUpperCase() +
                                profile.role.name.substring(1),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textOnPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth:
                      MediaQuery.of(context).size.width >= AppBreakpoints.wide
                          ? AppSpacing.maxContentWidth
                          : double.infinity,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Identity info card ──────────────────────────
                      _ProfileCard(
                        title: 'Campus Identity',
                        icon: Icons.badge_outlined,
                        children: [
                          _ProfileInfoRow(
                            label: 'College ID',
                            value: profile?.collegeId ?? '—',
                            icon: Icons.badge_outlined,
                          ),
                          _ProfileInfoRow(
                            label: 'Department',
                            value: profile?.department ?? '—',
                            icon: Icons.apartment_outlined,
                          ),
                          _ProfileInfoRow(
                            label: 'Academic year',
                            value: profile?.academicYear ?? '—',
                            icon: Icons.calendar_month_outlined,
                          ),
                          _ProfileInfoRow(
                            label: 'Role',
                            value: profile != null
                                ? profile.role.name[0].toUpperCase() +
                                    profile.role.name.substring(1)
                                : '—',
                            icon: Icons.person_outline,
                            isLast: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // ── Actions card ────────────────────────────────
                      _ProfileCard(
                        title: 'Account',
                        icon: Icons.settings_outlined,
                        children: [
                          // Browse Clubs (all users)
                          _ProfileActionTile(
                            icon: Icons.groups_outlined,
                            label: 'Browse Clubs',
                            subtitle: 'Discover and follow campus clubs',
                            onTap: () => context.push('/student/clubs'),
                          ),

                          // Notification Preferences (student only)
                          if (isStudent)
                            _ProfileActionTile(
                              icon: Icons.tune_outlined,
                              label: 'Notification Preferences',
                              subtitle: 'Manage followed clubs & categories',
                              onTap: () => context
                                  .push('/student/notification-preferences'),
                            ),

                          // Notifications
                          _ProfileActionTile(
                            icon: Icons.notifications_outlined,
                            label: 'Notifications',
                            subtitle: 'View your notification feed',
                            onTap: () => context.push('/student/notifications'),
                            isLast: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // ── Logout ───────────────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadius.lg,
                          border: Border.all(color: AppColors.border),
                          boxShadow: AppShadows.sm,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: AppRadius.lg,
                          child: InkWell(
                            onTap: () => ref
                                .read(authControllerProvider.notifier)
                                .logout(),
                            borderRadius: AppRadius.lg,
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      color: AppColors.dangerBg,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.logout,
                                      size: 18,
                                      color: AppColors.danger,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  const Text(
                                    'Sign out',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.danger,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Profile card container ────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _ProfileCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lg,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Row(
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
                  title,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.border),
          ...children,
        ],
      ),
    );
  }
}

// ── Profile info row ──────────────────────────────────────────────────────────

class _ProfileInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isLast;

  const _ProfileInfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 120,
            child: Text(label, style: AppTextStyles.bodySecondary),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.label,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Profile action tile ───────────────────────────────────────────────────────

class _ProfileActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLast;

  const _ProfileActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : const Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.label),
                    Text(subtitle, style: AppTextStyles.caption),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
