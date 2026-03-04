import 'package:flutter/material.dart';

void main() {
  runApp(const DeclutterApp());
}

// 根组件：StatelessWidget（无状态组件，适合首页）
class DeclutterApp extends StatelessWidget {
  const DeclutterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 去掉debug水印
      debugShowCheckedModeBanner: false,
      // App标题
      title: '断舍离App',
      theme: ThemeData(primarySwatch: Colors.teal),
      // 首页内容
      home: Scaffold(
        appBar: AppBar(title: const Text('断舍离 · 从杂乱到整洁')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Hello 断舍离！',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text(
                '接下来：录入物品 → 计算成本 → 归档整理',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
