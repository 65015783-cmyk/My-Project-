import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/home_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';
import 'services/auth_service.dart';
import 'services/attendance_service.dart';
import 'services/leave_service.dart';
import 'services/salary_service.dart';
import 'services/hr_salary_service.dart';
import 'services/language_service.dart';
import 'services/notification_service.dart';
import 'services/overtime_service.dart';
import 'screens/splash_screen.dart';
import 'login/login_screen.dart';
import 'screens/admin/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('th', null);
  await initializeDateFormatting('en', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => AttendanceService()),
        ChangeNotifierProvider(create: (_) => LeaveService()),
        ChangeNotifierProvider(create: (_) => SalaryService()),
        ChangeNotifierProvider(create: (_) => HrSalaryService()),
        ChangeNotifierProvider(create: (_) => LanguageService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
        ChangeNotifierProvider(create: (_) => OvertimeService()),
      ],
      child: Consumer<LanguageService>(
        builder: (context, languageService, _) {
          return MaterialApp(
            title: 'Hummans - HR Management',
            debugShowCheckedModeBanner: false,
            locale: languageService.locale, // ใช้ locale จาก LanguageService
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('th', 'TH'),
              Locale('en', ''),
            ],
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF2196F3),
                primary: const Color(0xFF2196F3),
                secondary: const Color(0xFF64B5F6),
                surface: Colors.white,
              ),
              // ฟอนต์สไตล์โมเดิร์นสำหรับ HR App ทั้งแอป (Prompt)
              // ถ้าอยากเปลี่ยนฟอนต์ครั้งหน้า แก้แค่สองบรรทัดนี้พอ
              fontFamily: GoogleFonts.prompt().fontFamily,
              textTheme: GoogleFonts.promptTextTheme(),
              useMaterial3: true,
              cardTheme: CardTheme(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              appBarTheme: const AppBarTheme(
                elevation: 0,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                centerTitle: true,
              ),
            ),
            routes: {
              '/home': (context) => const MainScreen(),
              '/login': (context) => const LoginScreen(),
              '/admin': (context) => const AdminDashboard(),
            },
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const CalendarScreen(),
    const NotificationsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // โหลดจำนวนการแจ้งเตือนเมื่อเข้าหน้า MainScreen (เรียกครั้งเดียว)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      notificationService.loadNotificationCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Consumer<NotificationService>(
              builder: (context, notificationService, _) {
                return NavigationBar(
                  height: 64,
                  backgroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  indicatorColor: const Color(0xFFE3F2FD),
                  selectedIndex: _currentIndex,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  onDestinationSelected: (index) {
                    final previousIndex = _currentIndex;
                    setState(() {
                      _currentIndex = index;
                    });
                    // รีเฟรชจำนวนการแจ้งเตือนเมื่อเข้าหรือออกจากหน้า Notifications
                    if (index == 2 || previousIndex == 2) {
                      notificationService.loadNotificationCount();
                    }
                  },
                  destinations: [
                    const NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.calendar_today_outlined),
                      selectedIcon: Icon(Icons.calendar_today),
                      label: 'Calendar',
                    ),
                    NavigationDestination(
                      icon: _buildNotificationIcon(
                        Icons.notifications_outlined,
                        notificationService.unreadCount,
                        false,
                      ),
                      selectedIcon: _buildNotificationIcon(
                        Icons.notifications,
                        notificationService.unreadCount,
                        true,
                      ),
                      label: 'Notifications',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: 'Profile',
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(IconData icon, int count, bool isSelected) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (count > 0)
          Positioned(
            right: -8,
            top: -8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

