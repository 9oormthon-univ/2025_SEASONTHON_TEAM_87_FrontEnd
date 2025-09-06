import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // 백엔드 서버 주소
  static const String _baseUrl = "http://ec2-13-125-117-232.ap-northeast-2.compute.amazonaws.com:8080";

  // 로그인 API 호출
  // ❗️ 백엔드에 로그인 API의 정확한 주소(/api/v1/auth/login)와
  // ❗️ 응답 JSON의 토큰 필드명('accessToken')을 확인해야 합니다.
  static Future<String?> login(String loginId, String password) async {
    final url = Uri.parse('$_baseUrl/api/v1/auth/login'); // 로그인 API 엔드포인트

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'loginId': loginId, 'password': password}),
      );

      // 성공적으로 응답을 받았을 때 (상태 코드 200)
      if (response.statusCode == 200) {
        // UTF-8로 디코딩하여 한글 깨짐 방지
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        // 응답 데이터에서 accessToken 추출
        final String accessToken = data['accessToken'];
        return accessToken;
      } else {
        // 로그인 실패 시 (4xx, 5xx 에러)
        print('Login failed: ${response.statusCode}');
        print('Response body: ${utf8.decode(response.bodyBytes)}');
        return null;
      }
    } catch (e) {
      // 네트워크 연결 오류 등 예외 발생 시
      print('Error on login request: $e');
      return null;
    }
  }
}
