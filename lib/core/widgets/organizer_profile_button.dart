import 'package:campus_event_hub/app/providers.dart';
import 'package:campus_event_hub/app/theme.dart';
import 'package:campus_event_hub/features/profile/presentation/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Clean, responsive profile avatar button for the top-right of Organizer AppBars.
class OrganizerProfileButton extends ConsumerWidget {
  const OrganizerProfileButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final initial = (profile?.fullName.isNotEmpty ?? false)
        ? profile!.fullName[0].toUpperCase()
        : 'O';

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.md),
      child: Center(
        child: Tooltip(
          message: 'Profile & Account',
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              customBorder: const CircleBorder(),
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: AppShadows.sm,
                ),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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
