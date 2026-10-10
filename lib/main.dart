import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/supabase_config.dart';
import 'core/constants/app_colors.dart';
import 'core/services/notification_service.dart';
import 'core/services/network_status.dart';
import 'core/services/network_monitor.dart';
import 'core/services/supabase_service.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/verify_email_screen.dart';
import 'features/schedule/schedule_screen.dart';
import 'features/schedule/add_session_screen.dart';
import 'features/students/screens/student_list_screen.dart';
import 'features/students/screens/class_management_screen.dart';
import 'features/salary/salary_report_screen.dart';
import 'features/settings/settings_screen.dart';
import 'widgets/curved_bottom_nav.dart';
import 'widgets/form_bottom_sheet.dart';

final GlobalKey<ScheduleScreenState> scheduleKey =
    GlobalKey<ScheduleScreenState>();
final GlobalKey<SalaryReportScreenState> salaryKey =
    GlobalKey<SalaryReportScreenState>();
final GlobalKey<StudentListScreenState> studentListKey =
    GlobalKey<StudentListScreenState>();
final GlobalKey<ClassManagementScreenState> classManagementKey =
    GlobalKey<ClassManagementScreenState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  await NetworkMonitor.instance.start();

  // Initialize notifications
  await NotificationService().init(
    onNotificationClick: (payload) {
      if (payload != null) {
        scheduleKey.currentState?.handleNotificationTap(payload);
      }
    },
  );
  // Clear persisted Android alarms before the app UI starts. The schedule
  // screen rebuilds valid reminders from the current sessions after sign-in.
  await NotificationService().cancelAllNotifications();

  runApp(const EnglishClassManagerApp());
}

class EnglishClassManagerApp extends StatelessWidget {
  const EnglishClassManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'English Class Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
          background: AppColors.background,
          error: AppColors.error,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.divider),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
        datePickerTheme: DatePickerThemeData(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          headerBackgroundColor: AppColors.primary,
          headerForegroundColor: Colors.white,
          weekdayStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
          dayStyle: const TextStyle(fontWeight: FontWeight.w600),
          todayForegroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.white;
            return AppColors.primary;
          }),
          todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.primary;
            return Colors.transparent;
          }),
          todayBorder: const BorderSide(color: AppColors.primary),
          yearForegroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.white;
            return AppColors.textPrimary;
          }),
          yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.primary;
            return Colors.transparent;
          }),
          dayShape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          confirmButtonStyle: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
          cancelButtonStyle: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
          ),
        ),
        timePickerTheme: TimePickerThemeData(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          hourMinuteShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          hourMinuteColor: AppColors.background,
          hourMinuteTextColor: AppColors.textPrimary,
          dialBackgroundColor: AppColors.background,
          dialHandColor: AppColors.primary,
          dialTextColor: AppColors.textPrimary,
          entryModeIconColor: AppColors.primary,
          dayPeriodColor: AppColors.primary.withOpacity(.12),
          dayPeriodTextColor: AppColors.primary,
          helpTextStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ),
      ),
      builder: (context, child) => Stack(
        fit: StackFit.expand,
        children: [
          child ?? const SizedBox.shrink(),
          const Positioned(
            top: 8,
            right: 12,
            child: SafeArea(child: _OfflineStatusBadge()),
          ),
        ],
      ),
      home: const _AuthGate(),
    );
  }
}

class _OfflineStatusBadge extends StatelessWidget {
  const _OfflineStatusBadge();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: NetworkStatus.isOffline,
      builder: (context, offline, _) {
        if (!offline) return const SizedBox.shrink();
        return Material(
          color: AppColors.textPrimary.withOpacity(.88),
          borderRadius: BorderRadius.circular(20),
          elevation: 3,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: NetworkStatus.retry,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_rounded, size: 15, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'Mất mạng · Kết nối Internet để đồng bộ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;

        if (snapshot.connectionState == ConnectionState.waiting &&
            session == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (session != null) {
          final user = Supabase.instance.client.auth.currentUser;
          if (user?.emailConfirmedAt == null) {
            return const VerifyEmailScreen();
          }
          return const MainShell();
        }

        return const LoginScreen();
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final List<int> _tabHistory = [];
  DateTime? _lastBackPress;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    NetworkStatus.onRetry = _retryCurrentTab;
    NetworkStatus.dataRevision.addListener(_onDataUpdated);
    _screens = [
      ScheduleScreen(key: scheduleKey),
      ClassManagementScreen(key: classManagementKey),
      SalaryReportScreen(key: salaryKey),
      const SettingsScreen(),
    ];
    _checkInitialNotification();
  }

  @override
  void dispose() {
    NetworkStatus.onRetry = null;
    NetworkStatus.dataRevision.removeListener(_onDataUpdated);
    super.dispose();
  }

  Future<void> _checkInitialNotification() async {
    final payload = await NotificationService().getInitialPayload();
    if (payload != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scheduleKey.currentState?.handleNotificationTap(payload);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_tabHistory.isNotEmpty || _currentIndex != 0) {
          _lastBackPress = null;
          _goBackToPreviousTab();
        } else {
          _handleBackAtRoot();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: List.generate(_screens.length, (index) {
            final active = index == _currentIndex;
            return AnimatedOpacity(
              opacity: active ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: AnimatedScale(
                scale: active ? 1 : 0.985,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: _screens[index],
              ),
            );
          }),
        ),
        bottomNavigationBar: CurvedBottomNav(
          currentIndex: _currentIndex,
          onTap: _navigateToTab,
          onFabPressed: _onFabPressed,
        ),
      ),
    );
  }

  void _handleBackAtRoot() {
    final now = DateTime.now();
    final lastPress = _lastBackPress;
    if (lastPress != null &&
        now.difference(lastPress) <= const Duration(seconds: 2)) {
      _lastBackPress = null;
      SystemNavigator.pop();
      return;
    }

    _lastBackPress = now;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Nhấn Back lần nữa để thoát'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _navigateToTab(int index) {
    if (index == _currentIndex) {
      _refreshTab(index);
      return;
    }
    _tabHistory.add(_currentIndex);
    setState(() => _currentIndex = index);
    _refreshTab(index);
  }

  void _goBackToPreviousTab() {
    while (_tabHistory.isNotEmpty) {
      final previousIndex = _tabHistory.removeLast();
      if (previousIndex == _currentIndex) continue;
      setState(() => _currentIndex = previousIndex);
      _refreshTab(previousIndex);
      return;
    }
    // If no tab history remains, return to the main schedule before exiting.
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
        _tabHistory.clear();
      });
      _refreshTab(0);
    }
  }

  void _refreshTab(int index) {
    if (index == 0) {
      scheduleKey.currentState?.loadSessions();
    } else if (index == 2) {
      salaryKey.currentState?.loadData(showLoading: true);
    } else if (index == 1) {
      classManagementKey.currentState?.refreshCurrentData();
    }
  }

  void _onDataUpdated() {
    if (mounted) _refreshTab(_currentIndex);
  }

  void _retryCurrentTab() {
    unawaited(_refreshReferenceData());
    if (_currentIndex == 0) {
      scheduleKey.currentState
          ?.loadSessions(showLoading: true, forceRefresh: true);
    } else if (_currentIndex == 1) {
      classManagementKey.currentState?.refreshCurrentData(forceRefresh: true);
    } else if (_currentIndex == 2) {
      salaryKey.currentState?.loadData(showLoading: true, forceRefresh: true);
    } else {
      scheduleKey.currentState
          ?.loadSessions(showLoading: true, forceRefresh: true);
    }
  }

  Future<void> _refreshReferenceData() async {
    final service = SupabaseService.instance;
    await Future.wait([
      _quietlyRefresh(() => service.getProfile(forceRefresh: true)),
      _quietlyRefresh(() => service.getBranches(forceRefresh: true)),
      _quietlyRefresh(() => service.getPrograms(forceRefresh: true)),
      _quietlyRefresh(() => service.getStudents(forceRefresh: true)),
    ]);
  }

  Future<void> _quietlyRefresh(Future<Object?> Function() refresh) async {
    try {
      await refresh();
    } catch (error) {
      NetworkStatus.reportFailure(error);
    }
  }

  void _onFabPressed() async {
    // Default to Add Session for L?ch, L?p h?c, Luong
    final addedDate = await showFormBottomSheet<DateTime>(
      context: context,
      child: const AddSessionScreen(),
    );
    if (addedDate != null) {
      await scheduleKey.currentState?.showDateAndRefresh(addedDate);
    }
  }
}
