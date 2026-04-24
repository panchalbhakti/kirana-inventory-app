import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart' as ap;
import '../auth/phone_screen.dart';
import '../home/home_screen.dart';

/// Sits at the root. Listens to Firebase auth state and routes accordingly.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<ap.AuthProvider>();

    return StreamBuilder<User?>(
      stream: authProvider.authStateChanges,
      builder: (context, snapshot) {
        // While Firebase is initialising
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashLoader();
        }

        final user = snapshot.data;
        if (user != null) {
          // Logged in — go to main app
          return HomeScreen();
        } else {
          // Not logged in — show phone auth
          return const PhoneScreen();
        }
      },
    );
  }
}

class _SplashLoader extends StatelessWidget {
  const _SplashLoader();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0C0C12),
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E68A)),
          strokeWidth: 2,
        ),
      ),
    );
  }
}