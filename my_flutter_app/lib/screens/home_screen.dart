import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/join_game_card.dart';
import '../widgets/user_profile_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 화면 상태를 제어하는 변수
  bool _isMatching = false;

  // 매칭 타이머 관련 변수
  Timer? _timer;
  int _countdown = 5;

  // API에서 받아올 데이터 (임시)
  String _userName = "홍길동";
  int _winRate = 20;
  int _wins = 1;
  int _losses = 4;

  @override
  void dispose() {
    _timer?.cancel(); // 화면이 꺼질 때 타이머 정리
    super.dispose();
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
        // TODO: 매칭 완료 후 게임 화면으로 이동하는 로직 추가
        setState(() {
          _isMatching = false; // 매칭 상태 해제 (예시)
        });
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
            body: Column(
              children: [
                const SizedBox(height: 20),
                UserProfileCard(
                  userName: _userName,
                  winRate: _winRate,
                  wins: _wins,
                  losses: _losses,
                ),
                const JoinGameCard(),

                // ✅ 수정된 부분: Spacer에 flex 비율을 지정합니다.
                const Spacer(flex: 1), // 버튼 위의 공간 (비율 2)

                _isMatching
                    ? _buildMatchingIndicator()
                    : _buildGameStartButton(),

                // ✅ 수정된 부분: 버튼 아래 공간도 Spacer로 비율을 지정합니다.
                const Spacer(flex: 8), // 버튼 아래의 공간 (비율 1)
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