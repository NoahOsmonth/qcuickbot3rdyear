import 'package:flutter/material.dart'; // Ensure Material is imported
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core
import 'firebase_options.dart';

import 'dart:async';
import 'package:app_links/app_links.dart';
import 'dart:developer';

import './utils/supabase_client.dart';

// import './screens/splash_screen.dart';
import './screens/login_screen.dart';
import './screens/signup_screen.dart';
import './screens/chat_screen.dart';
import './screens/settings_screen.dart'; // Import SettingsScreen
import './screens/notification_screen.dart'; // Import NotificationScreen
import './services/auth_service.dart';
import './providers/theme_provider.dart'; // Import theme provider
import 'theme/app_theme.dart'; // Import custom light and dark themes

class PlaceholderSplashScreen extends StatelessWidget {
  const PlaceholderSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    log('Firebase initialized successfully');
  } catch (e) {
    log('Error initializing Firebase: $e');
    // Handle initialization error if needed, maybe show an error screen
  }

  // Initialize Supabase AFTER Firebase (if there's any dependency)
  await initializeSupabase();

  // Run the app within a ProviderScope for Riverpod state management
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  // Flag to indicate deep link processing
  bool _isHandlingDeepLink = false;

  @override
  void initState() {
    super.initState();
    initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  // Initializes the deep link handling
  Future<void> initDeepLinks() async {
    _appLinks = AppLinks();

    // Listen for incoming links when the app is already running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        log('App Link Received (while running): $uri');
        _handleAppLink(uri);
      },
      onError: (err) {
        log('Error listening to app links: $err');
      },
    );

    // Get the initial link that opened the app (if any)
    try {
      // Use getInitialLink() for app_links v6.0.0+
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        log('Initial App Link Received: $initialUri');
        await _handleAppLink(initialUri);
      }
    } catch (e) {
      log('Error getting initial app link: $e');
    }
  }

  // Helper function to process app links
  Future<void> _handleAppLink(Uri uri) async {
    // Check if it's the Supabase auth callback (host or path)
    final isLoginCallback =
        uri.scheme == 'qcuickbot' &&
        (uri.host == 'login-callback' ||
            uri.pathSegments.contains('login-callback'));
    if (isLoginCallback) {
      log('Supabase auth callback link detected.');
      // Start handling deep link
      setState(() {
        _isHandlingDeepLink = true;
      });
      // Recover session from URL fragment
      try {
        await supabase.auth.getSessionFromUrl(uri);
        log('Supabase session restored from deep link');
      } catch (e) {
        log('Error restoring session from deep link: $e');
      }
      // Navigate to chat screen after session restore
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/chat',
          (route) => false,
        );
      });
      // Done handling deep link
      setState(() {
        _isHandlingDeepLink = false;
      });
    } else {
      log('Received non-Supabase app link: $uri');
      // Handle other deep links if necessary
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the authentication state provided by authServiceProvider
    final authState = ref.watch(authStateProvider);
    final themeMode = ref.watch(
      themeProvider,
    ); // Watch the current app theme mode

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'QCUickBot',

      theme: AppTheme.lightTheme, // Use custom light theme
      darkTheme: AppTheme.darkTheme, // Use custom dark theme
      themeMode: themeMode, // Use theme mode from provider
      debugShowCheckedModeBanner: false, // Hide debug banner

      routes: {
        // Define a root route if needed, often handled by home/builder
        // '/': (context) => const PlaceholderSplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/chat': (context) => const ChatScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/notifications':
            (context) => const NotificationScreen(), // Add Notification route
      },

      // Use builder to wrap the navigator and handle auth-based redirects
      builder: (context, child) {
        // Show loading while processing deep link
        if (_isHandlingDeepLink) {
          return const PlaceholderSplashScreen();
        }
        return authState.when(
          data: (user) {
            final currentRouteName = ModalRoute.of(context)?.settings.name;
            log(
              'Auth state change in builder: User=${user?.id}, CurrentRoute=$currentRouteName',
            );

            // Determine target route based on auth state
            final targetRoute = user != null ? '/chat' : '/login';

            // Routes that should redirect to targetRoute if auth state doesn't match
            final authRoutes = ['/login', '/signup'];
            final protectedRoutes = [
              '/chat',
              '/settings',
            ]; // Add other protected routes here

            bool shouldRedirect = false;
            if (user != null && authRoutes.contains(currentRouteName)) {
              // User is logged in but on an auth screen -> redirect to chat
              shouldRedirect = true;
            }
            if (user == null && protectedRoutes.contains(currentRouteName)) {
              // User is logged out but on a protected screen -> redirect to login
              shouldRedirect = true;
            }

            if (shouldRedirect && currentRouteName != targetRoute) {
              // Schedule navigation after the current build cycle
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // Check mount status and if route hasn't already changed
                if (mounted &&
                    ModalRoute.of(context)?.settings.name != targetRoute) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    targetRoute,
                    (route) => false,
                  );
                }
              });
              // Return a loading indicator while redirecting
              // Use the initial child briefly to avoid flicker if needed, or just loading.
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // No redirect needed, return the actual child widget for the current route
            // The null check is important as child can be null during transitions
            return child ??
                const PlaceholderSplashScreen(); // Fallback to splash/loading
          },
          // Show splash screen while loading auth state
          loading: () {
            log('Auth state: loading in builder');
            return const PlaceholderSplashScreen(); // TODO: Replace with your actual SplashScreen
          },
          // Show login screen or error screen on auth error
          error: (error, stackTrace) {
            log('Auth Error in builder: $error\n$stackTrace');
            // Consider a dedicated error screen
            return const LoginScreen(); // Default to login on error
          },
        );
      },
      // Set initial route - builder logic will handle redirection if needed
      initialRoute: '/', // Start at a root/splash route
      // Define the root route builder if using initialRoute '/'
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          // Decide initial screen within onGenerateRoute based on initial auth state
          // This avoids issues with builder running before initial route is fully determined
          return MaterialPageRoute(
            builder:
                (context) => authState.maybeWhen(
                  data:
                      (user) =>
                          user != null
                              ? const ChatScreen()
                              : const LoginScreen(),
                  orElse:
                      () =>
                          const PlaceholderSplashScreen(), // Loading or error initially
                ),
          );
        }
        // Let other routes be handled by the `routes` map
        return null;
      },
      // Remove the home property as builder/onGenerateRoute handles initial screen
      // home: ...
    );
  }
}
