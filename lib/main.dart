import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'auth/auth_service.dart';
import 'data/firestore_store_repository.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/sign_in_screen.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const GameVaultApp());
}

class GameVaultApp extends StatelessWidget {
  /// Overrides the auth gate, for tests.
  final Widget? home;

  const GameVaultApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GameVault',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          surface: AppColors.background,
        ),
      ),
      home: home ?? const AuthGate(),
    );
  }
}

/// Shows the store to signed-in accounts and the sign-in screen to everyone
/// else. The web QR panel signs in anonymously while it waits, and that
/// session still counts as signed out.
class AuthGate extends StatelessWidget {
  final AuthService auth;

  const AuthGate({super.key, this.auth = const FirebaseAuthService()});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          );
        }

        final User? user = snapshot.data;
        if (user == null || user.isAnonymous) {
          return SignInScreen(auth: auth);
        }

        // Keyed by account so a different user gets fresh store state.
        return HomeScreen(
          key: ValueKey(user.uid),
          repository: FirestoreStoreRepository(),
        );
      },
    );
  }
}
