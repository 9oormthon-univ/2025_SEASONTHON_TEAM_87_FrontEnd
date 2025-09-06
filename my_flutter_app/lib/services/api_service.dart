// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ✅ 제공해주신 실제 서버 주소로 변경했습니다.
  static const String _baseUrl = "http://ec2-13-125-117-232.ap-northeast-2.compute.amazonaws.com:8080";

  // 로그인 API 호출
  static Future<String?> login(String loginId, String password) async {
    // ❗️ 문서에 로그인 API 명세가 없으므로, 일반적인 형태로 가정했습니다.
    // ❗️ 백엔드 개발자에게 정확한 주소와 요청/응답 형식을 꼭 확인하세요.
    final url = Uri.parse('$_baseUrl/api/v1/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'loginId': loginId, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)); // 한글 깨짐 방지
        // 'accessToken' 필드가 있다고 가정합니다. 실제 필드명으로 수정 필요.
        final String accessToken = data['accessToken'];
        return accessToken;
      } else {
        print('Login failed: ${response.statusCode}');
        print('Response body: ${utf8.decode(response.bodyBytes)}');
        return null;
      }
    } catch (e) {
      print('Error on login: $e');
      return null;
    }
  }
}