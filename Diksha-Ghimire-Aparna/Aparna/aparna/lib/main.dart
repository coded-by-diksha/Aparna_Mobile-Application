import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aparna/core/di/dependency_injection.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:aparna/l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:aparna/core/services/firebase_messaging_service.dart';
import 'package:aparna/data/services/notification_service.dart';
import 'package:aparna/core/guards/auth_guard.dart';
import 'package:aparna/core/services/secure_session_service.dart';
import 'package:aparna/presentation/screens/main_navigation_screen.dart';
import 'package:aparna/presentation/screens/login.dart';
import 'package:aparna/presentation/screens/admin/admin_dashboard.dart';

// Export theme colors for use in other files
class AppTheme {
  static const Color primaryColor = Color(0xFF792F2F);
  static const Color secondaryColor = Color(0xFFFF9999);
  static const Color backgroundColor = Color(0xFFFFCCBC);
  static const Color surfaceColor = Colors.white;
  static const Color darkPrimaryColor = Color(0xFFB26A6A);
  static const Color darkBackgroundColor = Color(0xFF2D2D2D);
  static const Color darkSurfaceColor = Color(0xFF232323);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  
  if (!kIsWeb) {
    // Initializing Firebase for Mobile
    await Firebase.initializeApp();
    
    // Setting up background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    
    // Initializing Firebase Messaging and getting FCM token
    await DependencyInjection.authRepository.ensureTokenLoaded();
    await FirebaseMessagingService.initialize();
    
    // Setting up foreground message handler
    FirebaseMessagingService.setupForegroundMessageHandler();
  } else {
    print('Running on Web: Firebase Messaging bypassed');
  }

  final String languageCode = await SecureSessionService.getLanguage() ?? 'en';
  
  runApp(MultiBlocProvider(
    providers: DependencyInjection.getBlocProviders(),
    child: MyApp(locale: Locale(languageCode)),
  ));
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  final Locale locale;
  
  const MyApp({Key? key, required this.locale}) : super(key: key);

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Locale? _locale;
  DateTime? _lastFcmRegister;

  // Initialize the app
  @override
  void initState() {
    super.initState();
    _locale = widget.locale;
    WidgetsBinding.instance.addObserver(this);
  }

  // Dispose the app
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

// Did change app lifecycle state

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !kIsWeb) {
        // Reregister the FCM token if the app is resumed and not on web
        _reregisterFCMTokenIfLoggedIn();
    }
  }

  // Reregister the FCM token if the user is logged in (debounced: max once per 60s)
  Future<void> _reregisterFCMTokenIfLoggedIn() async {
    if (!DependencyInjection.authRepository.isLoggedIn) return;
    if (_lastFcmRegister != null &&
        DateTime.now().difference(_lastFcmRegister!) < const Duration(seconds: 60)) {
      return;
    }
    try {
      String? token = await FirebaseMessagingService.getToken();
      if (token == null) token = await FirebaseMessagingService.getSavedToken();
      if (token != null) {
        _lastFcmRegister = DateTime.now();
        await FirebaseMessagingService.saveToken(token);
        await NotificationService().registerDevice(token);
      }
    } catch (_) {}
  }

  // Set the locale

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  // Build the app

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('ne', ''),
      ],
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Light theme

final ThemeData lightTheme = ThemeData(
  primaryColor: AppTheme.primaryColor,
  colorScheme: ColorScheme.light(
    primary: AppTheme.primaryColor,
    secondary: AppTheme.secondaryColor,
    background: AppTheme.backgroundColor,
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    surface: AppTheme.surfaceColor,
    onSurface: Colors.black,
  ),
  scaffoldBackgroundColor: AppTheme.backgroundColor,
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black),
    bodyMedium: TextStyle(color: Colors.black87),
    titleLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
    ),
  ),
);

// Dark theme

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: AppTheme.darkPrimaryColor,
  colorScheme: ColorScheme.dark(
    primary: AppTheme.darkPrimaryColor,
    secondary: AppTheme.secondaryColor,
    background: AppTheme.darkBackgroundColor,
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    surface: AppTheme.darkSurfaceColor,
    onSurface: Colors.white,
  ),
  scaffoldBackgroundColor: AppTheme.darkBackgroundColor,
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white70),
    titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppTheme.darkPrimaryColor,
      foregroundColor: Colors.white,
    ),
  ),
);

// Splash screen — auto-routes to dashboard or welcome screen based on saved token
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _routeFromSession();
  }

  Future<void> _routeFromSession() async {
    try {
      final SessionStatus status =
          await DependencyInjection.sessionManagerService.getSessionStatus();

      if (!mounted) return;

      if (status.isValid) {
        final userRole = status.role?.toLowerCase() ?? 'user';
        final userName = (status.userName != null && status.userName!.trim().isNotEmpty)
            ? status.userName!.trim()
            : 'User';

        if (userRole == 'admin') {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => AdminDashboard(
                userName: userName,
                userProfile: {
                  'role': userRole,
                  'username': userName,
                  'uid': status.userId,
                },
              ),
            ),
            (route) => false,
          );
          return;
        }

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => MainNavigationScreen(userName: userName),
          ),
          (route) => false,
        );
        return;
      }

      if (status.isExpired) {
        print('[SplashScreen] Session expired; routing to login without clearing storage');
      }

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (_) {
      print('[SplashScreen] Session check failed; routing to login without clearing storage');
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/aparna_logo.png',
              height: 120,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.woman_rounded, size: 100),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }
}

// Main widget

class Main extends StatelessWidget {
  const Main({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: Colors.black54),
            onPressed: () => _showLanguageDialog(context),
          ),
          const SizedBox(width: 10),
        ],
      ),
      // Remove backgroundColor and use a Container with gradient as the body background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundColor,
              AppTheme.secondaryColor,
            ],
          ),
        ),
      
        child: Center(
          child: Padding( 
            padding: const EdgeInsets.symmetric(horizontal: 20.0),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/aparna_logo.png', // Ensure this asset exists
                  height: 200,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.woman_rounded, size: 100),
                ),
                Text(
                  '"${l10n.welcomeToAparna}"\n ${l10n.trackYourFlowStayStressFree}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color.fromARGB(221, 0, 0, 0),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.aparnaIntroDescription,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AuthGuard()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    l10n.moveIn,
                    style: const TextStyle(color: Color.fromARGB(221, 252, 252, 252)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.language),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.english),
              trailing: Localizations.localeOf(context).languageCode == 'en'
                  ? const Icon(Icons.check, color: AppTheme.primaryColor)
                  : null,
              onTap: () => _setLanguage(context, 'en'),
            ),
            ListTile(
              title: Text(l10n.nepali),
              trailing: Localizations.localeOf(context).languageCode == 'ne'
                  ? const Icon(Icons.check, color: AppTheme.primaryColor)
                  : null,
              onTap: () => _setLanguage(context, 'ne'),
            ),
          ],
        ),
      ),
    );
  }

  void _setLanguage(BuildContext context, String code) async {
    await SecureSessionService.saveLanguage(code);
    if (context.mounted) {
      MyApp.setLocale(context, Locale(code));
      Navigator.pop(context);
    }
  }
}
