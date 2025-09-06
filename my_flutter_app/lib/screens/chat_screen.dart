import 'package:flutter/material.dart';
import 'dart:async';
import 'package:bluffing_frontend/services/game_service.dart';
import 'package:bluffing_frontend/services/api_service.dart';
import 'lose_screen.dart';

class ChatScreen extends StatefulWidget {
  final MatchSuccessResponse matchData;
  final String accessToken;

  const ChatScreen({
    super.key,
    required this.matchData,
    required this.accessToken,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // ✅ [추가] GameService 인스턴스 가져오기
  final GameService _gameService = GameService();

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;
  Timer? _countdownTimer;
  Timer? _connectionCheckTimer;
  int _remainingSeconds = 180;
  int _countdownSeconds = 3;
  bool _isReady = false;
  int? _selectedPlayer;
  // TODO: 실제 게임 인원수에 맞게 동적으로 생성해야 함
  final List<int> _players = [2, 3, 4, 5, 6];

  // ✅ [수정] 메시지 목록을 비어있는 상태로 시작
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    
    // ✅ [추가] GameService를 통해 이 방의 공용 채널을 구독 시작 (먼저 실행)
    _gameService.subscribeToGameChannel(
      roomId: widget.matchData.roomId,
      onEvent: _handleGameEvent, // 메시지가 올 때마다 _handleGameEvent 함수 실행
    );
    
    // ✅ [추가] 연결 상태 체크
    _gameService.checkConnectionStatus();
    
    // ✅ [추가] 연결 상태 주기적 체크 (10초마다)
    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _gameService.checkConnectionStatus();
    });

    // 화면이 그려진 후 게임 시작 다이얼로그 표시 및 환영 메시지 추가
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showGameIntroDialog();
      // 환영 메시지는 다이얼로그 표시 후 약간의 지연을 두고 추가
      Future.delayed(const Duration(milliseconds: 100), () {
        _addWelcomeMessage();
      });
    });

    // ✅ [제거] 자동 Ready API 호출 제거 - 준비 버튼 클릭 시에만 호출
  }

  // ✅ [추가] 서버로부터 오는 이벤트를 처리하는 함수
  void _handleGameEvent(GameEvent event) {
    print('📨 게임 이벤트 수신: ${event.runtimeType}');
    
    if (event is ChatMessageEvent) {
      // 채팅 메시지 처리
      print('💬 채팅 메시지: ${event.content}');
      print('👤 발신자: ${event.senderNumber}');
      
      final isMyMessage = event.senderNumber == widget.matchData.userRoomNumber;
      
      final newMessage = ChatMessage(
        text: event.content,
        isMe: isMyMessage,
        playerNumber: isMyMessage ? null : event.senderNumber,
        isSystem: false,
        isServerMessage: false,
        messageReference: 'USER',
      );
      
      _addMessage(newMessage);
    } else if (event is PhaseChangeEvent) {
      // 페이즈 변경 메시지 처리
      print('🔄 페이즈 변경: ${event.phase}');
      print('📝 내용: ${event.content}');
      
      final newMessage = ChatMessage(
        text: event.content,
        isMe: false,
        isSystem: true,
        isServerMessage: true,
        messageReference: 'SERVER',
      );
      
      _addMessage(newMessage);
    } else if (event is VoteResultEvent) {
      // 투표 결과 메시지 처리
      print('🗳️ 투표 결과: ${event.result}');
      print('📝 내용: ${event.content}');
      
      final newMessage = ChatMessage(
        text: event.content,
        isMe: false,
        isSystem: true,
        isServerMessage: true,
        messageReference: 'VOTE_RESULT',
      );
      
      _addMessage(newMessage);
      
      // 투표 결과를 받으면 게임 완전 종료
      _completeGame();
    } else {
      print('❓ 알 수 없는 이벤트 타입: ${event.runtimeType}');
    }
  }

  // 메시지 추가 및 UI 업데이트
  void _addMessage(ChatMessage message) {
    if (!mounted) return;
    
    setState(() {
      _messages.add(message);
    });
    
    print('✅ 메시지 추가 완료. 총 메시지 수: ${_messages.length}');
    
    _scrollToBottom(); // 새 메시지가 오면 맨 아래로 스크롤
  }

  // 환영 메시지 추가
  void _addWelcomeMessage() {
    if (!mounted) return;
    
    try {
      setState(() {
        _messages.add(ChatMessage(
          text: "게임에 참여하신 것을 환영합니다! 🎮",
          isMe: false,
          isSystem: true,
          isServerMessage: false,
        ));
      });
      
      print('👋 환영 메시지 추가 완료');
    } catch (e) {
      print('❌ 환영 메시지 추가 중 오류: $e');
    }
  }

  // Ready API 호출
  void _sendReadyRequest() async {
    print('🎮 Ready API 호출 시작');
    print('🏠 방 ID: ${widget.matchData.roomId}');
    print('🔑 토큰: ${widget.accessToken.substring(0, 20)}...');
    
    final success = await ApiService.postReady(widget.accessToken, widget.matchData.roomId);
    if (success) {
      print('✅ Ready API 호출 성공');
      setState(() {
        _isReady = true;
      });
    } else {
      print('❌ Ready API 호출 실패');
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (build 메서드의 UI 구조는 변경 없음) ...
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            Container(
              color: const Color(0xFF8F2AB0),
              child: SafeArea(
                bottom: false,
                child: Container(),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildGameInfo(),
                  Expanded(
                    child: _buildChatList(),
                  ),
                  _buildMessageInput(),
                ],
              ),
            ),
            Container(
              color: Colors.grey.shade200,
              child: SafeArea(
                top: false,
                child: Container(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ [수정] 메시지 전송 함수 - 명세에 맞게 구현
  void _sendMessage() {
    final messageContent = _messageController.text.trim();
    if (messageContent.isNotEmpty) {
      print('📤 채팅 메시지 전송 시작');
      print('💬 내용: $messageContent');
      print('🏠 방 ID: ${widget.matchData.roomId}');
      print('👤 발신자 번호: ${widget.matchData.userRoomNumber}');
      
      // 연결 상태 체크
      _gameService.checkConnectionStatus();
      
      // GameService를 통해 서버로 메시지 전송 (STOMP)
      _gameService.sendChatMessage(
        roomId: widget.matchData.roomId,
        senderNumber: widget.matchData.userRoomNumber,
        content: messageContent,
      );

      // 메시지 입력창 초기화
      _messageController.clear();
      
      print('✅ 채팅 메시지 전송 완료');
    } else {
      print('❌ 채팅 메시지 전송 실패: 메시지가 비어있음');
    }
  }

  // ✅ [추가] 스크롤을 맨 아래로 내리는 함수
  void _scrollToBottom() {
    // 잠시 기다린 후 스크롤해야 UI가 완전히 그려진 후 정확히 이동함
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    // ✅ [추가] 화면이 종료될 때 반드시 구독을 해제하여 메모리 누수 방지
    _gameService.unsubscribeFromGameChannel();

    _messageController.dispose();
    _scrollController.dispose();
    _timer?.cancel();
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = null;
    
    // ✅ STOMP 클라이언트는 게임이 완전히 끝날 때만 비활성화
    // 일반적인 화면 전환 시에는 연결을 유지
    _gameService.safeDeactivate(force: false); // 연결 유지
    super.dispose();
  }

  // (UI를 그리는 나머지 함수들은 이전과 거의 동일)
  Widget _buildHeader() {
    const Color purple = Color(0xFF8F2AB0);

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 72,
          width: double.infinity,
          color: purple,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Row(
                children: [
                  Text(
                    '${widget.matchData.userRoomNumber}번',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Image.asset(
                    'assets/InChatCharacter.png',
                    height: 30,
                    width: 30,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          left: -10,
          top: 0,
          bottom: 0,
          child: Center(
            child: Image.asset(
              'assets/InChatLogo.png',
              height: 40,
              width: 140,
              fit: BoxFit.contain,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF4C1D95),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _formatTime(_remainingSeconds),
            style: const TextStyle(
              color: Colors.red,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.yellow.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '주제: 급식',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '20대: 5명',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '40대: 1명',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Text(
            message.text,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    // 서버 메시지 처리
    if (message.isServerMessage) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue[600],
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message.text,
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isMe) ...[
            Column(
              children: [
                Image.asset(
                  'assets/InChatOthers.png',
                  height: 30,
                  width: 30,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 2),
                Text(
                  '${message.playerNumber}번',
                  style: const TextStyle(
                    color: Color(0xFF6B46C1),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
                minWidth: 50,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isMe ? Colors.grey.shade200 : const Color(0x118F2AB0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message.text,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        border: const Border(
          top: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: '메시지를 입력하세요.',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: const Icon(
              Icons.send,
              color: Color(0xFF8F2AB0),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  void _showGameIntroDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (_countdownTimer == null) {
              _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
                setDialogState(() {
                  if (_countdownSeconds > 1) {
                    _countdownSeconds--;
                  } else {
                    _countdownTimer?.cancel();
                    _countdownTimer = null;
                    Navigator.of(context).pop();
                    // 준비하지 않은 상태에서 20초가 지나면 자동으로 Ready API 호출
                    if (!_isReady) {
                      _sendReadyRequest();
                    }
                    _startGame();
                  }
                });
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.all(24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8F2AB0).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sports_esports,
                      size: 40,
                      color: Color(0xFF8F2AB0),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Bluffing',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8F2AB0),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '20대 채팅방에',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '40대',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              TextSpan(
                                text: '가 숨어 있습니다.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '3분간 토론을 통해 찾아내세요!',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$_countdownSeconds초 뒤 게임이 시작됩니다...',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 준비 상태에 따른 UI 표시
                  if (!_isReady) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$_countdownSeconds초 뒤 게임이 시작됩니다...',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          setDialogState(() {
                            _isReady = true;
                          });
                          _sendReadyRequest();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8F2AB0),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '준비 완료',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '준비 완료! 게임 시작을 기다리는 중...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _startGame() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          _endGame();
        }
      });
    });
  }

  void _endGame() {
    print("🎮 게임 종료 - 투표 다이얼로그 표시");
    _showVoteDialog();
  }

  // 게임 완전 종료 시 STOMP 클라이언트 비활성화
  void _completeGame() {
    print("🏁 게임 완전 종료 - STOMP 클라이언트 비활성화");
    _gameService.safeDeactivate(force: true); // 강제 비활성화
  }

  void _showVoteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.65,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                      ),
                      child: const Column(
                        children: [
                          Text(
                            '투표 시간입니다',
                            style: TextStyle(
                              color: Color(0xFF33FF00),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '15초간 40대를 맞춰보세요!',
                            style: TextStyle(
                              color: Color(0xFF33FF00),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildVoteCard(0, setDialogState),
                                  const SizedBox(width: 10),
                                  _buildVoteCard(1, setDialogState),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildVoteCard(2, setDialogState),
                                  const SizedBox(width: 10),
                                  _buildVoteCard(3, setDialogState),
                                  const SizedBox(width: 10),
                                  _buildVoteCard(4, setDialogState),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Column(
                        children: [
                          const Text(
                            '투표 기다리는 중...',
                            style: TextStyle(
                              color: Color(0xFF33FF00),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _selectedPlayer != null ? _submitVote : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedPlayer != null ? Colors.amber : Colors.grey,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                '투표',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVoteCard(int index, StateSetter setDialogState) {
    final playerNumber = _players[index];
    final isSelected = _selectedPlayer == playerNumber;

    return GestureDetector(
      onTap: () {
        setDialogState(() {
          _selectedPlayer = isSelected ? null : playerNumber;
        });
      },
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.red : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/voteCardIcon.png',
                        height: 50,
                        width: 50,
                        fit: BoxFit.contain,
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 2),
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Text(
                '${playerNumber}번',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.red : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitVote() async {
    if (_selectedPlayer != null) {
      print('🗳️ 투표 제출 시작');
      print('👤 투표 대상: $_selectedPlayer');
      print('🏠 방 ID: ${widget.matchData.roomId}');
      
      final success = await ApiService.postVote(
        widget.accessToken,
        widget.matchData.roomId,
        _selectedPlayer!,
      );
        
        if (success) {
          print('✅ 투표 제출 성공');
          Navigator.of(context).pop();
          // 투표 결과는 STOMP로 받아옴
        } else {
          print('❌ 투표 제출 실패');
          // 에러 처리
        }
      } else {
        print('❌ 토큰이 없어 투표할 수 없습니다');
        // 임시로 LoseScreen으로 이동 (테스트용)
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const LoseScreen(),
          ),
        );
      }
    }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

class ChatMessage {
  final String text;
  final bool isMe;
  final int? playerNumber;
  final bool isSystem;
  final bool isServerMessage;
  final String? roomId;
  final String? sendTime;
  final String? messageReference; // "USER" | "SERVER"

  ChatMessage({
    required this.text,
    required this.isMe,
    this.playerNumber,
    this.isSystem = false,
    this.isServerMessage = false,
    this.roomId,
    this.sendTime,
    this.messageReference,
  });

  // GameChatMessageResponse에서 생성
  factory ChatMessage.fromGameChatResponse(Map<String, dynamic> data) {
    return ChatMessage(
      text: data['content'] ?? data['message'] ?? '', // 새로운 형식: content 우선
      isMe: false, // 서버에서 받은 메시지는 일단 false로 설정
      playerNumber: data['senderNumber'],
      isSystem: false,
      isServerMessage: data['messageReference'] == 'SERVER', // ✅ 오타 수정
      roomId: data['roomId'],
      sendTime: data['sendTime'],
      messageReference: data['messageReference'], // ✅ 오타 수정
    );
  }
}
