import 'package:bluffing_frontend/services/api_service.dart';
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
  final List<String> _years = List.generate(100, (index) => (DateTime.now().year - index).toString());
  final List<String> _months = List.generate(12, (index) => (index + 1).toString().padLeft(2, '0'));
  final List<String> _days = List.generate(31, (index) => (index + 1).toString().padLeft(2, '0'));

  // ✅ [다시 추가] 로딩 및 상태 관리 변수
  bool _isLoading = false;
  bool _isIdChecked = false; // 아이디 중복 확인을 했는지 여부
  bool _isIdAvailable = false; // 아이디가 사용 가능한지 여부

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ✅ [다시 추가] 아이디 중복 확인 로직
  Future<void> _handleCheckId() async {
    if (_idController.text.isEmpty) {
      _showSnackBar('아이디를 입력해주세요.');
      return;
    }

    final isAvailable = await ApiService.checkIdAvailability(_idController.text);
    // 위젯이 아직 화면에 있는지 확인
    if (!mounted) return;

    setState(() {
      _isIdChecked = true;
      _isIdAvailable = isAvailable;
    });

    if (isAvailable) {
      _showSnackBar('사용 가능한 아이디입니다.');
    } else {
      _showSnackBar('이미 사용 중인 아이디입니다.');
    }
  }

  // ✅ [수정] 회원가입 로직에 중복 확인 검사 추가
  Future<void> _handleSignup() async {
    // 1. 유효성 검사
    if (_nameController.text.isEmpty ||
        _idController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _selectedYear == null || _selectedMonth == null || _selectedDay == null) {
      _showErrorDialog('모든 필드를 입력해주세요.');
      return;
    }
    if (!_isIdChecked || !_isIdAvailable) { // 중복 확인을 통과했는지 검사
      _showErrorDialog('아이디 중복 확인을 해주세요.');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorDialog('비밀번호가 일치하지 않습니다.');
      return;
    }

    // 2. 로딩 상태 시작 및 API 호출
    setState(() { _isLoading = true; });

    final String birthDate = '$_selectedYear-$_selectedMonth-$_selectedDay';

    final String? errorMessage = await ApiService.signup(
      name: _nameController.text,
      birth: birthDate,
      loginId: _idController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() { _isLoading = false; });

    // 3. 결과 처리
    if (errorMessage == null) {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('회원가입 성공'),
            content: const Text('로그인 화면으로 이동합니다.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('확인'),
              )
            ],
          ));
    } else {
      _showErrorDialog(errorMessage);
    }
  }

  // UI 피드백을 위한 헬퍼 함수
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('알림'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          )
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6A1B9A);

    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('회원가입', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 40),

                _buildTextFieldSection(label: '이름', controller: _nameController, hintText: '이름을 입력하세요'),
                _buildBirthDateSection(),
                // ✅ [수정] 아이디 섹션 위젯 변경
                _buildIdSection(primaryColor),
                _buildTextFieldSection(label: '비밀번호', controller: _passwordController, hintText: '비밀번호를 입력하세요', isObscure: true),
                _buildTextFieldSection(label: '비밀번호 확인', controller: _confirmPasswordController, hintText: '비밀번호를 다시 입력하세요', isObscure: true),
                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _handleSignup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('확인', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('계정이 있으신가요?', style: TextStyle(color: Colors.grey)),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('로그인', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
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

  Widget _buildTextFieldSection({
    required String label,
    required TextEditingController controller,
    required String hintText,
    bool isObscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isObscure,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ✅ [다시 추가] 아이디 입력 + 중복확인 버튼 섹션 위젯
  Widget _buildIdSection(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('아이디', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _idController,
                onChanged: (value) {
                  // 아이디를 수정하면, '중복 확인' 상태를 초기화
                  if (_isIdChecked) {
                    setState(() {
                      _isIdChecked = false;
                    });
                  }
                },
                decoration: InputDecoration(
                  hintText: '아이디를 입력하세요',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _handleCheckId, // 중복확인 함수 연결
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primaryColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              ),
              child: Text('중복확인', style: TextStyle(color: primaryColor)),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBirthDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('생년월일', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildDropdownButton(
              hint: 'YYYY', value: _selectedYear, items: _years,
              onChanged: (value) => setState(() => _selectedYear = value),
            ),
            const SizedBox(width: 10),
            _buildDropdownButton(
              hint: 'MM', value: _selectedMonth, items: _months,
              onChanged: (value) => setState(() => _selectedMonth = value),
            ),
            const SizedBox(width: 10),
            _buildDropdownButton(
              hint: 'DD', value: _selectedDay, items: _days,
              onChanged: (value) => setState(() => _selectedDay = value),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

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