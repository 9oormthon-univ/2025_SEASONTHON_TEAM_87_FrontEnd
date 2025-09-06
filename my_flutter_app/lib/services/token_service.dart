import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  
  static TokenService? _instance;
  static TokenService get instance => _instance ??= TokenService._();
  
  TokenService._();
  
  // JWT 토큰 저장
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    if (refreshToken != null) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
  }
  
  // Access Token 가져오기
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }
  
  // Refresh Token 가져오기
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }
  
  // 토큰 삭제 (로그아웃)
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }
  
  // 토큰 존재 여부 확인
  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    if (token == null) return false;
    
    // JWT 토큰 만료 시간 확인 (간단한 구현)
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      
      final payload = parts[1];
      // Base64 디코딩
      final normalized = base64Url.normalize(payload);
      final resp = utf8.decode(base64Url.decode(normalized));
      final payloadMap = json.decode(resp);
      
      final exp = payloadMap['exp'] as int?;
      if (exp == null) return false;
      
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return exp > now;
    } catch (e) {
      return false;
    }
  }
  
  // Authorization 헤더 생성
  Future<String?> getAuthorizationHeader() async {
    final token = await getAccessToken();
    return token != null ? 'Bearer $token' : null;
  }
}

// Base64 URL 디코딩을 위한 확장
extension Base64Url on String {
  static String normalize(String input) {
    return input.replaceAll('-', '+').replaceAll('_', '/');
  }
}
