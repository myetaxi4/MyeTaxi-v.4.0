import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/vehicles_screen.dart';
import 'screens/trips_screen.dart';
import 'screens/drivers_screen.dart';
import 'screens/alerts_screen.dart';
import 'services/notification_service.dart';
import 'services/expiry_checker_service.dart';
import 'services/gps_service.dart';
import 'services/sms_listener_service.dart';
import 'providers/fleet_provider.dart';
import 'screens/auth/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kDemoMode) {
    await Firebase.initializeApp();
    await NotificationService().initialize();
  }
  runApp(const ProviderScope(child: MyeTaxiTrackerApp()));
}

class MyeTaxiTrackerApp extends ConsumerStatefulWidget {
  const MyeTaxiTrackerApp({super.key});

  @override
  ConsumerState<MyeTaxiTrackerApp> createState() => _MyeTaxiTrackerAppState();
}

class _MyeTaxiTrackerAppState extends ConsumerState<MyeTaxiTrackerApp> {
  bool _servicesInitialized = false;

  @override
  void initState() {
    super.initState();
    // Services are initialized after first auth state
    WidgetsBinding.instance.addPostFrameCallback((_) => _initServices());
  }

  Future<void> _initServices() async {
    if (kDemoMode) return;
    ref.listenManual(authProvider, (_, next) async {
      final uid = next.value?.uid;
      if (uid != null && !_servicesInitialized) {
        _servicesInitialized = true;

        // GPS & SMS services
        await GpsService().initialize(uid);
        await SmsListenerService().initialize();

        // Document expiry checker
        ExpiryCheckerService().startDailyCheck(uid);

        // Connect to GPS WebSocket server (update URL to your server)
        // GpsService().connectWebSocket('wss://your-gps-server.com/ws?owner=$uid');
        // Or use HTTP polling:
        // GpsService().startHttpPolling('https://your-gps-server.com');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844), // iPhone 14 base size
      minTextAdapt: true,
      builder: (_, __) => MaterialApp(
        title: 'MyeTaxi Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kDemoMode) return const MainShell();
    final auth = ref.watch(authProvider);
    return auth.when(
      loading: () => const _SplashScreen(),
      error: (_, __) => const _SplashScreen(),
      data: (user) => user != null ? const MainShell() : const AuthScreen(),
    );
  }
}

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    DashboardScreen(),
    VehiclesScreen(),
    TripsScreen(),
    DriversScreen(),
    AlertsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadAlertCountProvider);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.border),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.directions_car_outlined),
              activeIcon: Icon(Icons.directions_car),
              label: 'Fleet',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Trips',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Drivers',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: unreadCount > 0,
                label: Text('$unreadCount'),
                backgroundColor: AppTheme.red,
                child: const Icon(Icons.notifications_outlined),
              ),
              activeIcon: const Icon(Icons.notifications),
              label: 'Alerts',
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SPLASH SCREEN ────────────────────────────────────────────────────────────

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.accent, Color(0xFF0066FF)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.local_taxi,
                color: Colors.black, size: 48),
            ),
            const SizedBox(height: 20),
            const Text('MyeTaxi Tracker',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Fleet Intelligence Platform',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: AppTheme.accent,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}


