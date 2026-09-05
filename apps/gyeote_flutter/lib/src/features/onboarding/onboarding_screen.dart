import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../l10n/app_localizations.dart';
import '../../theme/gyeote_theme.dart';
import 'gyeotpin.dart';

/// 첫 실행에서 한 번 보여 준다.
///
/// 목적은 기능 소개가 아니라 **위치 권한을 받기 전에 이유를 먼저 말하는 것**이다.
/// 백그라운드 위치 승인률이 이 제품의 리텐션을 좌우하는데, 아무 설명 없이 OS
/// 대화상자를 띄우면 대부분 거절당하고 되돌리기 어렵다.
///
/// 건너뛸 수 있어야 한다. 읽기를 강요하면 첫인상이 나빠지고, 어차피 권한은
/// 필요한 순간에 다시 물어볼 수 있다.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final Future<void> Function({required bool wantsLocation}) onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pageCount = 3;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish({required bool wantsLocation}) =>
      widget.onDone(wantsLocation: wantsLocation);

  void _next() {
    if (_page >= _pageCount - 1) {
      _finish(wantsLocation: true);
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);

    final pages = <(String, String)>[
      (l10n.onboardWelcomeTitle, l10n.onboardWelcomeBody),
      (l10n.onboardConsentTitle, l10n.onboardConsentBody),
      (l10n.onboardPermissionTitle, l10n.onboardPermissionBody),
    ];

    return Scaffold(
      backgroundColor: palette.canvas,
      body: SafeArea(
        // 태블릿·데스크톱에서 글줄이 화면 폭만큼 늘어나면 읽을 수 없다.
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              children: [
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: TextButton(
                      // 건너뛰어도 권한은 나중에 필요한 순간 다시 묻는다.
                      onPressed: () => _finish(wantsLocation: false),
                      child: Text(l10n.onboardSkip),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: pages.length,
                    onPageChanged: (index) => setState(() => _page = index),
                    itemBuilder: (context, index) {
                      final (title, body) = pages[index];
                      return _OnboardingPage(title: title, body: body);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: Column(
                    children: [
                      Text(
                        l10n.onboardStepOf(_page + 1, _pageCount),
                        style: TextStyle(fontSize: 12, color: palette.muted),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _next,
                          child: Text(
                            _page >= _pageCount - 1
                                ? l10n.onboardStart
                                : l10n.onboardNext,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    // 세로로 흐르게 둔다. 고정 높이를 주면 큰 글자에서 잘린다.
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: Gyeotpin(size: 108)),
          const SizedBox(height: 32),
          Text(
            title,
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: TextStyle(
              fontSize: 15,
              height: 1.55,
              color: palette.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// 온보딩을 봤는지 기억한다.
class OnboardingGate {
  const OnboardingGate();

  static const _key = 'gyeote.onboarding.seen.v1';

  Future<bool> hasSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
