import 'package:flutter/material.dart';
import 'package:hatopro_01/screens/home_screen.dart';
import 'theme.dart';

void main() {
  runApp(const HatoNaviApp());
}

class HatoNaviApp extends StatelessWidget {
  const HatoNaviApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'はとナビおつかいクエスト',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: HomeScreen(),
    );
  }
}