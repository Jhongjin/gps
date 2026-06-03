import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'sign_in_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;

    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? client.auth.currentSession;

        if (session != null) {
          return child;
        }

        return const SignInScreen();
      },
    );
  }
}
