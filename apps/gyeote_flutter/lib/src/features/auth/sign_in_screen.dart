import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/gyeote_theme.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSignUp = false;
  bool _isLoading = false;
  String? _message;
  bool _isError = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
      _isError = false;
    });

    final client = Supabase.instance.client;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final displayName = _nameController.text.trim();

    try {
      if (_isSignUp) {
        final response = await client.auth.signUp(
          email: email,
          password: password,
          data: displayName.isEmpty
              ? null
              : <String, dynamic>{'display_name': displayName},
        );

        if (response.session == null && mounted) {
          setState(() {
            _message = '가입 확인 메일을 보냈습니다. 메일 확인 후 다시 로그인해 주세요.';
          });
        }
      } else {
        await client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      }
    } on AuthException catch (error) {
      if (mounted) {
        setState(() {
          _isError = true;
          _message = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isError = true;
          _message = '처리 중 문제가 생겼습니다. 잠시 후 다시 시도해 주세요.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionLabel = _isSignUp ? '가입하고 시작' : '로그인';

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 18),
                    const _BrandHeader(),
                    const SizedBox(height: 24),
                    Form(
                      key: _formKey,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: GyeoteColors.border),
                          borderRadius: BorderRadius.circular(8),
                          color: GyeoteColors.surface,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment(value: false, label: Text('로그인')),
                                ButtonSegment(value: true, label: Text('가입')),
                              ],
                              selected: {_isSignUp},
                              onSelectionChanged: (value) {
                                setState(() {
                                  _isSignUp = value.first;
                                  _message = null;
                                  _isError = false;
                                });
                              },
                            ),
                            const SizedBox(height: 14),
                            if (_isSignUp) ...[
                              TextFormField(
                                controller: _nameController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: '이름 또는 별명',
                                  prefixIcon: Icon(Icons.badge_outlined),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              decoration: const InputDecoration(
                                labelText: '이메일',
                                prefixIcon: Icon(Icons.mail_outline),
                              ),
                              validator: (value) {
                                final email = value?.trim() ?? '';
                                if (email.isEmpty || !email.contains('@')) {
                                  return '이메일을 입력해 주세요.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              decoration: const InputDecoration(
                                labelText: '비밀번호',
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                              onFieldSubmitted: (_) {
                                if (!_isLoading) {
                                  _submit();
                                }
                              },
                              validator: (value) {
                                if ((value ?? '').length < 6) {
                                  return '6자 이상 입력해 주세요.';
                                }
                                return null;
                              },
                            ),
                            if (_message != null) ...[
                              const SizedBox(height: 12),
                              _InlineMessage(
                                message: _message!,
                                isError: _isError,
                              ),
                            ],
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _isLoading ? null : _submit,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Icon(_isSignUp ? Icons.person_add_alt_1_outlined : Icons.login_outlined),
                              label: Text(actionLabel),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const _TrustStrip(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('곁에', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900)),
        SizedBox(height: 8),
        Text(
          '가까운 사람끼리만, 필요한 만큼 위치를 나눠요.',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 6),
        Text(
          '초대받은 서클과 상호 동의한 동행 모드에서만 위치가 공유됩니다.',
          style: TextStyle(color: GyeoteColors.muted),
        ),
        SizedBox(height: 4),
        Text(
          '정밀 위치는 광고에 사용하지 않으며, 언제든 공유를 멈출 수 있어요.',
          style: TextStyle(color: GyeoteColors.muted),
        ),
      ],
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? GyeoteColors.danger : GyeoteColors.primary;
    final background = isError ? GyeoteColors.dangerSoft : GyeoteColors.primarySoft;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _TrustPill(icon: Icons.visibility_outlined, label: '조회 기록'),
        _TrustPill(icon: Icons.place_outlined, label: '동의 기반 공유'),
        _TrustPill(icon: Icons.ads_click_outlined, label: '정밀 위치 광고 차단'),
      ],
    );
  }
}

class _TrustPill extends StatelessWidget {
  const _TrustPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: GyeoteColors.border),
        borderRadius: BorderRadius.circular(8),
        color: GyeoteColors.surface,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: GyeoteColors.primary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: GyeoteColors.primary, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
