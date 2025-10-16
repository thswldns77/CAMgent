import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'camera_settings.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ApiResponse {
  final String text;
  final String? url;           // nullable로 변경
  final String? b64;           // nullable로 변경
  final CameraSettings? cameraSettings; // nullable로 변경

  ApiResponse({
    required this.text,
    this.url,
    this.b64,
    this.cameraSettings,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      text: json['text'] as String? ?? '',
      url: json['youtubeUrl'] as String?,
      b64: json['image'] as String?,
      cameraSettings: json['cameraSettings'] != null
          ? CameraSettings.fromJson(json['cameraSettings'] as Map<String, dynamic>)
          : null,
    );
  }
}

// ApiService 클래스 개선
class ApiService {
  static String idToken = '' ;
  static const String apiUrl = 'http://ip주소:포트/agent-conversation';
  static const String apiUrl2 = 'http://ip주소:포트/history';


  static const String serverClientId =
  '';

  static bool _initialized = false;

  /// 플러그인 초기화 (앱 시작 시 1회)
  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      clientId: null,
      serverClientId: serverClientId, // 서버 토큰 교환·검증을 쓸 거면 권장
      // hostedDomain: 'yourdomain.com', // 필요시 G Suite 제한
      // nonce: 'optional-nonce',        // 필요시 nonce
    );
    // 선택: 가벼운 자동 인증 시도
    //GoogleSignIn.instance.attemptLightweightAuthentication();
    _initialized = true;
  }

  /// v7: authenticate()로 로그인 UX를 띄우고
  static Future<void> signInAndGetIdToken() async {
    await ensureInitialized();

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw PlatformException(
        code: 'unsupported',
        message: '현재 플랫폼에서 GoogleSignIn.authenticate()를 지원하지 않습니다.',
      );
    }

    // 혹시 이전 세션 꼬임 방지(선택)
    try { await GoogleSignIn.instance.disconnect(); } catch (_) {}
    try { await GoogleSignIn.instance.signOut(); } catch (_) {}


    print("333");
    // 로그인 시트 표시 (사용자 취소 시 예외가 아닌 내부적으로 종료될 수 있음)
    final user = await GoogleSignIn.instance.authenticate();
    print("4444");
    // 취소/닫힘 등으로 user가 null이 될 수 있는 구현들도 있어 안전하게 체크
    if (user == null) {
      throw PlatformException(code: 'canceled', message: '사용자가 로그인을 취소했습니다.');
    }

    final auth = await user.authentication;
    idToken = auth.idToken!;
    print("token 값 = $idToken\n");
    if (idToken == null || idToken.isEmpty) {
      // 대부분 serverClientId(웹 클라 ID) 누락/오타에서 발생
      throw PlatformException(
        code: 'no_id_token',
        message: 'ID 토큰을 받지 못했습니다. serverClientId(웹 클라이언트 ID) 설정을 확인하세요.',
      );
    }
  }
  static Future<void> signOut() async => GoogleSignIn.instance.signOut();
  static Future<void> disconnect() async => GoogleSignIn.instance.disconnect();


  static Future<ApiResponse> sendToAgentica(String text, String? imagePath) async {
    try {
      final uri = Uri.parse(apiUrl);
      final request = http.MultipartRequest('POST', uri);

      // 헤더 추가
      request.headers['Authorization'] = 'Bearer $idToken';

      // 텍스트 필드 추가
      request.fields['text'] = text;

      // 이미지 파일이 있는 경우 직접 파일에서 읽어서 전송
      if (imagePath != null && imagePath.isNotEmpty) {
        final file = File(imagePath);
        if (await file.exists()) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'image',      // 서버에서 기대하는 파라미터 이름
              imagePath,
            ),
          );
        } else {
          print('이미지 파일이 존재하지 않습니다: $imagePath');
        }
      }
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      print('🟢 StatusCode: ${response.statusCode}');
      print('🟢 Response body: ${jsonDecode(response.body)['image']}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.fromJson(data);
      } else {
        throw Exception('API 요청 실패: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('sendToAgentica 오류: $e');
      rethrow;
    }
  }
  static Future<List<dynamic>> getConversation() async{

      final uri = Uri.parse(apiUrl2);
      final headers = {
        'Authorization': 'Bearer $idToken',
        // 'Accept': 'application/json',
        // 'User-Agent': 'Camgent/1.0 (Flutter)',
        // GET에서는 보통 Content-Type을 보내지 않습니다 (보내도 문제는 없지만 불필요).
      };

      try{
        final response = await http.get(uri, headers: headers);
        print('🟢 StatusCode: ${response.statusCode}');
        print('🟢 Response body(불러오기): ${response.body}');
        if (response.statusCode == 200) {
          // 한글 / 이모지 안전
          final body = utf8.decode(response.bodyBytes);

          final dynamic data = jsonDecode(body);
          print('data = ${data['history']}');

          return data['history'];
        } else {
          throw Exception('API 요청 실패: ${response.statusCode} - ${response.body}');
        }
      } catch(e){
        print('getConversation 오류: $e');
        rethrow;
      }

    }

}

