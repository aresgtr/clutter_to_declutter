import 'package:flutter/material.dart';
// 导入录入页（确保路径正确）
import 'pages/item_input_page.dart';

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
      // 适配新版Flutter的CardThemeData
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
      home: const HomePage(),
    );
  }
}

// 首页组件
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('断舍离 · 从杂乱到整洁')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '断舍离 · 从杂乱到整洁',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ItemInputPage()),
                );
              },
              // 关键修复：新版Flutter把fontSize放到textStyle里
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                // 字体大小不再直接传，而是嵌套到textStyle中
                textStyle: const TextStyle(
                  fontSize: 18, // 原来的fontSize移到这里
                  fontWeight: FontWeight.normal, // 可选：配置字体粗细
                ),
              ),
              child: const Text('开始录入物品'),
            ),
          ],
        ),
      ),
    );
  }
}