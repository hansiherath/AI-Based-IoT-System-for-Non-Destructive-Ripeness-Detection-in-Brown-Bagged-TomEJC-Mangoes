import 'package:flutter/material.dart';

import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/health_recommendation_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/customer_activity_screen.dart';
import 'screens/monitor_system_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QUALO',
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/admin-login': (context) => const AdminLoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/health': (context) {
      final recommendation =
          ModalRoute.of(context)!.settings.arguments as String;

      return HealthRecommendationScreen(recommendation: recommendation);
    },

        //'/health': (context) => const HealthRecommendationScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/customer-activity': (context) => const CustomerActivityScreen(),
        '/monitor-system-screen': (context) => const MonitorSystemScreen(),
      },
    );
  }
}
