import 'package:flutter/material.dart';
import 'pages/item_list_page.dart';

// 断舍离APP入口
void main() {
  runApp(const DeclutterApp());
}

class DeclutterApp extends StatelessWidget {
  const DeclutterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '断舍离APP',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        cardTheme: const CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
          ),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          color: Colors.white,
        ),
      ),
      home: const ItemListPage(),
    );
  }
}