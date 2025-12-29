import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/app_provider.dart';
import 'core/services/supabase_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/sync_service.dart';
import 'core/services/presence_service.dart';
import 'core/services/realtime_notification_service.dart';
import 'features/auth/auth_page.dart';
import 'features/navigation/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseService.initialize();
  
  // Initialize Notifications
  await NotificationService().initialize();
  
  // Initialize Connectivity Service
  await ConnectivityService().initialize();
  
  // Initialize Sync Service
  await SyncService().initialize();
  
  // Initialize Presence Service (faster polling - 5 seconds)
  await PresenceService().initialize();
  
  // Initialize Realtime Notification Service (instant notifications)
  await RealtimeNotificationService().initialize();
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ANLifeTrackerApp());
}

class ANLifeTrackerApp extends StatelessWidget {
  const ANLifeTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: MaterialApp(
        title: 'AN Life Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: _AuthWrapper(),
        routes: {
          '/auth': (context) => const AuthPage(),
          '/home': (context) => const MainNavigation(),
        },
      ),
    );
  }
}

class _AuthWrapper extends StatefulWidget {
  @override
  State<_AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<_AuthWrapper> {
  bool? _isAuthenticated;
  
  @override
  void initState() {
    super.initState();
    _checkAuth();
    
    // Listen for auth state changes
    SupabaseService().client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      setState(() {
        _isAuthenticated = session != null;
      });
    });
  }
  
  Future<void> _checkAuth() async {
    final supabase = SupabaseService();
    setState(() {
      _isAuthenticated = supabase.isAuthenticated;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // Show loading while checking
    if (_isAuthenticated == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Check if user is authenticated
    if (_isAuthenticated!) {
      // Load user data and go to main app
      context.read<AppProvider>().refreshUserData();
      return const MainNavigation();
    } else {
      // Show auth page
      return const AuthPage();
    }
  }
}
