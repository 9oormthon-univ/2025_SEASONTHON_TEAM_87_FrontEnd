import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_service.dart';
// import 'stomp_service.dart'; // 직접 사용하지 않음

// 매칭 관련 모델 클래스들
class MatchingUser {
  final String userID;
  final int userRoomNumber;
  final String userAge;
  final String team;

  MatchingUser({
    required this.userID,
    required this.userRoomNumber,
    required this.userAge,
    required this.team,
  });

  factory MatchingUser.fromJson(Map<String, dynamic> json) {
    return MatchingUser(
      userID: json['userID'] ?? '',
      userRoomNumber: json['userRoomNumber'] ?? 0,
      userAge: json['userAge'] ?? '',
      team: json['team'] ?? '',
    );
  }
}

class GameMatchedResponse {
  final int userRoomNumber;
  final String userAge;
  final String team;
  final List<String> citizenTeamAgeList;
  final String mafiaTeamAge;

  GameMatchedResponse({
    required this.userRoomNumber,
    required this.userAge,
    required this.team,
    required this.citizenTeamAgeList,
    required this.mafiaTeamAge,
  });

  factory GameMatchedResponse.fromJson(Map<String, dynamic> json) {
    return GameMatchedResponse(
      userRoomNumber: json['userRoomNumber'] ?? 0,
      userAge: json['userAge'] ?? '',
      team: json['team'] ?? '',
      citizenTeamAgeList: (json['citizenTeamAgeList'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      mafiaTeamAge: json['mafiaTeamAge'] ?? '',
    );
  }
}

// 게임 모델 클래스들
class GamePhaseChangeResponse {
  final String roomId;
  final String content;
  final String phase;
  final String changeTime;
  final String massageReference;

  GamePhaseChangeResponse({
    required this.roomId,
    required this.content,
    required this.phase,
    required this.changeTime,
    required this.massageReference,
  });

  factory GamePhaseChangeResponse.fromJson(Map<String, dynamic> json) {
    return GamePhaseChangeResponse(
      roomId: json['roomId'] ?? '',
      content: json['content'] ?? '',
      phase: json['phase'] ?? '',
      changeTime: json['changeTime'] ?? '',
      massageReference: json['massageReference'] ?? '',
    );
  }
}

class GameVoteResultResponse {
  final String? winnerTeam;
  final List<VoteResult> voteResult;
  final int taggerNumber;
  final String taggerAge;
  final String roomId;

  GameVoteResultResponse({
    this.winnerTeam,
    required this.voteResult,
    required this.taggerNumber,
    required this.taggerAge,
    required this.roomId,
  });

  factory GameVoteResultResponse.fromJson(Map<String, dynamic> json) {
    return GameVoteResultResponse(
      winnerTeam: json['winnerTeam'],
      voteResult: (json['voteResult'] as List<dynamic>?)
          ?.map((e) => VoteResult.fromJson(e))
          .toList() ?? [],
      taggerNumber: json['taggerNumber'] ?? 0,
      taggerAge: json['taggerAge'] ?? '',
      roomId: json['roomId'] ?? '',
    );
  }
}

class VoteResult {
  final int userNumber;
  final int result;
  final String userTeam;

  VoteResult({
    required this.userNumber,
    required this.result,
    required this.userTeam,
  });

  factory VoteResult.fromJson(Map<String, dynamic> json) {
    return VoteResult(
      userNumber: json['userNumber'] ?? 0,
      result: json['result'] ?? 0,
      userTeam: json['userTeam'] ?? '',
    );
  }
}

class GameChatMessageResponse {
  final String roomId;
  final String content;
  final int senderNumber;
  final String massageReference;
  final String sendTime;

  GameChatMessageResponse({
    required this.roomId,
    required this.content,
    required this.senderNumber,
    required this.massageReference,
    required this.sendTime,
  });

  factory GameChatMessageResponse.fromJson(Map<String, dynamic> json) {
    return GameChatMessageResponse(
      roomId: json['roomId'] ?? '',
      content: json['content'] ?? '',
      senderNumber: json['senderNumber'] ?? 0,
      massageReference: json['massageReference'] ?? '',
      sendTime: json['sendTime'] ?? '',
    );
  }
}

class GameApiService {
  static const String baseUrl = 'http://ec2-13-125-117-232.ap-northeast-2.compute.amazonaws.com:8080/api/v1/game';
  
  // 매칭 요청 (게임 참여) - STOMP 방식으로 변경됨
  // 이제 StompService.sendMatchRequest()를 사용하세요
  @Deprecated('Use StompService.sendMatchRequest() instead')
  static Future<ApiResponse> matchGame() async {
    print('⚠️  DEPRECATED: matchGame() is deprecated. Use StompService.sendMatchRequest() instead.');
    return ApiResponse.error('Use STOMP method instead');
  }
  
  // Ready 요청
  static Future<ApiResponse> ready(String chatRoomId) async {
    try {
      final token = await TokenService.instance.getAccessToken();
      if (token == null) {
        print('Ready API: No access token available');
        return ApiResponse.error('No access token available');
      }
      
      print('Ready API: Sending request to $baseUrl/ready');
      print('Ready API: chatRoomId = $chatRoomId');
      print('Ready API: token = ${token.substring(0, 20)}...');
      
      final response = await http.post(
        Uri.parse('$baseUrl/ready'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'chatRoomId': chatRoomId,
        }),
      );
      
      print('Ready API: Response status = ${response.statusCode}');
      print('Ready API: Response body = ${response.body}');
      
      if (response.statusCode == 200) {
        print('Ready API: Success');
        return ApiResponse.success();
      } else {
        final errorData = json.decode(response.body);
        print('Ready API: Error - ${errorData['message']}');
        return ApiResponse.error(
          errorData['message'] ?? 'Ready request failed',
          errorCode: errorData['errorCode'],
        );
      }
    } catch (e) {
      print('Ready API: Exception - $e');
      return ApiResponse.error('Network error: $e');
    }
  }
  
  // Vote 요청
  static Future<ApiResponse> vote(String chatRoomId, int votedUserNumber) async {
    try {
      final token = await TokenService.instance.getAccessToken();
      if (token == null) {
        return ApiResponse.error('No access token available');
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/vote'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'chatRoomId': chatRoomId,
          'votedUserNumber': votedUserNumber,
        }),
      );
      
      if (response.statusCode == 200) {
        return ApiResponse.success();
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(
          errorData['message'] ?? 'Vote request failed',
          errorCode: errorData['errorCode'],
        );
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }
  
  // 방 생성 (임시 - 실제 API에 따라 수정 필요)
  static Future<ApiResponse<String>> createRoom() async {
    try {
      final token = await TokenService.instance.getAccessToken();
      if (token == null) {
        return ApiResponse.error('No access token available');
      }
      
      // 실제 API 엔드포인트에 맞게 수정 필요
      final response = await http.post(
        Uri.parse('$baseUrl/room/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(data['roomId'] ?? '');
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(
          errorData['message'] ?? 'Room creation failed',
          errorCode: errorData['errorCode'],
        );
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }
  
  // 방 참가 (임시 - 실제 API에 따라 수정 필요)
  static Future<ApiResponse<Map<String, dynamic>>> joinRoom(String roomId) async {
    try {
      final token = await TokenService.instance.getAccessToken();
      if (token == null) {
        return ApiResponse.error('No access token available');
      }
      
      // 실제 API 엔드포인트에 맞게 수정 필요
      final response = await http.post(
        Uri.parse('$baseUrl/room/$roomId/join'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(data);
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(
          errorData['message'] ?? 'Join room failed',
          errorCode: errorData['errorCode'],
        );
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }
}

// API 응답 래퍼 클래스
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int? errorCode;
  
  ApiResponse._({
    required this.success,
    this.data,
    this.error,
    this.errorCode,
  });
  
  factory ApiResponse.success([T? data]) {
    return ApiResponse._(success: true, data: data);
  }
  
  factory ApiResponse.error(String error, {int? errorCode}) {
    return ApiResponse._(
      success: false,
      error: error,
      errorCode: errorCode,
    );
  }
}

// 게임 상태 관리
class GameState {
  String? roomId;
  String currentPhase = 'WAIT';
  int? userNumber;
  String? userTeam;
  String? userAge;
  List<Player> players = [];
  int remainingTime = 0;
  bool isReady = false;
  
  void updateFromPhaseChange(GamePhaseChangeResponse response) {
    currentPhase = response.phase;
    // 페이즈별 시간 설정
    switch (response.phase) {
      case 'CHAT':
        remainingTime = 301; // 5분 1초
        break;
      case 'VOTE':
      case 'RE_VOTE':
        remainingTime = 61; // 1분 1초
        break;
      case 'VOTE_RESULT':
      case 'END':
        remainingTime = 2; // 2초
        break;
      default:
        remainingTime = 0;
    }
  }
  
  void updateFromVoteResult(GameVoteResultResponse response) {
    // 투표 결과 처리
    if (response.winnerTeam != null) {
      // 게임 종료
      currentPhase = 'END';
    }
  }
}

// 플레이어 정보
class Player {
  final int userNumber;
  final String userTeam;
  final String userAge;
  final bool isReady;
  
  Player({
    required this.userNumber,
    required this.userTeam,
    required this.userAge,
    required this.isReady,
  });
  
  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      userNumber: json['userNumber'] ?? 0,
      userTeam: json['userTeam'] ?? '',
      userAge: json['userAge'] ?? '',
      isReady: json['isReady'] ?? false,
    );
  }
}
