import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/supabase_config.dart';
import 'core/constants/app_colors.dart';
import 'core/services/notification_service.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // Initialize notifications
  await NotificationService().init(
    onNotificationClick: (payload) {
      if (payload != null) {
        scheduleKey.currentState?.handleNotificationTap(payload);
      }
    },
  );

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
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ),
      ),
      home: const _AuthGate(),
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

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      ScheduleScreen(key: scheduleKey),
      const ClassManagementScreen(),
      SalaryReportScreen(key: salaryKey),
      const SettingsScreen(),
    ];
    _checkInitialNotification();
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
    return Scaffold(
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
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) {
            scheduleKey.currentState?.loadSessions(showLoading: true);
          } else if (index == 2) {
            salaryKey.currentState?.loadData(showLoading: true);
          } else if (index == 1) {
            studentListKey.currentState?.loadStudents();
          }
        },
        onFabPressed: _onFabPressed,
      ),
    );
  }

  void _onFabPressed() async {
    // Default to Add Session for L?ch, L?p h?c, Luong
    final added = await showFormBottomSheet<bool>(
      context: context,
      child: const AddSessionScreen(),
    );
    if (added == true) {
      scheduleKey.currentState?.loadSessions();
    }
  }
}
