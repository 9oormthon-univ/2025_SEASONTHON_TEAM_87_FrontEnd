import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String userName;

  const CustomAppBar({
    super.key,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    // 이미지에 사용된 색상과 유사하게 텍스트/아이콘 색상 지정
    const Color appBarContentColor = Color(0xFF6A1B9A);

    return AppBar(
      // Scaffold의 배경 이미지가 보이도록 AppBar 배경을 투명하게 설정
      backgroundColor: Colors.white,   //transparent < 투명버전
      elevation: 0, // AppBar 아래의 그림자 제거

      // 로고 이미지를 왼쪽에 배치
      title: Image.asset(
        'assets/logo.png', // assets 폴더에 있는 로고 이미지 경로
        height: 100, // AppBar 높이에 맞는 적절한 크기로 조절
      ),
      centerTitle: false, // title을 왼쪽 정렬로 변경

      actions: [
        // 오른쪽 사용자 정보 섹션
        Row(
          children: [
            Text(
              userName,
              style: const TextStyle(
                color: appBarContentColor, // 색상 적용
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.account_circle_outlined, // 외곽선만 있는 아이콘으로 변경
              color: appBarContentColor, // 색상 적용
              size: 28,
            ),
            const SizedBox(width: 4),
            // 노란색 점 추가
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.yellow,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16), // 오른쪽 끝 여백
          ],
        )
      ],
    );
  }

  // AppBar의 표준 높이를 반환
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}


///
///import 'package:flutter/material.dart';
//
// class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
//   final String userName;
//
//   const CustomAppBar({
//     super.key,
//     required this.userName,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return AppBar(
//       backgroundColor: Colors.transparent, // 배경 투명
//       elevation: 0, // 그림자 제거
//       title: Text(
//         'Bluffing',
//         style: TextStyle(
//           color: Colors.white,
//           fontWeight: FontWeight.bold,
//           fontSize: 24,
//         ),
//       ),
//       actions: [
//         Row(
//           children: [
//             Text(
//               userName,
//               style: const TextStyle(color: Colors.white, fontSize: 16),
//             ),
//             const SizedBox(width: 8),
//             const Icon(
//               Icons.account_circle,
//               color: Colors.white,
//               size: 28,
//             ),
//             const SizedBox(width: 16),
//           ],
//         )
//       ],
//     );
//   }
//
//   @override
//   Size get preferredSize => const Size.fromHeight(kToolbarHeight);
// }
