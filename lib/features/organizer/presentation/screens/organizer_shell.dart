import 'package:campus_event_hub/app/theme.dart';
import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/features/attendance/presentation/screens/attendance_scan_screen.dart';
import 'package:campus_event_hub/features/organizer/presentation/screens/create_event_screen.dart';
import 'package:campus_event_hub/features/organizer/presentation/screens/organizer_dashboard_screen.dart';
import 'package:campus_event_hub/features/organizer/presentation/screens/organizer_events_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrganizerShell extends ConsumerStatefulWidget {
  const OrganizerShell({super.key});
  @override
  ConsumerState<OrganizerShell> createState() => _OrganizerShellState();
}

class _OrganizerShellState extends ConsumerState<OrganizerShell> {
  int _index = 0;

  void _goCreateEvent() => setState(() => _index = 2);

  void _goScan() => setState(() => _index = 3);

  void _goMyEvents([EventStatus? filter]) {
    ref.read(organizerEventsFilterProvider.notifier).state = filter;
    setState(() => _index = 1);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      OrganizerDashboardScreen(
        onCreateEvent: _goCreateEvent,
        onScanAttendance: _goScan,
        onMyEvents: _goMyEvents,
      ),
      const OrganizerEventsScreen(),
      const CreateEventScreen(),
      const AttendanceScanScreen(),
    ];

    const destinations = [
      NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      NavigationDestination(
        icon: Icon(Icons.event_note_outlined),
        selectedIcon: Icon(Icons.event_note),
        label: 'My Events',
      ),
      NavigationDestination(
        icon: Icon(Icons.add_circle_outline_rounded),
        selectedIcon: Icon(Icons.add_circle_rounded),
        label: 'Create Event',
      ),
      NavigationDestination(
        icon: Icon(Icons.qr_code_scanner_outlined),
        selectedIcon: Icon(Icons.qr_code_scanner),
        label: 'Scan',
      ),
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
