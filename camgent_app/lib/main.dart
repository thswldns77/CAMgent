// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:device_info_plus/device_info_plus.dart';
//
// lib/main.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'chat_screen.dart';
import 'camera_screen.dart';
import 'camera_settings.dart';
import 'login.dart';
import 'app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RootApp());
}

class RootApp extends StatelessWidget {
  const RootApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CAMgent',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const PermissionGate(), // ✅ 권한 → 로그인 → 메인
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CAMgent',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const MainScreen(),
    );
  }
}

/// 권한 요청/점검 게이트
class PermissionGate extends StatefulWidget {
  const PermissionGate({Key? key}) : super(key: key);

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate> {
  bool _checking = true;     // 현재 권한 점검 중
  bool _requesting = false;  // 권한 요청 중
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAlreadyGranted();
  }

  /// 플랫폼/SDK에 맞는 권한 목록 구성
  Future<List<Permission>> _buildPerms() async {
    final perms = <Permission>[Permission.camera];

    if (Platform.isAndroid) {
      final sdk = (await DeviceInfoPlugin().androidInfo).version.sdkInt ?? 0;
      if (sdk < 30) {
        perms.add(Permission.storage); // Android 10 이하
      } else {
        // Android 11~: 기기/롬에 따라 필요할 수 있어 옵션
        perms.add(Permission.manageExternalStorage);
      }
    } else if (Platform.isIOS) {
      perms.addAll([Permission.photos, Permission.photosAddOnly]);
    }

    return perms;
  }

  /// 앱 시작 시: 이미 모두 허용돼 있으면 메인으로 바로 이동
  Future<void> _checkAlreadyGranted() async {
    final perms = await _buildPerms();
    final statuses = await Future.wait(perms.map((p) => p.status));
    final allGranted = statuses.every((s) => s.isGranted);

    if (!mounted) return;

    if (allGranted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
      });
    } else {
      setState(() => _checking = false);
    }
  }

  /// 버튼 눌렀을 때: 일괄 요청하고 통과하면 로그인으로 이동
  Future<void> _requestAndStart() async {
    setState(() {
      _requesting = true;
      _error = null;
    });

    try {
      final perms = await _buildPerms();
      final results = await perms.request();
      final allGranted = results.values.every((s) => s.isGranted);
      if (!allGranted) {
        throw Exception('필수 권한이 모두 허용되지 않았습니다.');
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking || _requesting) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('권한 설정')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              decoration: AppTheme.glass(radius: 16),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: const [
                  Icon(Icons.lock_open_rounded, color: Colors.white70),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '정확한 촬영을 위해 아래 권한이 필요합니다.\n'
                          '거부해도 앱은 실행되지만 일부 기능이 제한될 수 있어요.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _permTile(Icons.camera_alt_outlined, '카메라', '프리뷰/촬영'),
            if (Platform.isAndroid)
              _permTile(Icons.sd_storage_rounded, '저장소', '사진 저장 (기기/OS에 따라 요청)'),
            if (Platform.isIOS)
              _permTile(Icons.photo_outlined, '사진', '갤러리 저장/접근'),
            const Spacer(),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => openAppSettings(),
                    child: const Text('설정 열기'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _requestAndStart,
                    child: const Text('권한 확인 후 시작'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _permTile(IconData icon, String title, String desc) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.glass(),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const Spacer(),
          AppTheme.infoBadge('권장'),
        ],
      ),
    );
  }
}

/// 권한 통과 후 실제 앱 화면
class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  CameraSettings? _cameraSettings;
  int _cameraEpoch = 0;

  Future<bool> _onWillPop() async {
    // 카메라 탭이면 뒤로가기는 채팅 탭으로 전환
    if (_currentIndex == 1) {
      setState(() => _currentIndex = 0);
      return false;
    }

    // 채팅 탭이면 종료 확인 다이얼로그
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('앱을 종료할까요?'),
        content: const Text('종료하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('종료'),
          ),
        ],
      ),
    );

    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            ChatScreen(
              onSettingsReceived: (s) {
                setState(() {
                  _cameraSettings = s;
                  _cameraEpoch++;
                  _currentIndex = 1;
                });
              },
            ),
            CameraScreen(
              key: ValueKey(_cameraEpoch),
              isActive: _currentIndex == 1,
              cameraSettings: _cameraSettings,
              onBackToChat: () => setState(() => _currentIndex = 0),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) {
            setState(() {
              if (i == 1) _cameraEpoch++; // 카메라 탭 들어갈 때 재생성
              _currentIndex = i;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.smart_toy_outlined), label: '어시스턴트'),
            BottomNavigationBarItem(icon: Icon(Icons.camera), label: '카메라'),
          ],
        ),
      ),
    );
  }
}