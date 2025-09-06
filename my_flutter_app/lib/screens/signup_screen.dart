import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // 각 입력 필드를 제어하기 위한 컨트롤러
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // 생년월일 Dropdown을 위한 변수
  String? _selectedYear;
  String? _selectedMonth;
  String? _selectedDay;

  // Dropdown 메뉴 아이템 리스트 생성
  final List<String> _years =
  List.generate(100, (index) => (DateTime.now().year - index).toString());
  final List<String> _months = List.generate(12, (index) => (index + 1).toString().padLeft(2, '0'));
  final List<String> _days = List.generate(31, (index) => (index + 1).toString().padLeft(2, '0'));

  @override
  void dispose() {
    // 위젯이 제거될 때 컨트롤러를 정리합니다.
    _nameController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 디자인에 사용된 기본 보라색 정의
    const primaryColor = Color(0xFF6A1B9A); // 약간 더 진한 보라색으로 조정

    return Scaffold(
      // ✅ 키보드가 올라오거나 화면이 작을 때 UI가 잘리지 않도록 스크롤 기능을 추가합니다.
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '회원가입',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),

                // 이름 입력 섹션
                _buildTextFieldSection(
                  label: '이름',
                  controller: _nameController,
                  hintText: '이름을 입력하세요',
                ),

                // 생년월일 입력 섹션
                _buildBirthDateSection(),

                // 아이디 입력 섹션
                _buildIdSection(primaryColor),

                // 비밀번호 입력 섹션
                _buildTextFieldSection(
                  label: '비밀번호',
                  controller: _passwordController,
                  hintText: '비밀번호를 입력하세요',
                  isObscure: true,
                ),

                // 비밀번호 확인 섹션
                _buildTextFieldSection(
                  label: '비밀번호 확인',
                  controller: _confirmPasswordController,
                  hintText: '비밀번호를 다시 입력하세요',
                  isObscure: true,
                ),
                const SizedBox(height: 40),

                // 확인 버튼
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: 회원가입 로직 구현
                      print('회원가입 정보 확인');
                      print('이름: ${_nameController.text}');
                      print('아이디: ${_idController.text}');
                      print('생년월일: $_selectedYear-$_selectedMonth-$_selectedDay');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 로그인 링크
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('계정이 있으신가요?', style: TextStyle(color: Colors.grey)),
                    TextButton(
                      onPressed: () {
                        // TODO: 로그인 화면으로 이동
                      },
                      child: const Text(
                        '로그인',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 반복되는 텍스트 필드 섹션을 만드는 헬퍼 위젯
  Widget _buildTextFieldSection({
    required String label,
    required TextEditingController controller,
    required String hintText,
    bool isObscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isObscure,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // 아이디 입력 + 중복확인 버튼 섹션
  Widget _buildIdSection(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '아이디',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _idController,
                decoration: InputDecoration(
                  hintText: '아이디를 입력하세요',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {
                // TODO: 아이디 중복 확인 로직 구현
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              ),
              child: Text(
                '중복확인',
                style: TextStyle(color: primaryColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // 생년월일 Dropdown 섹션
  Widget _buildBirthDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '생년월일',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildDropdownButton(
              hint: 'YYYY',
              value: _selectedYear,
              items: _years,
              onChanged: (value) {
                setState(() {
                  _selectedYear = value;
                });
              },
            ),
            const SizedBox(width: 10),
            _buildDropdownButton(
              hint: 'MM',
              value: _selectedMonth,
              items: _months,
              onChanged: (value) {
                setState(() {
                  _selectedMonth = value;
                });
              },
            ),
            const SizedBox(width: 10),
            _buildDropdownButton(
              hint: 'DD',
              value: _selectedDay,
              items: _days,
              onChanged: (value) {
                setState(() {
                  _selectedDay = value;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // 반복되는 DropdownButton을 만드는 헬퍼 위젯
  Widget _buildDropdownButton({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            hint: Text(hint, style: TextStyle(color: Colors.grey[500])),
            value: value,
            isExpanded: true,
            items: items.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}