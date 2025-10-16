// lib/login.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_theme.dart';
import 'apiservice.dart';
import 'main.dart';

bool islogin = false;

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 배경 그라데이션 + 미니멀 레이아웃
    return Scaffold(
      body: Stack(
        children: [
          // 배경 그라데이션(약한 비네팅)
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.2),
                  radius: 1.2,
                  colors: [Color(0xFF0E1113), Color(0xFF0E1113)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const _ApertureLogo(),
                      const SizedBox(height: 28),
                      const Text(
                        'CAMgent',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '카메라 어시스턴트에 로그인하세요',
                        style: TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // Google 로그인
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: () => _handleGoogleLogin(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.white.withOpacity(0.2)),
                            backgroundColor: Colors.white.withOpacity(0.03),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.g_mobiledata_rounded, size: 28, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Google로 로그인', style: TextStyle(fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 게스트 모드
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () => _handleGuestMode(context),
                          icon: const Icon(Icons.person_outline),
                          label: const Text('게스트로 계속하기'),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Text(
                        '계속하면 이용약관 및 개인정보처리방침에 동의합니다.',
                        style: TextStyle(fontSize: 12, color: Colors.white54),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGoogleLogin(BuildContext context) async {
    // 계정 선택 시트 전에 초기화 보장
    await ApiService.ensureInitialized();

    // 로딩 다이얼로그
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          decoration: AppTheme.glass(radius: 16),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 12),
             // Text('Google 로그인 중…'),
            ],
          ),
        ),
      ),
    );

    try {
      await ApiService.signInAndGetIdToken();

      if (context.mounted) {
        Navigator.of(context).pop(); // 로딩 닫기
        islogin = true;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MyApp()),
        );
      }
    } on PlatformException catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // 로딩 닫기
        final code = (e.code).toLowerCase();
        if (code.contains('canceled')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('로그인을 취소했습니다.')),
          );
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 실패: ${e.code} ${e.message ?? ''}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // 로딩 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 실패: $e')),
        );
      }
    }
  }

  void _handleGuestMode(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MyApp()),
    );
  }
}

// 카메라 조리개 느낌의 심볼
// 로그인 화면의 _ApertureLogo 교체본
class _ApertureLogo extends StatelessWidget {
  const _ApertureLogo();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.primary;
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [c.withOpacity(0.18), Colors.transparent],
        ),
        border: Border.all(color: c.withOpacity(0.65), width: 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 간단한 조리개 블레이드 라인
          Transform.rotate(
            angle: 0.2,
            child: Container(width: 64, height: 2, color: c.withOpacity(0.7)),
          ),
          Transform.rotate(
            angle: 2.4,
            child: Container(width: 64, height: 2, color: c.withOpacity(0.7)),
          ),
          Transform.rotate(
            angle: 4.0,
            child: Container(width: 64, height: 2, color: c.withOpacity(0.7)),
          ),
          // 머티리얼 대체 아이콘
          const Icon(Icons.camera_alt_rounded, size: 54, color: Colors.white),
        ],
      ),
    );
  }
}

