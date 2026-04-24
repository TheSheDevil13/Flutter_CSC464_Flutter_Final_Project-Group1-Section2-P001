import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';
import 'providers/chat_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/history_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  // Required before any async work in main()
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait only (mobile app)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Style the Android status bar to match our dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Firebase before runApp
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const LinguaAIApp());
}

class LinguaAIApp extends StatelessWidget {
  const LinguaAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ChatProvider is available to every screen in the app
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        title: 'LinguaAI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        // Named routes make navigation clean and testable
        initialRoute: '/',
        routes: {
          '/':        (context) => const SplashScreen(),
          '/home':    (context) => const HomeScreen(),
          '/chat':    (context) => const ChatScreen(),
          '/history': (context) => const HistoryScreen(),
        },
      ),
    );
  }
}
