import 'package:flutter/material.dart';              // [IMPORT] Flutter UI framework
import 'package:flutter/foundation.dart' show kIsWeb; // [IMPORT] Flutter foundation for platform detection
import 'package:provider/provider.dart';              // [IMPORT] State management with Provider
import 'package:firebase_core/firebase_core.dart';    // [IMPORT] Firebase core initialization
import 'firebase_options.dart';                       // [IMPORT] Firebase platform-specific options

import 'theme/app_theme.dart';                        // [IMPORT] App theme configuration
import 'providers/post_provider.dart';               // [IMPORT] Post data state provider
import 'providers/map_provider.dart';                // [IMPORT] Map state provider
// import 'providers/social_provider.dart';             // [IMPORT] Social features provider - commented out
import 'providers/user_provider.dart';               // [IMPORT] User authentication provider
import 'screens/simple_login_screen.dart';          // [IMPORT] Login screen widget
import 'screens/home_screen.dart';                   // [IMPORT] Home screen widget (main dashboard)

/// [FUNCTION] main
/// [PARAMS] None
/// [RETURNS] void
/// [PURPOSE] Application entry point - initializes Flutter and Firebase, then runs app
/// [STEP 1] Ensure Flutter widgets are initialized
/// [STEP 2] Initialize Firebase with platform-specific options
/// [STEP 3] Run the SocialMemoriesApp widget
void main() async {
  WidgetsFlutterBinding.ensureInitialized();          // [STEP 1] Initialize Flutter binding
  
  // Configure Android embedding for v2
  if (!kIsWeb) {
    // Android-specific configuration
    // This fixes the "deleted Android v1 embedding" error
  }
  
  await Firebase.initializeApp(                       // [STEP 2] Initialize Firebase
    options: DefaultFirebaseOptions.currentPlatform,  // [CONFIG] Use platform config
  );

  runApp(const SocialMemoriesApp());                  // [STEP 3] Launch app
}

/// [CLASS] SocialMemoriesApp
/// [PURPOSE] Root widget of the application - configures providers and theme
/// [FUNCTIONALITY] Sets up MultiProvider with all app providers, configures MaterialApp
class SocialMemoriesApp extends StatelessWidget {
  const SocialMemoriesApp({super.key});               // [CONSTRUCTOR] Creates app widget

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // [PROVIDERS] All app state providers available to child widgets
      providers: [
        ChangeNotifierProvider(create: (_) => PostProvider()),   // [PROVIDER] Post data state
        ChangeNotifierProvider(create: (_) => MapProvider()),    // [PROVIDER] Map state
        // ChangeNotifierProvider(create: (_) => SocialProvider()), // [PROVIDER] Social features state - commented out
        ChangeNotifierProvider(create: (_) => UserProvider()),   // [PROVIDER] User auth state
      ],
      child: MaterialApp(
        title: 'Social Memories',                      // [APP] App title
        debugShowCheckedModeBanner: false,            // [CONFIG] Hide debug banner
        theme: AppTheme.lightTheme,                   // [THEME] Light theme configuration
        home: const AuthWrapper(),                    // [HOME] Auth wrapper decides initial screen
      ),
    );
  }
}

/// [CLASS] AuthWrapper
/// [PURPOSE] StatelessWidget that decides which screen to show based on auth state
/// [FUNCTIONALITY] Shows loading spinner while checking auth, then HomeScreen or LoginScreen
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});                   // [CONSTRUCTOR] Creates auth wrapper

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(                   // [WIDGET] Listen to UserProvider changes
      builder: (context, userProvider, child) {
        // [CHECK] Still loading auth state - show spinner
        if (userProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(       // [UI] Loading spinner
                color: Color(0xFF66BB6A),            // [STYLE] Green spinner
              ),
            ),
          );
        }

        // [CHECK] User is logged in - show home screen
        if (userProvider.isLoggedIn) {
          return const HomeScreen();                  // [SCREEN] Main app home
        } else {
          return const SimpleLoginScreen();           // [SCREEN] Login screen
        }
      },
    );
  }
}