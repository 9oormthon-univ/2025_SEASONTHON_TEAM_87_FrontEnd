import 'dart:async';
import 'dart:convert';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'token_service.dart';

class StompService {
  static StompService? _instance;
  static StompService get instance => _instance ??= StompService._();
  
  StompService._();
  
  StompClient? _stompClient;
  final StreamController<Map<String, dynamic>> _messageController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  // 메시지 스트림 (외부에서 구독)
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  
  // 연결 상태
  bool get isConnected => _stompClient?.connected ?? false;
  
  // STOMP 연결
  Future<bool> connect({required String baseUrl}) async {
    try {
      final token = await TokenService.instance.getAccessToken();
      if (token == null) {
        print('No access token available');
        return false;
      }

      // SockJS 지원을 위한 URL 수정
      final sockJsUrl = baseUrl.replaceFirst('ws://', 'http://').replaceFirst('wss://', 'https://');
      
      final config = StompConfig(
        url: sockJsUrl,
        onConnect: _onConnect,
        onStompError: _onStompError,
        onWebSocketError: _onWebSocketError,
        onDebugMessage: (message) => print('STOMP Debug: $message'),
        connectionTimeout: const Duration(seconds: 10),
        heartbeatIncoming: const Duration(seconds: 30),
        heartbeatOutgoing: const Duration(seconds: 30),
        stompConnectHeaders: {
          'Authorization': 'Bearer $token',
        },
        // SockJS 사용
        useSockJS: true,
      );

      _stompClient = StompClient(config: config);
      _stompClient!.activate();

      // 연결 확인을 위한 짧은 대기
      await Future.delayed(const Duration(milliseconds: 1000));

      return _stompClient!.connected;
    } catch (e) {
      print('STOMP connection error: $e');
      return false;
    }
  }
  
  // 연결 콜백
  void _onConnect(StompFrame frame) {
    print('✅ STOMP 연결 성공!');
    print('📡 연결 정보: ${frame.body}');
    print('🔗 연결 상태: ${_stompClient?.connected}');
    print('⏰ 연결 시간: ${DateTime.now().toIso8601String()}');
  }
  
  // STOMP 에러 콜백
  void _onStompError(StompFrame frame) {
    print('❌ STOMP 에러 발생!');
    print('🚨 에러 내용: ${frame.body}');
    print('⏰ 에러 시간: ${DateTime.now().toIso8601String()}');
  }

  // WebSocket 에러 콜백
  void _onWebSocketError(dynamic error) {
    print('❌ WebSocket 에러 발생!');
    print('🚨 에러 내용: $error');
    print('⏰ 에러 시간: ${DateTime.now().toIso8601String()}');
  }
  
  // 매칭 알림 구독 - 명세에 따른 토픽
  Future<void> subscribeToMatchNotification() async {
    if (_stompClient == null || !isConnected) {
      print('❌ STOMP 클라이언트가 연결되지 않음');
      return;
    }
    
    final topic = '/user/api/v1/game/match/notify';
    print('🔔 매칭 알림 구독 시작: $topic');
    
    _stompClient!.subscribe(
      destination: topic,
      callback: (frame) {
        try {
          final message = json.decode(frame.body ?? '{}') as Map<String, dynamic>;
          print('📨 매칭 알림 수신: $message');
          _messageController.add(message);
        } catch (e) {
          print('❌ 매칭 알림 파싱 오류: $e');
        }
      },
    );
    
    print('✅ 매칭 알림 구독 완료');
  }

  // 방 구독
  Future<void> subscribeToRoom(String roomId) async {
    if (_stompClient == null || !isConnected) {
      print('❌ STOMP 클라이언트가 연결되지 않음');
      return;
    }
    
    final topic = '/api/v1/game/server/room/$roomId';
    print('🏠 방 구독 시작: $topic');
    print('🆔 방 ID: $roomId');
    
    _stompClient!.subscribe(
      destination: topic,
      callback: (frame) {
        try {
          final message = json.decode(frame.body ?? '{}') as Map<String, dynamic>;
          print('📨 게임 메시지 수신: $message');
          _messageController.add(message);
        } catch (e) {
          print('❌ 게임 메시지 파싱 오류: $e');
        }
      },
    );
    
    print('✅ 방 구독 완료');
  }
  
  // 매칭 요청 - STOMP 방식
  Future<void> sendMatchRequest() async {
    if (_stompClient == null || !isConnected) {
      print('❌ STOMP 클라이언트가 연결되지 않음');
      return;
    }
    
    final message = {
      'regular': true,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    print('🎮 매칭 요청 전송 (STOMP)');
    print('📤 전송 대상: /api/v1/game/match');
    print('📦 요청 바디: $message');
    
    try {
      _stompClient!.send(
        destination: '/api/v1/game/match',
        body: json.encode(message),
      );
      print('✅ 매칭 요청 전송 완료');
    } catch (e) {
      print('❌ 매칭 요청 전송 오류: $e');
    }
  }

  // 채팅 메시지 전송
  Future<void> sendChatMessage({
    required String roomId,
    required String content,
    required int senderNumber,
  }) async {
    if (_stompClient == null || !isConnected) {
      print('❌ STOMP 클라이언트가 연결되지 않음');
      return;
    }
    
    final message = {
      'roomId': roomId,
      'content': content,
      'senderNumber': senderNumber,
      'sendTime': DateTime.now().toIso8601String(),
    };
    
    print('💬 채팅 메시지 전송: $content');
    print('📤 전송 대상: /api/v1/game/chat/message');
    
    try {
      _stompClient!.send(
        destination: '/api/v1/game/chat/message',
        body: json.encode(message),
      );
      print('✅ 채팅 메시지 전송 완료');
    } catch (e) {
      print('❌ 채팅 메시지 전송 오류: $e');
    }
  }
  
  // 연결 해제
  Future<void> disconnect() async {
    if (_stompClient != null) {
      print('🔌 STOMP 연결 해제 중...');
      _stompClient!.deactivate();
      _stompClient = null;
      print('✅ STOMP 연결 해제 완료');
    }
  }
  
  // 리소스 정리
  void dispose() {
    disconnect();
    _messageController.close();
  }
}

// 게임 메시지 타입 정의
class GameMessage {
  final String type;
  final Map<String, dynamic> data;
  
  GameMessage({required this.type, required this.data});
  
  factory GameMessage.fromJson(Map<String, dynamic> json) {
    return GameMessage(
      type: _determineMessageType(json),
      data: json,
    );
  }
  
  static String _determineMessageType(Map<String, dynamic> json) {
    // 페이즈 변경 메시지
    if (json.containsKey('phase') && json.containsKey('changeTime')) {
      return 'PHASE_CHANGE';
    }
    
    // 투표 결과 메시지
    if (json.containsKey('winnerTeam') && json.containsKey('voteResult')) {
      return 'VOTE_RESULT';
    }
    
    // 채팅 메시지
    if (json.containsKey('senderNumber') && json.containsKey('content')) {
      return 'CHAT';
    }
    
    return 'UNKNOWN';
  }
}

// 모델 클래스들은 game_api_service.dart에서 import하여 사용
