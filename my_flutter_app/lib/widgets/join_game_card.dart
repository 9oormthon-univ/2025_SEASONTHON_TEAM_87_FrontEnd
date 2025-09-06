import 'package:flutter/material.dart';

class JoinGameCard extends StatelessWidget {
  const JoinGameCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          const Text(
            '다양한 세대와 함께 즐겨보세요!',
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // TODO: 'assets/people_illustration.png' 경로에 실제 이미지 파일을 넣어주세요.
          Image.asset('assets/people.png'),
        ],
      ),
    );
  }
}