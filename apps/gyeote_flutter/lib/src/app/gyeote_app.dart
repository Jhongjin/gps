import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/backend/backend_config.dart';
import '../core/backend/supabase_backend.dart';
import '../core/location/location_bridge.dart';
import '../features/auth/auth_gate.dart';
import '../features/circle/circle_screen.dart';
import '../features/history/history_screen.dart';
import '../features/map/map_screen.dart';
import '../features/privacy/privacy_screen.dart';
import '../theme/gyeote_theme.dart';

class GyeoteApp extends StatefulWidget {
  const GyeoteApp({
    super.key,
    required this.backendConfig,
  });

  final BackendConfig backendConfig;

  @override
  State<GyeoteApp> createState() => _GyeoteAppState();
}

class _GyeoteAppState extends State<GyeoteApp> {
  final _locationBridge = LocationBridge();
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final backend = widget.backendConfig.hasSupabase
        ? SupabaseBackend(
            client: Supabase.instance.client,
            config: widget.backendConfig,
          )
        : null;

    final screens = [
      MapScreen(
        circleRepository: backend?.circles,
        deviceRepository: backend?.devices,
        companionRepository: backend?.companions,
        checkInRepository: backend?.checkIns,
        placeAlertRepository: backend?.placeAlerts,
        backendConfig: widget.backendConfig,
        locationBridge: _locationBridge,
        onOpenCircle: () => setState(() => _tabIndex = 1),
      ),
      CircleScreen(
        circleRepository: backend?.circles,
        invitationRepository: backend?.invitations,
        placeAlertRepository: backend?.placeAlerts,
        checkInRepository: backend?.checkIns,
        locationBridge: _locationBridge,
      ),
      HistoryScreen(
        circleRepository: backend?.circles,
        checkInRepository: backend?.checkIns,
      ),
      PrivacyScreen(
        circleRepository: backend?.circles,
        privacyRepository: backend?.privacy,
        locationBridge: _locationBridge,
        onSignOut: widget.backendConfig.hasSupabase
            ? () => Supabase.instance.client.auth.signOut()
            : null,
      ),
    ];

    final shell = Scaffold(
      body: SafeArea(child: screens[_tabIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) => setState(() => _tabIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: '지도',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group),
            label: '서클',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            selectedIcon: Icon(Icons.schedule),
            label: '기록',
          ),
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield),
            label: '안심',
          ),
        ],
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '곁에',
      theme: buildGyeoteTheme(),
      home: widget.backendConfig.hasSupabase ? AuthGate(child: shell) : shell,
    );
  }
}
