import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const FeedbackReviewApp());
}

class FeedbackReviewApp extends StatelessWidget {
  const FeedbackReviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Placeholder provider until we create our services in Phase 3
        Provider(create: (_) => 'Placeholder'),
      ],
      child: MaterialApp(
        title: 'Feedback & Review',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}
