import 'package:bluffing_frontend/screens/home_screen.dart';
import 'package:bluffing_frontend/screens/signup_screen.dart';
import 'package:bluffing_frontend/services/api_service.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    print("로그인 버튼 눌림! _handleLogin 함수 시작.");

    if (_isLoading) {
      print("로딩 중이므로 로그인 요청을 중단합니다.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final accessToken = await ApiService.login(
      _idController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (accessToken != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(accessToken: accessToken)),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => const ErrorDialog(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF8A2BE2);
    // 그라데이션 색상은 이제 사용되지 않습니다.
    // const gradientStartColor = Color(0xFFD4B9FF);
    // const gradientEndColor = Color(0xFFE9D8FF);

    return Scaffold(
      body: Stack( // ✅ [수정] Stack 위젯으로 변경하여 배경 이미지 위에 UI를 올립니다.
        fit: StackFit.expand,
        children: [
          // ✅ [추가] 배경 이미지
          Image.asset(
            'assets/login_background.png', // ✅ [수정] 배경 이미지 파일 경로
            fit: BoxFit.cover,
          ),
          // ✅ [수정] 기존 Container의 내용은 Stack의 자식으로 옮겨집니다.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                    Center(child: Image.asset('assets/logo.png', width: 200)),
                    const SizedBox(height: 60),

                    _buildTextField(label: '아이디', controller: _idController),
                    const SizedBox(height: 20),

                    _buildTextField(label: '비밀번호', controller: _passwordController, isObscure: true),
                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _handleLogin,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0))),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('로그인',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('계정이 없으신가요?',
                            style: TextStyle(color: Colors.grey.shade600)),
                        TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen()));
                          },
                          child: const Text('회원가입',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, color: Colors.black)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool isObscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 16)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isObscure,
          decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none),
              contentPadding:
              const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0)),
        ),
      ],
    );
  }
}

class ErrorDialog extends StatelessWidget {
  const ErrorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF8A2BE2);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '로그인에 실패하였습니다',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              '아이디와 비밀번호를 확인해주세요!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0))),
                child: const Text(
                  '확인',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}