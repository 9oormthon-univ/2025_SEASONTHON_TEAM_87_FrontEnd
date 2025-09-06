import 'package:flutter/material.dart';
import 'chat_screen.dart';

void main() {
  runApp(const BluffingGameApp());
}

class BluffingGameApp extends StatelessWidget {
  const BluffingGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluffing Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}
