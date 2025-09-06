// ✅ [수정] dart.async -> dart:async 오타 수정
import 'dart:async';
import 'package:bluffing_frontend/services/api_service.dart';
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
  bool _isMatching = false;
  Timer? _timer;
  int _countdown = 5;

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
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      // 5초의 타임아웃 설정
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

  void _startMatching() {
    setState(() {
      _isMatching = true;
      _countdown = 5;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const ChatScreen(),
          ),
        );
      }
    });
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
        const Text('매칭 중입니다...', style: TextStyle(color: Colors.white, fontSize: 18)),
        const SizedBox(height: 8),
        Text('0:0$_countdown', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: LinearProgressIndicator(
            value: _countdown / 5.0,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
      ],
    );
  }
}