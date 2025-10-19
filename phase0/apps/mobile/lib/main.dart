import 'package:flutter/material.dart';
import 'src/home_page.dart';

void main() {
  runApp(const XxxApp());
}

class XxxApp extends StatelessWidget {
  const XxxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'APP XXX',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
