import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';

import 'theme_mode_provider.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/account_screen.dart';
import '../features/auth/presentation/screens/auth_screen.dart';
import '../features/appointments/presentation/screens/appointment_screen.dart';
import '../features/health_logs/presentation/screens/health_logs_screen.dart';
import '../features/medicines/presentation/screens/medicines_screen.dart';
import 'theme.dart';

class HealthCompanionApp extends ConsumerWidget {
  const HealthCompanionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'MedTime',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: authState.isLoading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : authState.isAuthenticated
          ? const HomeShell()
          : const AuthScreen(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  int _previousIndex = 0;

  static const _screens = [
    MedicinesScreen(),
    HealthLogsScreen(),
    AppointmentScreen(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? const [Color(0xFF171429), Color(0xFF1A2A44), Color(0xFF131A2B)]
                  : const [Color(0xFFBF9BFF), Color(0xFFD7E6FF), Color(0xFFF2F6FF)],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
        ),
        _BackgroundBlobs(isDark: isDark),
        Scaffold(
          extendBody: true,
          body: _AnimatedTabBody(
            index: _index,
            previousIndex: _previousIndex,
            screens: _screens,
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF44516C).withValues(alpha: 0.65)
                      : Colors.white.withValues(alpha: 0.85),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F2A1E4A),
                    blurRadius: 18,
                    offset: Offset(0, 9),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: NavigationBar(
                    selectedIndex: _index,
                    height: 72,
                    backgroundColor: isDark
                        ? const Color(0xFF1B2136).withValues(alpha: 0.86)
                        : Colors.white.withValues(alpha: 0.84),
                    indicatorColor: isDark
                        ? const Color(0xFF6D4CE8).withValues(alpha: 0.42)
                        : AppTheme.softViolet,
                    elevation: 0,
                    onDestinationSelected: (value) => setState(() {
                      _previousIndex = _index;
                      _index = value;
                    }),
                    destinations: [
                      _destination(0, Icons.home_rounded, 'Medicines'),
                      _destination(1, Icons.calendar_month_rounded, 'Health Logs'),
                      _destination(2, Icons.event_note_rounded, 'Visits'),
                      _destination(3, Icons.person_outline_rounded, 'Account'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  NavigationDestination _destination(int idx, IconData icon, String label) {
    final selected = _index == idx;
    return NavigationDestination(
      icon: AnimatedScale(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        scale: selected ? 1.08 : 1.0,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: selected ? 1 : 0.78,
          child: Icon(icon),
        ),
      ),
      label: label,
    );
  }
}

class _AnimatedTabBody extends StatelessWidget {
  const _AnimatedTabBody({
    required this.index,
    required this.previousIndex,
    required this.screens,
  });

  final int index;
  final int previousIndex;
  final List<Widget> screens;

  @override
  Widget build(BuildContext context) {
    final movingForward = index >= previousIndex;
    return Stack(
      children: List.generate(screens.length, (i) {
        final isActive = i == index;
        final animateThis = i == index || i == previousIndex;
        return IgnorePointer(
          ignoring: !isActive,
          child: TickerMode(
            enabled: isActive,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              offset: animateThis
                  ? (isActive
                        ? Offset.zero
                        : Offset(movingForward ? -0.04 : 0.04, 0))
                  : Offset.zero,
              child: AnimatedOpacity(
                opacity: isActive ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: Offstage(offstage: !isActive, child: screens[i]),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _BackgroundBlobs extends StatelessWidget {
  const _BackgroundBlobs({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -70,
            right: -30,
            child: Container(
              width: 210,
              height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isDark ? const Color(0xFF7A5CFF) : const Color(0xFF8D5BFF))
                      .withValues(alpha: isDark ? 0.13 : 0.17),
                ),
              ),
            ),
          Positioned(
            top: 180,
            left: -90,
            child: Container(
              width: 220,
              height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isDark ? const Color(0xFF3A85C5) : const Color(0xFF6FD5FF))
                      .withValues(alpha: isDark ? 0.11 : 0.13),
                ),
              ),
            ),
          Positioned(
            bottom: 140,
            right: -65,
            child: Container(
              width: 190,
              height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isDark ? const Color(0xFF5B6DDA) : const Color(0xFFA48BFF))
                      .withValues(alpha: isDark ? 0.12 : 0.15),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
