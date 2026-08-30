import 'package:campus_event_hub/app/providers.dart';
import 'package:campus_event_hub/app/theme.dart';
import 'package:campus_event_hub/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final isStudent = profile?.role.name == 'student';
    final isOrganizer = profile?.role.name == 'organizer';
    final initial = (profile?.fullName.isNotEmpty ?? false)
        ? profile!.fullName[0].toUpperCase()
        : '?';


    // Build role-aware identity rows (filtering out empty/placeholder values)
    final infoRows = <_ProfileInfoData>[];
    if (profile != null) {
      if (isStudent) {
        if (_isValid(profile.studentId)) {
          infoRows.add(const _ProfileInfoData(
            label: 'Student ID',
            icon: Icons.badge_outlined,
          ).withValue(profile.studentId));
        }
        if (_isValid(profile.rollNo)) {
          infoRows.add(const _ProfileInfoData(
            label: 'Roll No',
            icon: Icons.numbers_outlined,
          ).withValue(profile.rollNo));
        }
        if (_isValid(profile.programme)) {
          infoRows.add(const _ProfileInfoData(
            label: 'Programme',
            icon: Icons.school_outlined,
          ).withValue(profile.programme));
        }
        if (_isValid(profile.branch)) {
          infoRows.add(const _ProfileInfoData(
            label: 'Branch',
            icon: Icons.apartment_outlined,
          ).withValue(profile.branch));
        }
        if (_isValid(profile.academicYear)) {
          infoRows.add(const _ProfileInfoData(
            label: 'Academic year',
            icon: Icons.calendar_month_outlined,
          ).withValue(profile.academicYear));
        }
      } else {
        final idLabel = isOrganizer ? 'Organizer ID' : 'Staff ID';
        if (_isValid(profile.studentId)) {
          infoRows.add(_ProfileInfoData(
            label: idLabel,
            icon: Icons.badge_outlined,
          ).withValue(profile.studentId));
        }
      }

      if (_isValid(profile.collegeEmail)) {
        infoRows.add(const _ProfileInfoData(
          label: 'Email',
          icon: Icons.email_outlined,
        ).withValue(profile.collegeEmail));
      }

      infoRows.add(const _ProfileInfoData(
        label: 'Role',
        icon: Icons.person_outline,
      ).withValue(
        profile.role.name[0].toUpperCase() + profile.role.name.substring(1),
      ));
    }

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
                        width: 84,
                        height: 84,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.textOnPrimary.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.textOnPrimary.withValues(alpha: 0.35),
                            width: 3,
                          ),
                        ),
                        child: Text(
                          initial,
                          style: AppTextStyles.headline.copyWith(
                            color: AppColors.textOnPrimary,
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Name
                      Text(
                        profile?.fullName ?? 'Loading...',
                        style: AppTextStyles.title.copyWith(
                          color: AppColors.textOnPrimary,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 3),

                      // Email
                      Text(
                        profile?.collegeEmail ?? '',
                        style: AppTextStyles.bodySecondary.copyWith(
                          color: AppColors.textOnPrimary.withValues(alpha: 0.82),
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      // Role badge
                      if (profile != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.textOnPrimary.withValues(alpha: 0.16),
                            borderRadius: AppRadius.full,
                            border: Border.all(
                              color: AppColors.textOnPrimary.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Text(
                            profile.role.name[0].toUpperCase() +
                                profile.role.name.substring(1),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
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
                          for (int i = 0; i < infoRows.length; i++)
                            _ProfileInfoRow(
                              label: infoRows[i].label,
                              value: infoRows[i].value,
                              icon: infoRows[i].icon,
                              isLast: i == infoRows.length - 1,
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

                          // Notifications (student only)
                          if (isStudent)
                            _ProfileActionTile(
                              icon: Icons.notifications_outlined,
                              label: 'Notifications',
                              subtitle: 'View your notification feed',
                              onTap: () =>
                                  context.push('/student/notifications'),
                              isLast: true,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // ── Logout ───────────────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                          boxShadow: AppShadows.sm,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: () => ref
                                .read(authControllerProvider.notifier)
                                .logout(),
                            borderRadius: BorderRadius.circular(16),
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
        borderRadius: BorderRadius.circular(16),
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
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEBEE),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 16, color: const Color(0xFFC62828)),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  title,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
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
        vertical: 13,
      ),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.bodySecondary.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.label.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
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
                : const Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEBEE),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: const Color(0xFFC62828)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.label.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF9E9E9E),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Profile data helper ──────────────────────────────────────────────────────

bool _isValid(String? value) {
  if (value == null) return false;
  final trimmed = value.trim();
  return trimmed.isNotEmpty && trimmed != '—' && trimmed.toUpperCase() != 'N/A';
}

class _ProfileInfoData {
  final String label;
  final String value;
  final IconData icon;

  const _ProfileInfoData({
    required this.label,
    this.value = '',
    required this.icon,
  });

  _ProfileInfoData withValue(String val) => _ProfileInfoData(
        label: label,
        value: val,
        icon: icon,
      );
}

