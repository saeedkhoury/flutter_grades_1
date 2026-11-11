import 'package:flutter/material.dart';

import 'package:flutter_grades_1/screens/grades_screen.dart';

void main() {
  runApp(const GradesApp());
}

class GradesApp extends StatelessWidget {
  const GradesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ציונים',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const GradesScreen(),
    );
  }
}
