// lib/camera_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'app_theme.dart';
import 'camera_settings.dart';

class CameraScreen extends StatefulWidget {
  final CameraSettings? cameraSettings;
  final VoidCallback? onBackToChat;
  final bool isActive;

  const CameraScreen({
    Key? key,
    required this.isActive,
    this.cameraSettings,
    this.onBackToChat,
  }) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  MethodChannel? _channel;
  bool _isTakingPicture = false;
  double _zoom = 1.0;
  double _exposure = 0.0;

  // UI 한계값 (네이티브에서 실제 범위 받아 조정하려면 메서드 추가)
  final double _minZoom = 1.0, _maxZoom = 4.0;
  final double _minExposure = -2.0, _maxExposure = 2.0;

  @override
  void didUpdateWidget(covariant CameraScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 설정 변경 즉시 반영
    if (_channel != null && widget.cameraSettings != null) {
      final map = widget.cameraSettings!.toJson();
      debugPrint('[Flutter→Native] applySettings (update): $map');
      _channel!.invokeMethod('applySettings', map);
    }

    // 활성/비활성 전환
    if (oldWidget.isActive && !widget.isActive) {
      _pause();
    } else if (!oldWidget.isActive && widget.isActive) {
      _resume();
    }
  }

  Future<void> _pause() async {
    try {
      await _channel?.invokeMethod('pauseCamera');
    } catch (e) {
      debugPrint('pauseCamera error: $e');
    }
  }

  Future<void> _resume() async {
    try {
      await _channel?.invokeMethod('resumeCamera');
      if (widget.cameraSettings != null) {
        final map = widget.cameraSettings!.toJson();
        debugPrint('[Flutter→Native] applySettings (resume): $map');
        await _channel?.invokeMethod('applySettings', map);
      }
    } catch (e) {
      debugPrint('resumeCamera error: $e');
    }
  }

  @override
  void dispose() {
    _channel?.invokeMethod('pauseCamera');
    super.dispose();
  }

  void _onPlatformViewCreated(int id) {
    _channel = MethodChannel('native_camera_channel_$id');

    _channel!.setMethodCallHandler((call) async {
      if (call.method == 'previewReady') {
        if (mounted) setState(() {}); // 컨트롤 활성화
        if (widget.cameraSettings != null) {
          final map = widget.cameraSettings!.toJson();
          debugPrint('[Flutter→Native] applySettings (previewReady): $map');
          await _channel!.invokeMethod('applySettings', map);
        }
      }
    });

    // 예비 안전망: 약간 지연 후 설정 재적용
    Future.delayed(const Duration(milliseconds: 300), () async {
      if (!mounted || _channel == null) return;
      if (widget.cameraSettings != null) {
        await _channel!.invokeMethod('applySettings', widget.cameraSettings!.toJson());
      }
      if (mounted) setState(() {}); // controlsEnabled 갱신
    });

    // 현재 isActive 상태에 맞춰 제어
    if (widget.isActive) {
      _resume();
    } else {
      _pause();
    }
  }

  Future<void> _setZoom(double v) async {
    setState(() => _zoom = v);
    try {
      await _channel?.invokeMethod('setZoom', {'zoom': v});
    } catch (e) {
      debugPrint('setZoom error: $e');
    }
  }

  Future<void> _setExposure(double v) async {
    setState(() => _exposure = v);
    try {
      await _channel?.invokeMethod('setExposureCompensation', {'exposure': v});
    } catch (e) {
      debugPrint('setExposure error: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_channel == null || _isTakingPicture || !widget.isActive) return;
    setState(() => _isTakingPicture = true);
    try {
      final String? uriString = await _channel!.invokeMethod<String>('takePicture');
      if (uriString == null) throw '네이티브가 경로를 반환하지 않았습니다.';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('갤러리에 저장 완료\n$uriString')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('촬영 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _isTakingPicture = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controlsEnabled = _channel != null && widget.isActive;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(''),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBackToChat,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: AppTheme.infoBadge(controlsEnabled ? 'LIVE' : 'PAUSED'),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Native camera preview
          AndroidView(
            viewType: 'native_camera_view',
            onPlatformViewCreated: _onPlatformViewCreated,
            hitTestBehavior: PlatformViewHitTestBehavior.transparent,
          ),

          // 상단 가독성용 그라데이션
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment(0, .28),
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
              ),
            ),
          ),

          // 좌측 상단 설정 오버레이
          if (widget.cameraSettings != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 12,
              child: Container(
                decoration: AppTheme.glass(),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: DefaultTextStyle(
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CAMERA SETTINGS',
                          style: TextStyle(
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: 6),
                      Text('ISO   : ${widget.cameraSettings!.sensorSensitivity}'),
                      Text('Shut. : ${widget.cameraSettings!.sensorExposureTime}s'),
                      Text('AE    : ${widget.cameraSettings!.controlAeExposureCompensation}'),
                      Text('Flash : ${widget.cameraSettings!.flashMode}'),
                    ],
                  ),
                ),
              ),
            ),

          // 우측 레일 (Zoom / Exposure)
          Positioned(
            right: 8,
            top: 100,
            bottom: 100,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _RailSlider(
                  label: 'Zoom ${_zoom.toStringAsFixed(1)}x',
                  min: _minZoom,
                  max: _maxZoom,
                  value: _zoom,
                  onChanged: controlsEnabled ? _setZoom : null,
                ),
                _RailSlider(
                  label: 'Exp ${_exposure.toStringAsFixed(1)}',
                  min: _minExposure,
                  max: _maxExposure,
                  value: _exposure,
                  onChanged: controlsEnabled ? _setExposure : null,
                ),
              ],
            ),
          ),

          // 하단 셔터
          Positioned(
            bottom: 28,
            left: 0,
            right: 0,
            child: Center(
              child: _ShutterButton(
                enabled: controlsEnabled && !_isTakingPicture,
                busy: _isTakingPicture,
                onTap: _takePicture,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== 보조 위젯 =====

class _RailSlider extends StatelessWidget {
  final String label;
  final double min, max, value;
  final ValueChanged<double>? onChanged;

  const _RailSlider({
    required this.label,
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.glass(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        children: [
          RotatedBox(
            quarterTurns: 3,
            child: SizedBox(
              width: 200,
              child: Slider(
                min: min,
                max: max,
                value: value,
                divisions: 40,
                onChanged: onChanged,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  final bool enabled;
  final bool busy;
  final VoidCallback onTap;

  const _ShutterButton({
    required this.enabled,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ringColor = enabled ? Theme.of(context).colorScheme.primary : Colors.white24;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 82,
        height: 82,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ringColor, width: 4),
          boxShadow: [
            if (enabled) BoxShadow(color: ringColor.withOpacity(0.3), blurRadius: 18),
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: busy
                ? const SizedBox(
              key: ValueKey('busy'),
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            )
                : Container(
              key: const ValueKey('idle'),
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: enabled ? Colors.white : Colors.white12,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

