import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'screens/intro_screen.dart';
import 'screens/permission_screen.dart';
import 'screens/gesture_canvas_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_gesture_screen.dart';
import 'screens/login_screen.dart';
import 'utils/permissions.dart';
import 'utils/bubble_customizer.dart';
import 'data/models/gesture_model.dart';
import 'data/repositories/gesture_repository.dart';
import 'features/gestures/bloc/gesture_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  Hive.registerAdapter(GestureModelAdapter());
  await Hive.openBox<GestureModel>('gestures_box');
  await Hive.openBox('settings');
  
  PermissionHelper.initialize();
  runApp(const GestureApp());
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AppFlowController(),
    ),
    GoRoute(
      path: '/intro',
      builder: (context, state) => const IntroScreen(),
    ),
    GoRoute(
      path: '/permissions',
      builder: (context, state) => PermissionScreen(
         onDone: () {
            context.go('/login');
         },
      ),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/add',
      builder: (context, state) => const AddGestureScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    // Added specific route for Canvas to be pushed from anywhere
    GoRoute(
      path: '/canvas',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const GestureCanvasScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        opaque: false, // Important for transparent/blur effect
        barrierColor: Colors.black54,
      ),
    ),
  ],
);

class GestureApp extends StatefulWidget {
  const GestureApp({super.key});

  @override
  State<GestureApp> createState() => _GestureAppState();
}

class _GestureAppState extends State<GestureApp> {
  
  @override
  void initState() {
    super.initState();
    // Global Listener for Bubble Actions
    PermissionHelper.actionStream.listen((action) {
       if (action == 'OPEN_CANVAS') {
          // Use push to overlay it on top of whatever screen (Home, Settings, etc)
          _router.push('/canvas');
       } else if (action == 'OPEN_SETTINGS') {
          _router.push('/settings');
       }
    });

    _syncSettingsToNative();
  }

  Future<void> _syncSettingsToNative() async {
     final box = Hive.box('settings');
     
     // Sync all relevant native settings
     await BubbleCustomizer.updateBubbleOpacity(box.get('opacity', defaultValue: 1.0));
     await BubbleCustomizer.updateBubbleSize(box.get('size', defaultValue: 'medium'));
     // Need to map color names to hex codes if stored as names 'black','glass','neon'
     // Or just rely on what is stored. SettingsScreen stores raw strings 'black', etc.
     // BubbleCustomizer expects HEX.
     // Let's defer color sync for now or implement generic sync logic. 
     // Focus on Shake and Lock which are boolean.
     
     await BubbleCustomizer.updateBubbleLock(box.get('lock_position', defaultValue: false));
     await BubbleCustomizer.updateShakeToWake(box.get('shake_to_wake', defaultValue: false));
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => GestureRepository(),
      child: BlocProvider(
        create: (context) => GestureBloc(context.read<GestureRepository>())..add(LoadGestures()),
        child: ValueListenableBuilder(
          valueListenable: Hive.box('settings').listenable(),
          builder: (context, box, widget) {
            final isDark = box.get('is_dark_mode', defaultValue: true);
            return MaterialApp.router(
              routerConfig: _router,
              title: 'Gesture App',
              debugShowCheckedModeBanner: false,
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
              theme: ThemeData(
                brightness: Brightness.light,
                colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C63FF), brightness: Brightness.light),
                useMaterial3: true,
                scaffoldBackgroundColor: Colors.grey[100],
                appBarTheme: AppBarTheme(
                  backgroundColor: Colors.grey[100],
                  foregroundColor: Colors.black,
                  elevation: 0,
                  iconTheme: const IconThemeData(color: Colors.black),
                ),
                cardColor: Colors.white,
              ),
              darkTheme: ThemeData(
                brightness: Brightness.dark,
                colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C63FF), brightness: Brightness.dark),
                useMaterial3: true,
                scaffoldBackgroundColor: const Color(0xFF121212),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Color(0xFF121212),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  iconTheme: IconThemeData(color: Colors.white),
                ),
                cardColor: const Color(0xFF1E1E1E),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AppFlowController extends StatefulWidget {
  const AppFlowController({super.key});

  @override
  State<AppFlowController> createState() => _AppFlowControllerState();
}

class _AppFlowControllerState extends State<AppFlowController> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkInitialAction();
  }

  Future<void> _checkInitialAction() async {
    final action = await PermissionHelper.getInitialAction();
    
    // Handle Cold Start from Bubble
    if (action == 'OPEN_CANVAS') {
        if (mounted) context.go('/canvas');
        return;
    }
    
    // Normal Flow Check
    final perms = await PermissionHelper.checkPermissions();
    final allGranted = (perms['notification']??false) && (perms['overlay']??false) && (perms['battery_optimization']??false);
    
    setState(() {
       _isLoading = false;
    });
    
    if (mounted) {
       if (!allGranted) {
           context.go('/intro');
       } else {
           // Permissions granted, assume logged in or go home
           context.go('/home');
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black, 
      body: Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
    );
  }
}
