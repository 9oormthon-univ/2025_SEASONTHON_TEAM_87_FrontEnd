import 'package:flutter/material.dart';
import 'dart:async';
import 'victory_screen.dart';
import 'lose_screen.dart';
import '../services/stomp_service.dart';
import '../services/game_api_service.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;
  final int userNumber;
  
  const ChatScreen({
    super.key,
    required this.roomId,
    required this.userNumber,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;
  Timer? _countdownTimer;
  int _remainingSeconds = 1; // 3분 = 180초
  int _countdownSeconds = 1; // 5초 카운트다운
  
  // STOMP 및 게임 상태 관리
  final StompService _stompService = StompService.instance;
  final GameState _gameState = GameState();
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  String? _roomId;
  int _userNumber = 1; // 임시로 1번으로 설정
  
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "급식에 떡볶이 나왔었음",
      isMe: true,
      playerNumber: null,
    ),
    ChatMessage(
      text: "아이스크림도 종종 나옴",
      isMe: false,
      playerNumber: 3,
    ),
    ChatMessage(
      text: "엥 그럴리가",
      isMe: false,
      playerNumber: 2,
    ),
    ChatMessage(
      text: "학바학인거 같은데",
      isMe: false,
      playerNumber: 4,
    ),
    ChatMessage(
      text: "주제가 알잘딱이 아니네",
      isMe: false,
      playerNumber: 6,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 키보드 외의 영역을 터치하면 키보드 숨기기
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // 상단 SafeArea (보라색)
            Container(
              color: const Color(0xFF8F2AB0),
              child: SafeArea(
                bottom: false,
                child: Container(),
              ),
            ),
            // 메인 콘텐츠
            Expanded(
              child: Column(
                children: [
                  // 상단 헤더
                  _buildHeader(),
                  // 게임 정보
                  _buildGameInfo(),
                  // 채팅 메시지 리스트
                  Expanded(
                    child: _buildChatList(),
                  ),
                  // 메시지 입력 영역
                  _buildMessageInput(),
                ],
              ),
            ),
            // 하단 SafeArea (회색)
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

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }
  
  Future<void> _initializeGame() async {
    // 홈 화면에서 받은 정보 사용
    _roomId = widget.roomId;
    _userNumber = widget.userNumber;
    
    // STOMP 연결
    final endpoints = [
      'ws://ec2-13-125-117-232.ap-northeast-2.compute.amazonaws.com:8080/ws',
    ];
    
    bool connected = false;
    for (final endpoint in endpoints) {
      print('WebSocket 연결 시도: $endpoint');
      connected = await _stompService.connect(baseUrl: endpoint);
      if (connected) {
        print('WebSocket 연결 성공: $endpoint');
        break;
      }
    }
    
    if (connected && _roomId != null) {
      // 방 구독
      await _stompService.subscribeToRoom(_roomId!);
      
      // 메시지 스트림 구독
      _messageSubscription = _stompService.messageStream.listen(_handleMessage);
      
      // 20초 대기 후 Ready 요청 (명세에 따라)
      print('20초 후 게임을 시작합니다...');
      await Future.delayed(const Duration(seconds: 20));
      
      // Ready 요청
      await _sendReady();
      
      // 게임 시작 다이얼로그 표시
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showGameIntroDialog();
      });
    } else {
      print('STOMP 연결 실패');
    }
  }
  
  
  Future<void> _sendReady() async {
    if (_roomId == null) return;
    
    final response = await GameApiService.ready(_roomId!);
    if (response.success) {
      print('Ready request sent successfully');
    } else {
      print('Ready request failed: ${response.error}');
    }
  }
  
  void _handleMessage(Map<String, dynamic> message) {
    // 명세에 따른 메시지 타입 분기
    if (message['phase'] != null) {
      // GamePhaseChangeResponse - 페이즈 변경
      _handlePhaseChange(GamePhaseChangeResponse.fromJson(message));
    } else if (message['voteResult'] != null) {
      // GameVoteResultResponse - 투표 결과
      _handleVoteResult(GameVoteResultResponse.fromJson(message));
    } else if (message['senderNumber'] != null && message['massageReference'] == 'USER') {
      // GameChatMessageResponse - 사용자 채팅
      _handleChatMessage(GameChatMessageResponse.fromJson(message));
    } else if (message['content'] != null && message['massageReference'] == 'SERVER') {
      // 서버 메시지 (게임 시작, 페이즈 변경 알림 등)
      _handleServerMessage(message);
    } else {
      print('Unknown message format: $message');
    }
  }
  
  void _handlePhaseChange(GamePhaseChangeResponse response) {
    if (!mounted) return;
    
    setState(() {
      _gameState.updateFromPhaseChange(response);
      _remainingSeconds = _gameState.remainingTime;
    });
    
    // 페이즈별 처리
    switch (response.phase) {
      case 'CHAT':
        _startChatPhase();
        break;
      case 'VOTE':
        _startVotePhase();
        break;
      case 'VOTE_RESULT':
        _showVoteResult();
        break;
      case 'END':
        _endGame();
        break;
    }
  }
  
  void _handleVoteResult(GameVoteResultResponse response) {
    if (!mounted) return;
    
    setState(() {
      _gameState.updateFromVoteResult(response);
    });
    
    // 투표 결과 처리
    if (response.winnerTeam != null) {
      // 게임 종료 - 승부 결과에 따라 화면 이동
      if (response.winnerTeam == _gameState.userTeam) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const VictoryScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoseScreen()),
        );
      }
    }
  }
  
  void _handleChatMessage(GameChatMessageResponse response) {
    if (!mounted) return;
    
    setState(() {
      _messages.add(ChatMessage(
        text: response.content,
        isMe: response.senderNumber == _userNumber,
        playerNumber: response.senderNumber == _userNumber ? null : response.senderNumber,
      ));
    });
    
    // 메시지 추가 후 스크롤
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
  
  // 서버 메시지 처리 (게임 시작, 페이즈 변경 알림 등)
  void _handleServerMessage(Map<String, dynamic> message) {
    if (!mounted) return;
    
    final content = message['content'] as String?;
    print('Server message: $content');
    
    // 서버 메시지를 채팅에 표시
    setState(() {
      _messages.add(ChatMessage(
        text: '[서버] $content',
        isMe: false,
        playerNumber: null,
        isServerMessage: true,
      ));
    });
    
    // 메시지 추가 후 스크롤
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
  
  void _startChatPhase() {
    // 채팅 페이즈 시작
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          timer.cancel();
        }
      });
    });
  }
  
  void _startVotePhase() {
    // 투표 페이즈 시작
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          timer.cancel();
        }
      });
    });
  }
  
  void _showVoteResult() {
    // 투표 결과 표시
    _timer?.cancel();
  }
  
  void _endGame() {
    // 게임 종료
    _timer?.cancel();
  }

  Widget _buildHeader() {
    const Color purple = Color(0xFF8F2AB0);
    
    return Stack(
      alignment: Alignment.center,
      children: [
        // 보라색 상단 바
        Container(
          height: 72,
          width: double.infinity,
          color: purple,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 왼쪽 공간 (로고는 Stack에서 독립적으로 배치)
              // const SizedBox(width: 140), // 로고 공간 확보
              const Spacer(),
              // 플레이어 정보
              Row(
                children: [
                  const Text(
                    '1번',
                    style: TextStyle(
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
        // 왼쪽 로고 (독립적으로 배치)
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
        // 중앙 타이머
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
          // 주제
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
          // 플레이어 구성
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
          mainAxisAlignment: message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isMe) ...[
              // 플레이어 아이콘과 번호
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
          // 메시지 버블
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
                style: TextStyle(
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

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty && _roomId != null) {
      // STOMP를 통해 채팅 메시지 전송
      _stompService.sendChatMessage(
        roomId: _roomId!,
        content: _messageController.text.trim(),
        senderNumber: _userNumber,
      );
      
      _messageController.clear();
    }
  }

  void _showGameIntroDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // 5초 카운트다운 시작 (다이얼로그가 열릴 때만)
            if (_countdownTimer == null) {
              _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
                setDialogState(() {
                  if (_countdownSeconds > 1) {
                    _countdownSeconds--;
                  } else {
                    _countdownTimer?.cancel();
                    _countdownTimer = null;
                    Navigator.of(context).pop();
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
                  // 게임 아이콘
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
                  // 게임 제목
                  const Text(
                    'Bluffing',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8F2AB0),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 게임 설명
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
                  // 카운트다운 진행 표시
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8F2AB0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '자동으로 게임이 시작됩니다...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF8F2AB0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _startGame() {
    // 3분 타이머 시작
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




  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _timer?.cancel();
    _countdownTimer?.cancel();
    _countdownTimer = null;
    
    // STOMP 연결 정리
    _messageSubscription?.cancel();
    _stompService.disconnect();
    
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isMe;
  final int? playerNumber;
  final bool isSystem;
  final bool isServerMessage;

  ChatMessage({
    required this.text,
    required this.isMe,
    this.playerNumber,
    this.isSystem = false,
    this.isServerMessage = false,
  });
}
