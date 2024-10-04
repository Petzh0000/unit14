import 'package:flutter/material.dart';
import 'package:varit14/pages/add_page.dart';
import 'package:varit14/pages/list_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'บทที่ 14',
      debugShowCheckedModeBanner: false,
      home: ListPage(),
    );
  }
}
