import 'dart:async';
import 'dart:convert';
import 'package:bluffing_frontend/services/api_service.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

// --- 데이터 클래스 정의 ---

abstract class GameEvent {}

class ChatMessageEvent extends GameEvent {
  final String content;
  final int senderNumber;
  final String sendTime;
  ChatMessageEvent({required this.content, required this.senderNumber, required this.sendTime});
}

class PhaseChangeEvent extends GameEvent {
  final String phase;
  final String content;
  PhaseChangeEvent({required this.phase, required this.content});
}

class UnknownEvent extends GameEvent {}

class MatchSuccessResponse {
  final String roomId;
  final int userRoomNumber;
  final String userAge;
  final String team;

  MatchSuccessResponse({
    required this.roomId,
    required this.userRoomNumber,
    required this.userAge,
    required this.team,
  });

  factory MatchSuccessResponse.fromJson(Map<String, dynamic> json) {
    return MatchSuccessResponse(
      roomId: json['roomId'] ?? '',
      userRoomNumber: json['userRoomNumber'],
      userAge: json['userAge'],
      team: json['team'],
    );
  }
}

// --- 게임 서비스 클래스 ---

class GameService {
  static final GameService _instance = GameService._internal();
  factory GameService() => _instance;
  GameService._internal();

  StompClient? stompClient;
  String? _accessToken;

  // 콜백 함수 정의
  Function()? onMatchRequested;
  Function(MatchSuccessResponse response)? onMatchSuccess;
  Function(String error)? onMatchError;
  Function(GameEvent event)? onGameEvent;

  // ✅ [수정] 구독 해제 함수의 타입을 Function? 으로 변경
  Function? _gameChannelUnsubscribeCallback;


  void _setupStompClient(String accessToken) {
    stompClient = StompClient(
      config: StompConfig(
        url: 'ws://ec2-13-125-117-232.ap-northeast-2.compute.amazonaws.com:8080/ws'.trim(),
        onConnect: _onConnect,
        onWebSocketError: (dynamic error) {
          print("웹소켓 에러: ${error.toString()}");
          onMatchError?.call("서버와 연결할 수 없습니다.");
        },
        stompConnectHeaders: {'Authorization': 'Bearer $accessToken'},
        webSocketConnectHeaders: {
          'Authorization': 'Bearer $accessToken',
          'Sec-WebSocket-Protocol': 'v10.stomp, v11.stomp, v12.stomp',
        },
      ),
    );
  }

  void activate(String accessToken) {
    if (stompClient == null || !stompClient!.connected) {
      _setupStompClient(accessToken);
      stompClient?.activate();
    }
  }

  void deactivate() {
    stompClient?.deactivate();
    stompClient = null;
    print("STOMP 클라이언트 비활성화됨");
  }

  void _onConnect(StompFrame frame) {
    print("STOMP 클라이언트 연결 성공!");

    stompClient?.subscribe(
      destination: '/user/queue/match/notify',
      callback: (frame) {
        print("매칭 성공 메시지 수신!");
        if (frame.body != null) {
          try {
            final data = jsonDecode(frame.body!);
            final response = MatchSuccessResponse.fromJson(data);
            if (response.roomId.isEmpty) throw Exception("응답에서 roomId를 찾을 수 없습니다.");

            print("20초 후 '준비 완료' REST API를 호출합니다.");
            Timer(const Duration(seconds: 20), () async {
              if (_accessToken != null) {
                bool readySuccess = await ApiService.sendReady(accessToken: _accessToken!, chatRoomId: response.roomId);
                if (readySuccess) {
                  onMatchSuccess?.call(response);
                } else {
                  onMatchError?.call("'준비 완료' 요청에 실패했습니다.");
                }
              }
            });
          } catch (e) {
            print("매칭 성공 메시지 처리 에러: $e");
            onMatchError?.call("잘못된 매칭 데이터입니다.");
            deactivate();
          }
        }
      },
    );

    _requestMatchAndNotify();
  }

  void _requestMatchAndNotify() {
    final token = _accessToken;
    if (token == null) {
      onMatchError?.call("인증 토큰이 없습니다.");
      return;
    }
    print("게임 매칭 STOMP 메시지를 전송합니다...");
    try {
      stompClient?.send(
        destination: '/api/v1/game/notify',
        headers: {'Authorization': 'Bearer $token'},
        body: jsonEncode({'matchCategory': 'REGULAR'}),
      );
      onMatchRequested?.call();
    } catch (e) {
      print("매칭 요청(STOMP) 중 에러: $e");
      onMatchError?.call("매칭 요청에 실패했습니다.");
      deactivate();
    }
  }

  void startMatching({
    required String accessToken,
    required Function() onRequested,
    required Function(MatchSuccessResponse response) onSuccess,
    required Function(String error) onError,
  }) {
    _accessToken = accessToken;
    onMatchRequested = onRequested;
    onMatchSuccess = onSuccess;
    onMatchError = onError;
    activate(accessToken);
  }

  // --- ChatScreen을 위한 함수들 ---

  void subscribeToGameChannel({
    required String roomId,
    required Function(GameEvent event) onEvent,
  }) {
    onGameEvent = onEvent;
    // ✅ [수정] subscribe가 반환하는 '구독 해제 함수'를 변수에 저장
    _gameChannelUnsubscribeCallback = stompClient?.subscribe(
      destination: '/topic/game/room/$roomId',
      callback: (frame) {
        if (frame.body != null) {
          final data = jsonDecode(frame.body!);
          if (data['phase'] != null) {
            onGameEvent?.call(PhaseChangeEvent(phase: data['phase'], content: data['content']));
          } else if (data['massageReference'] == 'USER') {
            onGameEvent?.call(ChatMessageEvent(
              content: data['message'] ?? data['content'] ?? '', // 새로운 형식: message, 기존 형식: content
              senderNumber: data['senderNumber'],
              sendTime: data['sendTime'],
            ));
          } else {
            onGameEvent?.call(UnknownEvent());
          }
        }
      },
    );
    print("$roomId 방의 공용 채널 구독 시작");
  }

  void unsubscribeFromGameChannel() {
    // ✅ [수정] .unsubscribe() 대신, 저장해둔 함수를 직접 호출
    _gameChannelUnsubscribeCallback?.call();
    _gameChannelUnsubscribeCallback = null;
    print("게임 방 공용 채널 구독 해제");
  }

  void sendChatMessage({
    required String roomId,
    required int senderNumber,
    required String content,
  }) {
    if (stompClient == null || !stompClient!.connected) {
      print("STOMP 연결이 끊어져 메시지를 보낼 수 없습니다.");
      return;
    }

    final token = _accessToken;
    if (token == null) {
      print("토큰이 없어 메시지를 보낼 수 없습니다.");
      return;
    }

    stompClient?.send(
      destination: '/api/v1/game/message',
      headers: {'Authorization': 'Bearer $token'},
      body: jsonEncode({
        'roomId': roomId,
        'message': content,
        'senderNumber': senderNumber,
        'sendTime': DateTime.now().toIso8601String(),
      }),
    );
    print("채팅 메시지 전송: $content");
  }
}