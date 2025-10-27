import 'package:flutter/material.dart';
import 'package:kpass/features/dashboard/presentation/widgets/assignments_summary_tab.dart';
import 'package:kpass/features/courses/presentation/pages/courses_tab_screen.dart';
import 'package:kpass/features/calendar/presentation/pages/timetable_screen.dart';
import 'package:kpass/features/calendar/presentation/pages/calendar_tab_screen.dart';
import 'package:kpass/features/settings/presentation/pages/settings_tab_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const AssignmentsSummaryTab(),
    const CoursesScreen(),
    const TimetableScreen(),
    const CalendarTab(),
    const SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.onSurfaceVariant,
        backgroundColor: theme.colorScheme.surface,
        elevation: 8,
        iconSize: 24,
        selectedFontSize: 0,
        unselectedFontSize: 0,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            activeIcon: const Icon(Icons.dashboard),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.school_outlined),
            activeIcon: const Icon(Icons.school),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_view_week_outlined),
            activeIcon: const Icon(Icons.calendar_view_week),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_today_outlined),
            activeIcon: const Icon(Icons.calendar_today),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: '',
          ),
        ],
      ),
    );
  }
}
