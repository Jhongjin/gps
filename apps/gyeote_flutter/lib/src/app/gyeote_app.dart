import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../l10n/app_localizations.dart';

import '../core/backend/backend_config.dart';
import '../core/backend/supabase_backend.dart';
import '../core/location/location_bridge.dart';
import '../features/auth/auth_gate.dart';
import '../features/circle/circle_screen.dart';
import '../features/history/history_screen.dart';
import '../features/map/map_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
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

  /// null 이면 아직 확인 중이다. 확인 전에 셸을 띄우면 온보딩이 한 프레임
  /// 늦게 덮여 깜빡인다.
  bool? _hasSeenOnboarding;

  @override
  void initState() {
    super.initState();
    const OnboardingGate().hasSeen().then((seen) {
      if (mounted) setState(() => _hasSeenOnboarding = seen);
    });
  }

  Future<void> _completeOnboarding({required bool wantsLocation}) async {
    await const OnboardingGate().markSeen();
    if (wantsLocation) {
      // 방금 이유를 읽은 직후가 물어보기 가장 좋은 때다.
      await _locationBridge.requestWhenInUse();
    }
    if (mounted) setState(() => _hasSeenOnboarding = true);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppL10n.of(context).appTitle,
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      theme: buildGyeoteTheme(),
      darkTheme: buildGyeoteDarkTheme(),
      themeMode: ThemeMode.system,
      // 셸은 MaterialApp 아래에서 만들어야 AppL10n.of(context) 가 닿는다.
      home: Builder(builder: _buildShell),
    );
  }

  Widget _buildShell(BuildContext context) {
    final seen = _hasSeenOnboarding;
    if (seen == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    if (!seen) {
      return OnboardingScreen(onDone: _completeOnboarding);
    }

    final l10n = AppL10n.of(context);
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
        meetupRepository: backend?.meetups,
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
        backendConfig: widget.backendConfig,
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
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            selectedIcon: const Icon(Icons.map),
            label: l10n.navMap,
          ),
          NavigationDestination(
            icon: const Icon(Icons.group_outlined),
            selectedIcon: const Icon(Icons.group),
            label: l10n.navCircle,
          ),
          NavigationDestination(
            icon: const Icon(Icons.schedule_outlined),
            selectedIcon: const Icon(Icons.schedule),
            label: l10n.navHistory,
          ),
          NavigationDestination(
            icon: const Icon(Icons.shield_outlined),
            selectedIcon: const Icon(Icons.shield),
            label: l10n.navPrivacy,
          ),
        ],
      ),
    );

    return widget.backendConfig.hasSupabase ? AuthGate(child: shell) : shell;
  }
}
