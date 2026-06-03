import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app/gyeote_app.dart';
import 'src/core/backend/backend_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final backendConfig = BackendConfig.fromEnvironment();
  if (backendConfig.hasSupabase) {
    await Supabase.initialize(
      url: backendConfig.supabaseUrl,
      anonKey: backendConfig.supabaseAnonKey,
    );
  }

  runApp(GyeoteApp(backendConfig: backendConfig));
}
