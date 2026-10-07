import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart';
import '../auth/verify_email_screen.dart';
import 'pro_league_home.dart';

class ProLeagueAuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Color(0xFF1B1B2F),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF00C9A7)),
                  SizedBox(height: 16),
                  Text(
                    "Loading...",
                    style: TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return LoginScreen();
        }

        if (!user.emailVerified) {
          return VerifyEmailScreen();
        }

        return ProLeagueHome();
      },
    );
  }
}