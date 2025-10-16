/// 카메라 세팅 모델 (안전 캐스팅 적용)
class CameraSettings {
  final int? sensorSensitivity;               // ISO (int)
  final double? sensorExposureTime;           // 초 단위 (double)
  final String? colorCorrectionMode;
  final List<double>? colorCorrectionGains;   // [r, g_even, g_odd, b] → double
  final double? lensFocusDistance;            // m^-1 (double)
  final int? controlAeExposureCompensation;   // EV index (int)
  final String? controlSceneMode;
  final bool? controlAwbLock;
  final bool? controlAeLock;
  final String? flashMode;
  final String? controlAfRegions;
  final String? controlAeRegions;
  final String? controlEffectMode;
  final String? noiseReductionMode;
  final String? tonemapMode;
  final bool? rawOutput;
  final int? jpegQuality;                     // 0~100
  final String? controlAeAntibandingMode;
  final List<int>? controlAeTargetFpsRange;   // [min, max]

  CameraSettings({
    this.sensorSensitivity,
    this.sensorExposureTime,
    this.colorCorrectionMode,
    this.colorCorrectionGains,
    this.lensFocusDistance,
    this.controlAeExposureCompensation,
    this.controlSceneMode,
    this.controlAwbLock,
    this.controlAeLock,
    this.flashMode,
    this.controlAfRegions,
    this.controlAeRegions,
    this.controlEffectMode,
    this.noiseReductionMode,
    this.tonemapMode,
    this.rawOutput,
    this.jpegQuality,
    this.controlAeAntibandingMode,
    this.controlAeTargetFpsRange,
  });

  // -------- 안전한 헬퍼들 --------
  static num? _num(dynamic v) => v is num ? v : (v is String ? num.tryParse(v) : null);
  static double? _double(dynamic v) => _num(v)?.toDouble();
  static int? _int(dynamic v) => _num(v)?.toInt();
  static String? _str(dynamic v) => v is String ? v : v?.toString();

  static List<double>? _doubleList(dynamic v) {
    if (v is List) {
      final out = <double>[];
      for (final e in v) {
        final d = _double(e);
        if (d == null) return null;
        out.add(d);
      }
      return out;
    }
    return null;
  }

  static List<int>? _intList(dynamic v) {
    if (v is List) {
      final out = <int>[];
      for (final e in v) {
        final i = _int(e);
        if (i == null) return null;
        out.add(i);
      }
      return out;
    }
    return null;
  }

  factory CameraSettings.fromJson(Map<String, dynamic> json) {
    // 노출 시간: ns 또는 s 로 들어올 수 있음 → s(초)로 통일
    double? exposureSeconds;
    if (json['SENSOR_EXPOSURE_TIME_NS'] != null) {
      final ns = _double(json['SENSOR_EXPOSURE_TIME_NS']);
      if (ns != null) exposureSeconds = ns / 1e9;
    } else if (json['SENSOR_EXPOSURE_TIME'] != null) {
      final v = _double(json['SENSOR_EXPOSURE_TIME']);
      if (v != null) {
        exposureSeconds = (v > 1e6) ? v / 1e9 : v; // 1e6 넘으면 ns로 간주
      }
    }

    return CameraSettings(
      sensorSensitivity: _int(json['SENSOR_SENSITIVITY']),
      sensorExposureTime: exposureSeconds,
      colorCorrectionMode: _str(json['COLOR_CORRECTION_MODE']),
      colorCorrectionGains: _doubleList(json['COLOR_CORRECTION_GAINS']),
      lensFocusDistance: _double(json['LENS_FOCUS_DISTANCE']),
      controlAeExposureCompensation: _int(json['CONTROL_AE_EXPOSURE_COMPENSATION']),
      controlSceneMode: _str(json['CONTROL_SCENE_MODE']),
      controlAwbLock: json['CONTROL_AWB_LOCK'] as bool?,
      controlAeLock: json['CONTROL_AE_LOCK'] as bool?,
      flashMode: _str(json['FLASH_MODE']),
      controlAfRegions: _str(json['CONTROL_AF_REGIONS']),
      controlAeRegions: _str(json['CONTROL_AE_REGIONS']),
      controlEffectMode: _str(json['CONTROL_EFFECT_MODE']),
      noiseReductionMode: _str(json['NOISE_REDUCTION_MODE']),
      tonemapMode: _str(json['TONEMAP_MODE']),
      rawOutput: json['RAW_OUTPUT'] as bool?,
      jpegQuality: _int(json['JPEG_QUALITY']),
      controlAeAntibandingMode: _str(json['CONTROL_AE_ANTIBANDING_MODE']),
      controlAeTargetFpsRange: _intList(json['CONTROL_AE_TARGET_FPS_RANGE']),
    );
  }

  /// 네이티브(Camera2)로 보낼 Map - 키 이름은 자바 측과 일치
  Map<String, dynamic> toJson() {
    int? exposureNs;
    if (sensorExposureTime != null) {
      final v = sensorExposureTime!;
      exposureNs = (v > 1e6 ? v.round() : (v * 1e9).round()); // s→ns
    }

    final map = <String, dynamic>{
      if (sensorSensitivity != null) 'SENSOR_SENSITIVITY': sensorSensitivity,
      if (exposureNs != null) 'SENSOR_EXPOSURE_TIME_NS': exposureNs, // long(ns)
      if (jpegQuality != null) 'JPEG_QUALITY': jpegQuality,
      if (flashMode != null) 'FLASH_MODE': flashMode!.toUpperCase(),
      if (controlAeExposureCompensation != null)
        'CONTROL_AE_EXPOSURE_COMPENSATION': controlAeExposureCompensation, // int
      if (controlSceneMode != null) 'CONTROL_SCENE_MODE': controlSceneMode!.toUpperCase(),
      if (controlAwbLock != null) 'CONTROL_AWB_LOCK': controlAwbLock,
      if (controlAeLock != null) 'CONTROL_AE_LOCK': controlAeLock,
      if (colorCorrectionMode != null) 'COLOR_CORRECTION_MODE': colorCorrectionMode!.toUpperCase(),
      if (colorCorrectionGains != null) 'COLOR_CORRECTION_GAINS': colorCorrectionGains,
      if (lensFocusDistance != null) 'LENS_FOCUS_DISTANCE': lensFocusDistance, // double
      if (controlEffectMode != null) 'CONTROL_EFFECT_MODE': controlEffectMode!.toUpperCase(),
      if (noiseReductionMode != null) 'NOISE_REDUCTION_MODE': noiseReductionMode!.toUpperCase(),
      if (tonemapMode != null) 'TONEMAP_MODE': tonemapMode!.toUpperCase(),
      if (controlAeAntibandingMode != null)
        'CONTROL_AE_ANTIBANDING_MODE': controlAeAntibandingMode!.toUpperCase(),
      if (controlAeTargetFpsRange != null) 'CONTROL_AE_TARGET_FPS_RANGE': controlAeTargetFpsRange, // [int,int]
    };

    // null 제거
    map.removeWhere((k, v) => v == null);
    return map;
  }

  /// (선택) 서버 직렬화가 따로 필요하면 toServerJson 따로 분리
  Map<String, dynamic> toServerJson() {
    return {
      'sensorSensitivity': sensorSensitivity,
      'sensorExposureTime': sensorExposureTime, // 서버는 s 단위로 받는다고 가정
      // ...필요 필드만
    }..removeWhere((k, v) => v == null);
  }
}
