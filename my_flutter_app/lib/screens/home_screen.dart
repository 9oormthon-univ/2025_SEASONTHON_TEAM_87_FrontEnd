import 'dart:async';
import 'package:bluffing_frontend/services/api_service.dart';
import 'package:bluffing_frontend/services/game_service.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/join_game_card.dart';
import '../widgets/user_profile_card.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  final String accessToken;
  const HomeScreen({super.key, required this.accessToken});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GameService _gameService = GameService();
  bool _isMatching = false;
  String _matchingStatusText = "매칭 중입니다...";

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
    // ✅ STOMP 클라이언트를 안전하게 관리 - ChatScreen에서 계속 사용해야 함
    _gameService.safeDeactivate(force: false); // 연결 유지
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final results = await Future.wait([
        ApiService.getUserSummary(widget.accessToken),
        ApiService.getUserRecord(widget.accessToken),
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
      print("프로필 로딩 실패: $e");
      if (mounted) {
        setState(() {
          _userName = "정보 로딩 실패";
          _isLoading = false;
        });
      }
    }
  }

  void _startMatching() {
    setState(() {
      _isMatching = true;
      _matchingStatusText = "매칭 서버에 연결 중...";
    });

    _gameService.startMatching(
      accessToken: widget.accessToken,
      onRequested: () {
        if (mounted) {
          setState(() {
            _matchingStatusText = "다른 플레이어를 기다리는 중...";
          });
        }
      },
      onSuccess: (response) {
        if (mounted) {
          print("최종 매칭 성공! 채팅 화면으로 이동합니다.");
          // ✅ [수정] ChatScreen으로 매칭 데이터를 전달합니다.
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                matchData: response,
                accessToken: widget.accessToken,
              ),
            ),
          );
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isMatching = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("매칭 실패: $error")),
          );
        }
      },
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
                const SizedBox(height: 100),
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
        Text(_matchingStatusText,
            style: const TextStyle(color: Colors.white, fontSize: 18)),
        const SizedBox(height: 20),
        const CircularProgressIndicator(
          color: Colors.white,
        ),
      ],
    );
  }
}