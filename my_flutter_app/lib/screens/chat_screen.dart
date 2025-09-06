import 'package:flutter/material.dart';
import 'dart:async';
import 'victory_screen.dart';
import 'lose_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

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
  int? _selectedPlayer;
  final List<int> _players = [2, 3, 4, 5, 6]; // 1번은 현재 플레이어이므로 제외
  
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
    // 게임 시작 다이얼로그 표시
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showGameIntroDialog();
    });
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
    if (_messageController.text.trim().isNotEmpty) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: _messageController.text.trim(),
            isMe: true,
            playerNumber: null,
          ),
        );
        _messageController.clear();
      });
      
      // 메시지 추가 후 가장 아래로 스크롤
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

  void _endGame() {
    // 투표 다이얼로그 표시
    _showVoteDialog();
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
                    // 투표 안내 텍스트 (검정색 배경)
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
                    // 플레이어 선택 카드들 (흰색 배경)
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 첫 번째 행 (2개 카드)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildVoteCard(0, setDialogState),
                                  const SizedBox(width: 10),
                                  _buildVoteCard(1, setDialogState),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // 두 번째 행 (3개 카드)
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
                    // 투표 대기 메시지와 버튼 (흰색 배경)
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
                          // 투표 버튼
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
            // 아이콘 영역 (흰색 배경)
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
                    // 플레이어 아이콘
                    Center(
                      child: Image.asset(
                        'assets/voteCardIcon.png',
                        height: 50,
                        width: 50,
                        fit: BoxFit.contain,
                      ),
                    ),
                    // 선택된 경우 체크마크
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
            // 번호 영역 (검은색 배경)
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

  void _submitVote() {
    if (_selectedPlayer != null) {
      // 다이얼로그 닫기
      Navigator.of(context).pop();
      // 패배 화면으로 이동
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _timer?.cancel();
    _countdownTimer?.cancel();
    _countdownTimer = null;
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isMe;
  final int? playerNumber;
  final bool isSystem;

  ChatMessage({
    required this.text,
    required this.isMe,
    this.playerNumber,
    this.isSystem = false,
  });
}
