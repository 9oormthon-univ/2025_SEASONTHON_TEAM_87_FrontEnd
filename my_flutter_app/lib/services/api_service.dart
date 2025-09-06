import 'dart:convert';
import 'package:http/http.dart' as http;

// API 응답을 담기 위한 간단한 데이터 클래스
class UserSummary {
  final String name;
  UserSummary({required this.name});

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(name: json['name'] ?? '이름없음');
  }
}

class UserRecord {
  final int gameCount;
  final int winCount;
  final int lossCount;
  UserRecord({required this.gameCount, required this.winCount, required this.lossCount});

  factory UserRecord.fromJson(Map<String, dynamic> json) {
    return UserRecord(
      gameCount: json['userGameCount'] ?? 0,
      winCount: json['userWinCount'] ?? 0,
      lossCount: json['userLossCount'] ?? 0,
    );
  }
}


class ApiService {
  // 백엔드 서버 주소
  static const String _baseUrl = "http://ec2-13-125-117-232.ap-northeast-2.compute.amazonaws.com:8080";

  // 로그인 API 호출 함수
  static Future<String?> login(String loginId, String password) async {
    final url = Uri.parse('$_baseUrl/api/v1/auth/local/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'loginId': loginId,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final String accessToken = data['accessToken'];
        return accessToken;
      } else {
        print('로그인 실패: ${response.statusCode}');
        print('응답 내용: ${utf8.decode(response.bodyBytes)}');
        return null;
      }
    } catch (e) {
      print('로그인 중 에러 발생: $e');
      return null;
    }
  }

  // 회원가입 API 호출 함수
  static Future<String?> signup({
    required String name,
    required String birth,
    required String loginId,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/api/v1/auth/local/register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'birth': birth,
          'loginId': loginId,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        print('회원가입 성공');
        return null; // 성공 시 null 반환
      } else {
        print('회원가입 실패: ${response.statusCode}');
        final body = utf8.decode(response.bodyBytes);
        print('응답 내용: $body');
        final Map<String, dynamic> data = jsonDecode(body);
        return data['message'] ?? '알 수 없는 오류가 발생했습니다.';
      }
    } catch (e) {
      print('회원가입 중 에러 발생: $e');
      return '서버와 통신할 수 없습니다.';
    }
  }

  // 아이디 중복 확인 API 호출 함수
  static Future<bool> checkIdAvailability(String loginId) async {
    final url = Uri.parse('$_baseUrl/api/v1/user/id?loginId=$loginId');
    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bool isExist = data['isExist'] ?? true;
        return !isExist;
      } else {
        return false;
      }
    } catch (e) {
      print('아이디 중복 확인 중 에러 발생: $e');
      return false;
    }
  }

  // 사용자 이름 가져오는 API
  static Future<UserSummary?> getUserSummary(String accessToken) async {
    final url = Uri.parse('$_baseUrl/api/v1/user/summary');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return UserSummary.fromJson(data);
      }
    } catch (e) {
      print('사용자 요약 정보 로딩 중 에러: $e');
    }
    return null;
  }

  // 사용자 전적 가져오는 API
  static Future<UserRecord?> getUserRecord(String accessToken) async {
    final url = Uri.parse('$_baseUrl/api/v1/game/user/record');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return UserRecord.fromJson(data);
      }
    } catch (e) {
      print('사용자 전적 정보 로딩 중 에러: $e');
    }
    return null;
  }
}