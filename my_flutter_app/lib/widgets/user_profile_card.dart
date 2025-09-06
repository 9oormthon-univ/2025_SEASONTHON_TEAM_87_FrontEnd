import 'package:flutter/material.dart';

class UserProfileCard extends StatelessWidget {
  final String userName;
  final int winRate;
  final int wins;
  final int losses;

  const UserProfileCard({
    super.key,
    required this.userName,
    required this.winRate,
    required this.wins,
    required this.losses,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          _buildInfoBox(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$userName님,',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                const Text(
                  '반갑습니다!',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildInfoBox(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '승률 $winRate%',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${wins}승 • ${losses}패',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox({required Widget child}) {
    return Expanded(
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: child,
      ),
    );
  }
}