import 'package:campus_pulse/app/theme.dart';
import 'package:campus_pulse/features/attendance/presentation/screens/attendance_scan_screen.dart';
import 'package:campus_pulse/features/events/presentation/screens/home_screen.dart';
import 'package:campus_pulse/features/organizer/presentation/screens/create_event_screen.dart';
import 'package:campus_pulse/features/organizer/presentation/screens/organizer_dashboard_screen.dart';
import 'package:campus_pulse/features/organizer/presentation/screens/organizer_events_screen.dart';
import 'package:campus_pulse/features/profile/presentation/screens/profile_screen.dart';
import 'package:flutter/material.dart';

class OrganizerShell extends StatefulWidget {
  const OrganizerShell({super.key});
  @override
  State<OrganizerShell> createState() => _OrganizerShellState();
}

class _OrganizerShellState extends State<OrganizerShell> {
  int _index = 0;

  void _goCreateEvent() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const CreateEventScreen()));
  }

  void _goScan() => setState(() => _index = 3);

  void _goMyEvents() => setState(() => _index = 2);

  @override
  Widget build(BuildContext context) {
    final screens = [
      OrganizerDashboardScreen(
        onCreateEvent: _goCreateEvent,
        onScanAttendance: _goScan,
        onMyEvents: _goMyEvents,
      ),
      const HomeScreen(),
      const OrganizerEventsScreen(),
      const AttendanceScanScreen(),
      const ProfileScreen(),
    ];

    const destinations = [
      NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard'),
      NavigationDestination(
          icon: Icon(Icons.explore_outlined),
          selectedIcon: Icon(Icons.explore),
          label: 'Campus'),
      NavigationDestination(
          icon: Icon(Icons.event_note_outlined),
          selectedIcon: Icon(Icons.event_note),
          label: 'My Events'),
      NavigationDestination(
          icon: Icon(Icons.qr_code_scanner_outlined),
          selectedIcon: Icon(Icons.qr_code_scanner),
          label: 'Scan'),
      NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile'),
    ];

    final isWide = MediaQuery.of(context).size.width >= AppBreakpoints.desktop;
    if (isWide) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: AppColors.surface,
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: NavigationRailLabelType.all,
              indicatorColor: AppColors.primaryLight,
              destinations: destinations
                  .map((d) => NavigationRailDestination(
                      icon: d.icon,
                      selectedIcon: d.selectedIcon,
                      label: Text(d.label)))
                  .toList(),
            ),
            const VerticalDivider(width: 1, color: AppColors.border),
            Expanded(child: IndexedStack(index: _index, children: screens)),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          onPressed: _goCreateEvent,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Create Event'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primaryLight,
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: destinations,
        ),
      ),
    );
  }
}
