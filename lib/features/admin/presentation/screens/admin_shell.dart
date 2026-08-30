import 'package:campus_event_hub/app/theme.dart';
import 'package:campus_event_hub/features/admin/presentation/screens/admin_screens.dart';
import 'package:campus_event_hub/features/events/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  static const _screens = [
    AdminDashboardScreen(),
    HomeScreen(),
    PendingEventsScreen(),
    ClubsScreen(),
    AdminCalendarScreen(),
  ];

  static const _destinations = [
    NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Dashboard'),
    NavigationDestination(
        icon: Icon(Icons.explore_outlined),
        selectedIcon: Icon(Icons.explore),
        label: 'Campus'),
    NavigationDestination(
        icon: Icon(Icons.pending_actions_outlined),
        selectedIcon: Icon(Icons.pending_actions),
        label: 'Pending'),
    NavigationDestination(
        icon: Icon(Icons.groups_outlined),
        selectedIcon: Icon(Icons.groups),
        label: 'Clubs'),
    NavigationDestination(
        icon: Icon(Icons.calendar_month_outlined),
        selectedIcon: Icon(Icons.calendar_month),
        label: 'Calendar'),
  ];

  @override
  Widget build(BuildContext context) {
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
              destinations: _destinations
                  .map((d) => NavigationRailDestination(
                      icon: d.icon,
                      selectedIcon: d.selectedIcon,
                      label: Text(d.label)))
                  .toList(),
            ),
            const VerticalDivider(width: 1, color: AppColors.border),
            Expanded(child: IndexedStack(index: _index, children: _screens)),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primaryLight,
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: _destinations,
        ),
      ),
    );
  }
}
