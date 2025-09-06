// ✅ [수정] dart.async -> dart:async 오타 수정
import 'dart:async';
import '../services/api_service.dart';
import '../services/token_service.dart';
import '../services/stomp_service.dart';
import '../services/game_api_service.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/join_game_card.dart';
import '../widgets/user_profile_card.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StompService _stompService = StompService.instance;
  bool _isMatching = false;
  String? _roomId;
  int? _userNumber;
  StreamSubscription? _messageSubscription;

  bool _isLoading = true;
  String _userName = "로딩 중...";
  int _winRate = 0;
  int _wins = 0;
  int _losses = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserProfile();
    });
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _stompService.disconnect();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final token = await TokenService.instance.getAccessToken();
      if (token == null) {
        print('No access token available for user profile');
        return;
      }
      
      // 5초의 타임아웃 설정
      final results = await Future.wait([
        ApiService.getUserSummary(token),
        ApiService.getUserRecord(token),
      ]).timeout(const Duration(seconds: 5));

      final summary = results[0] as UserSummary?;
      final record = results[1] as UserRecord?;

      if (mounted) {
        setState(() {
          _userName = summary?.name ?? "사용자";
          if (record != null && record.gameCount > 0) {
            _wins = record.winCount;
            _losses = record.lossCount;
            _winRate = ((record.winCount / record.gameCount) * 100).toInt();
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      // 에러 발생 또는 타임아웃 시
      print("프로필 로딩 실패: $e");
      if (mounted) {
        setState(() {
          _userName = "정보 로딩 실패";
          _isLoading = false; // 에러가 나도 로딩은 끝내야 함
        });
      }
    }
  }

  void _startMatching() async {
    setState(() {
      _isMatching = true;
    });

    // 바로 매칭 시작
    _startActualMatching();
  }

  Future<void> _startActualMatching() async {
    try {
      print('🚀 매칭 프로세스 시작');
      
      // 1. STOMP 연결
      print('🔗 STOMP 연결 시도 중...');
      final connected = await _stompService.connect(
        baseUrl: 'ws://ec2-13-125-117-232.ap-northeast-2.compute.amazonaws.com:8080/ws'
      );
      
      if (!connected) {
        print('❌ STOMP 연결 실패');
        _showErrorDialog('연결에 실패했습니다. 다시 시도해주세요.');
        return;
      }
      print('✅ STOMP 연결 성공!');

      // 2. 매칭 알림 구독
      print('🔔 매칭 알림 구독 시작...');
      await _stompService.subscribeToMatchNotification();
      
      // 3. 메시지 스트림 구독
      print('📡 메시지 스트림 구독 시작...');
      _messageSubscription = _stompService.messageStream.listen(_handleMessage);
      
      // 4. 매칭 요청 (STOMP 방식)
      print('🎮 게임 매칭 요청 전송 (STOMP)...');
      await _stompService.sendMatchRequest();
      print('✅ 매칭 요청 전송 완료! 매칭 결과 대기 중...');
    } catch (e) {
      print('❌ 매칭 중 오류 발생: $e');
      _showErrorDialog('매칭 중 오류가 발생했습니다: $e');
    }
  }

  // 매칭 결과 처리
  void _handleMessage(Map<String, dynamic> message) {
    if (message['userRoomNumber'] != null && message['team'] != null) {
      // GameMatchedResponse - 매칭 완료
      _handleMatchResult(GameMatchedResponse.fromJson(message));
    }
  }

  // 매칭 결과 처리
  void _handleMatchResult(GameMatchedResponse response) {
    if (!mounted) return;
    
    print('🎉 매칭 완료!');
    print('🆔 방 번호: ${response.userRoomNumber}');
    print('👥 팀: ${response.team}');
    print('🎂 나이: ${response.userAge}');
    print('🏠 시민팀 나이: ${response.citizenTeamAgeList}');
    print('🕵️ 마피아팀 나이: ${response.mafiaTeamAge}');
    
    // 사용자 정보 저장
    _userNumber = response.userRoomNumber;
    _roomId = '11111111-2222-3333-4444-555555555555'; // 임시 방 ID
    
    print('🚀 채팅 화면으로 이동 중...');
    
    // 채팅 화면으로 이동
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          roomId: _roomId!,
          userNumber: _userNumber!,
        ),
      ),
    );
  }

  // 에러 다이얼로그
  void _showErrorDialog(String message) {
    if (!mounted) return;
    
    setState(() {
      _isMatching = false;
    });
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/home_background.png',
            fit: BoxFit.cover,
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: CustomAppBar(userName: _userName),
            body: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : Column(
              children: [
                const SizedBox(height: 20),
                UserProfileCard(
                  userName: _userName,
                  winRate: _winRate,
                  wins: _wins,
                  losses: _losses,
                ),
                const JoinGameCard(),
                const Spacer(flex: 1),
                _isMatching
                    ? _buildMatchingIndicator()
                    : _buildGameStartButton(),
                const Spacer(flex: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameStartButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed: _startMatching,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.yellow[700],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          child: const Text(
            '게임 시작',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
      ),
    );
  }

  Widget _buildMatchingIndicator() {
    return Column(
      children: [
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          strokeWidth: 3,
        ),
        const SizedBox(height: 16),
        const Text(
          '매칭 중입니다...',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        const SizedBox(height: 8),
        const Text(
          '잠시만 기다려주세요...',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }
}