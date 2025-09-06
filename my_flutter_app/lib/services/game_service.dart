import 'dart:convert';
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

class VoteResultEvent extends GameEvent {
  final String result;
  final String content;
  VoteResultEvent({required this.result, required this.content});
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
        onDisconnect: (frame) {
          print("🔌 STOMP 연결이 끊어졌습니다: ${frame.body}");
        },
        onWebSocketError: (dynamic error) {
          print("❌ 웹소켓 에러: ${error.toString()}");
          onMatchError?.call("서버와 연결할 수 없습니다.");
        },
        onStompError: (frame) {
          print("❌ STOMP 에러: ${frame.body}");
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
    print("🔄 STOMP 클라이언트 활성화 시도");
    print("   - 현재 stompClient: ${stompClient != null ? '존재' : 'null'}");
    print("   - 현재 연결 상태: ${stompClient?.connected}");
    
    if (stompClient == null || !stompClient!.connected) {
      print("   - 새로운 STOMP 클라이언트 설정 중...");
      _setupStompClient(accessToken);
      stompClient?.activate();
      print("   - STOMP 클라이언트 활성화 완료");
    } else {
      print("   - STOMP 클라이언트가 이미 연결되어 있음");
    }
  }

  // 연결 상태 체크 메서드
  void checkConnectionStatus() {
    print("🔍 STOMP 연결 상태 상세 체크:");
    print("   - stompClient: ${stompClient != null ? '존재' : 'null'}");
    if (stompClient != null) {
      print("   - connected: ${stompClient!.connected}");
      print("   - _accessToken: ${_accessToken != null ? '존재 (${_accessToken!.substring(0, 20)}...)' : 'null'}");
    }
  }

  void deactivate() {
    print("🔌 STOMP 클라이언트 비활성화 요청");
    print("   - 현재 연결 상태: ${stompClient?.connected}");
    print("   - 비활성화를 진행합니다...");
    
    try {
      stompClient?.deactivate();
      stompClient = null;
      print("✅ STOMP 클라이언트 비활성화 완료");
    } catch (e) {
      print("❌ STOMP 클라이언트 비활성화 중 오류: $e");
      stompClient = null; // 강제로 null로 설정
    }
  }

  // 안전한 비활성화 - 특정 조건에서만 비활성화
  void safeDeactivate({bool force = false}) {
    print("🛡️ STOMP 클라이언트 안전한 비활성화 검토");
    print("   - 현재 연결 상태: ${stompClient?.connected}");
    print("   - 강제 비활성화: $force");
    
    if (force) {
      print("   - 강제 비활성화 모드로 진행");
      deactivate();
    } else {
      print("   - 일반적인 경우에는 비활성화하지 않음 (연결 유지)");
      print("   - STOMP 연결을 유지하여 다른 화면에서 계속 사용 가능");
    }
  }

  void _onConnect(StompFrame frame) {
    print("STOMP 클라이언트 연결 성공!");

    stompClient?.subscribe(
      destination: '/user/queue/match/notify',
      callback: (frame) {
        if (frame.body != null) {
          try {
            final body = jsonDecode(frame.body!);
            print('✅ 매칭 알림 수신: $body');
            
            // MatchSuccessResponse로 파싱 시도
            final response = MatchSuccessResponse.fromJson(body);
            if (response.roomId.isEmpty) {
              throw Exception("응답에서 roomId를 찾을 수 없습니다.");
            }

            print("매칭 완료! 바로 채팅방으로 입장합니다.");
            // 20초 대기 없이 바로 채팅방으로 입장
            onMatchSuccess?.call(response);
          } catch (e) {
            print("매칭 성공 메시지 처리 에러: $e");
            onMatchError?.call("잘못된 매칭 데이터입니다.");
            // 매칭 에러 시에도 연결을 유지하여 재시도 가능하도록 함
            // deactivate(); // 제거: 연결을 유지
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
      // 매칭 요청 에러 시에도 연결을 유지하여 재시도 가능하도록 함
      // deactivate(); // 제거: 연결을 유지
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
          print("🔍 수신된 메시지 데이터: $data");
          
          if (data['phase'] != null) {
            onGameEvent?.call(PhaseChangeEvent(phase: data['phase'], content: data['content']));
          } else if (data['messageReference'] == 'USER') {
            onGameEvent?.call(ChatMessageEvent(
              content: data['content'] ?? data['message'] ?? '', // 새로운 형식: content 우선
              senderNumber: data['senderNumber'],
              sendTime: data['sendTime'],
            ));
          } else if (data['messageReference'] == 'SERVER') {
            onGameEvent?.call(PhaseChangeEvent(
              phase: 'SERVER_MESSAGE',
              content: data['content'] ?? '',
            ));
          } else if (data['messageReference'] == 'VOTE_RESULT') {
            onGameEvent?.call(VoteResultEvent(
              result: data['result'] ?? '',
              content: data['content'] ?? '',
            ));
          } else {
            print("❓ 알 수 없는 messageReference: ${data['messageReference']}");
            print("❓ 전체 데이터: $data");
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
    print("🔍 STOMP 연결 상태 체크:");
    print("   - stompClient: ${stompClient != null ? '존재' : 'null'}");
    print("   - connected: ${stompClient?.connected}");
    print("   - _accessToken: ${_accessToken != null ? '존재' : 'null'}");
    
    if (stompClient == null || !stompClient!.connected) {
      print("❌ STOMP 연결이 끊어져 메시지를 보낼 수 없습니다.");
      print("   - stompClient가 null인가? ${stompClient == null}");
      print("   - 연결 상태: ${stompClient?.connected}");
      
      // 연결 재시도
      if (_accessToken != null) {
        print("🔄 STOMP 연결 재시도 중...");
        activate(_accessToken!);
        // 재연결 후 잠시 대기
        Future.delayed(const Duration(milliseconds: 500), () {
          if (stompClient != null && stompClient!.connected) {
            print("✅ STOMP 재연결 성공, 메시지 재전송 시도");
            _sendMessageInternal(roomId, senderNumber, content);
          } else {
            print("❌ STOMP 재연결 실패");
          }
        });
      }
      return;
    }
    
    _sendMessageInternal(roomId, senderNumber, content);
  }

  void _sendMessageInternal(String roomId, int senderNumber, String content) {
    try {
      // 입력 값 검증
      if (roomId.isEmpty) {
        print("❌ roomId가 비어있습니다");
        return;
      }
      if (content.isEmpty) {
        print("❌ content가 비어있습니다");
        return;
      }
      if (senderNumber <= 0) {
        print("❌ senderNumber가 유효하지 않습니다: $senderNumber");
        return;
      }
      
      final messageBody = {
        'roomId': roomId,
        'content': content,
        'senderNumber': senderNumber,
        'sendTime': DateTime.now().toIso8601String(),
      };
      
      final jsonBody = jsonEncode(messageBody);
      
      print("🔍 메시지 전송 디버그:");
      print("   - STOMP 연결 상태: ${stompClient?.connected}");
      print("   - destination: /api/v1/game/message");
      print("   - headers: {'Content-Type': 'application/json; charset=utf-8'}");
      print("   - body: $jsonBody");
      print("   - body length: ${jsonBody.length}");
      print("   - roomId: '$roomId' (length: ${roomId.length})");
      print("   - content: '$content' (length: ${content.length})");
      print("   - senderNumber: $senderNumber");
      
      stompClient?.send(
        destination: '/api/v1/game/message',
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: jsonBody,
      );
      print("✅ 채팅 메시지 전송 성공: $content");
    } catch (e) {
      print("❌ 채팅 메시지 전송 실패: $e");
      print("❌ 에러 상세: ${e.toString()}");
    }
  }
}