import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

class Item {
  final String id;
  final String emoji;
  final String name;
  final String price;
  final String buyDate;

  Item({
    required this.id,
    required this.emoji,
    required this.name,
    required this.price,
    required this.buyDate,
  });

  // 写入csv
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'emoji': emoji,
      'name': name,
      'price': price,
      'buyDate': buyDate,
    };
  }

  // 读取csv
  static Item fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'] ?? '',
      emoji: map['emoji'] ?? '📦', // 默认emoji
      name: map['name'] ?? '',
      price: map['price'] ?? '',
      buyDate: map['buyDate'] ?? '',
    );
  }
}

// csv工具类（负责读写物品数据）
class CsvHelper {
  // 获取csv文件路径（安卓本地存储）
  static Future<String> _getCsvFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/items.csv';
  }

  // 初始化csv
  static Future<void> initCsvFile() async {
    final path = await _getCsvFilePath();
    final file = File(path);
    if (!await file.exists()) {
      // csv表头
      await file.writeAsString('id,emoji,name,price,buyDate\n');
    }
  }

  // 读取所有物品（启动app时加载）
  //
  // 为了避免第三方CSV解析在不同行尾/编码下的兼容问题，这里改为手动解析：
  // - 按行拆分
  // - 跳过表头
  // - 每一行按逗号切成5列
  static Future<List<Item>> readAllItems() async {
    await initCsvFile();
    final path = await _getCsvFilePath();
    final file = File(path);
    final lines = await file.readAsLines();

    final items = <Item>[];

    // 没有数据或只有表头
    if (lines.length <= 1) {
      return items;
    }

    // 从第二行开始解析
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final parts = line.split(',');
      if (parts.length < 5) continue;

      items.add(
        Item(
          id: parts[0],
          emoji: parts[1],
          name: parts[2],
          price: parts[3],
          buyDate: parts[4],
        ),
      );
    }

    return items;
  }

  // 添加商品到csv
  static Future<void> addItem(Item item) async {
    await initCsvFile();
    final path = await _getCsvFilePath();
    final file = File(path);

    // 拼接csv行（注意转义逗号，避免格式错误）
    final csvRow =
        '${item.id},${item.emoji},${_escapeComma(item.name)},${item.price},${item.buyDate}\n';
    await file.writeAsString(csvRow, mode: FileMode.append);
  }

  // 删除指定ID的商品（重新写入所有数据，删除目标行）
  static Future<void> deleteItem(String itemId) async {
    final allItem = await readAllItems();
    final filteredItems = allItem.where((item) => item.id != itemId).toList();

    // 重新写入csv（先写表头，再写过滤后的数据）
    final path = await _getCsvFilePath();
    final file = File(path);
    String newCsvContent = 'id,emoji,name,price,buyDate\n';
    for (final item in filteredItems) {
      newCsvContent +=
          '${item.id},${item.emoji},${_escapeComma(item.name)},${item.price},${item.buyDate}\n';
    }
    await file.writeAsString(newCsvContent);
  }

  // 辅助：转义逗号（避免商品名含逗号导致csv格式错误）
  static String _escapeComma(String text) {
    return text.replaceAll(',', '，'); // 替换为中文逗号
  }
}
