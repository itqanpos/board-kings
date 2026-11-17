import 'package:flutter/material.dart';
import 'ludo_screen.dart';

void main() {
  runApp(const BoardKingsApp());
}

class BoardKingsApp extends StatelessWidget {
  const BoardKingsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BOARD KINGS — Ludo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.amber,
        scaffoldBackgroundColor: const Color(0xFF1E1E2C),
      ),
      home: const LudoScreen(),
    );
  }
}
