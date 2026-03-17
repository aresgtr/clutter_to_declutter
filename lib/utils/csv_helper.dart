import 'dart:io';

import 'package:path_provider/path_provider.dart';

class Item {
  final String id;
  final String emoji;
  final String name;
  final String price;
  final String buyDate;
  final bool archived;

  Item({
    required this.id,
    required this.emoji,
    required this.name,
    required this.price,
    required this.buyDate,
    this.archived = false,
  });

  // 写入csv
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'emoji': emoji,
      'name': name,
      'price': price,
      'buyDate': buyDate,
      'archived': archived ? '1' : '0',
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
      archived: map['archived'] == '1' || map['archived'] == 1 || map['archived'] == true,
    );
  }
}

// csv工具类（负责读写物品数据）
class CsvHelper {
  static const _header = 'id,emoji,name,price,buyDate,archived\n';

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
      await file.writeAsString(_header);
      return;
    }

    // 兼容迁移：旧版本没有 archived 列，则自动补齐
    final lines = await file.readAsLines();
    if (lines.isEmpty) {
      await file.writeAsString(_header);
      return;
    }

    final firstLine = lines.first.trim();
    if (!firstLine.contains('archived')) {
      final migrated = <String>[];
      migrated.add(_header.trimRight());

      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        // 旧格式：id,emoji,name,price,buyDate
        migrated.add('$line,0');
      }

      await file.writeAsString('${migrated.join('\n')}\n');
    }
  }

  static Future<void> _writeAllItems(List<Item> items) async {
    final path = await _getCsvFilePath();
    final file = File(path);
    final buffer = StringBuffer()..write(_header);
    for (final item in items) {
      buffer.writeln(
        '${item.id},${item.emoji},${_escapeComma(item.name)},${item.price},${item.buyDate},${item.archived ? '1' : '0'}',
      );
    }
    await file.writeAsString(buffer.toString());
  }

  // 读取所有物品（启动app时加载）
  //
  // 为了避免第三方CSV解析在不同行尾/编码下的兼容问题，这里改为手动解析：
  // - 按行拆分
  // - 跳过表头
  // - 每一行按逗号切成6列（最后一列 archived：0/1）
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
          archived: parts.length >= 6 ? (parts[5] == '1') : false,
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
        '${item.id},${item.emoji},${_escapeComma(item.name)},${item.price},${item.buyDate},${item.archived ? '1' : '0'}\n';
    await file.writeAsString(csvRow, mode: FileMode.append);
  }

  // 归档/取消归档：标记 archived，不做物理删除
  static Future<void> setArchived(String itemId, bool archived) async {
    final allItem = await readAllItems();
    final updated = allItem
        .map(
          (item) => item.id == itemId
              ? Item(
                  id: item.id,
                  emoji: item.emoji,
                  name: item.name,
                  price: item.price,
                  buyDate: item.buyDate,
                  archived: archived,
                )
              : item,
        )
        .toList();
    await _writeAllItems(updated);
  }

  // 永久删除：从CSV中移除该行（不可恢复）
  static Future<void> deletePermanently(String itemId) async {
    final allItem = await readAllItems();
    final filteredItems = allItem.where((item) => item.id != itemId).toList();
    await _writeAllItems(filteredItems);
  }

  // 更新物品信息（保持 archived 状态）
  static Future<void> updateItem(Item updatedItem) async {
    final allItem = await readAllItems();
    bool replaced = false;

    final updated = allItem.map((item) {
      if (item.id != updatedItem.id) return item;
      replaced = true;
      return updatedItem;
    }).toList();

    if (!replaced) {
      updated.add(updatedItem);
    }

    await _writeAllItems(updated);
  }

  // 辅助：转义逗号（避免商品名含逗号导致csv格式错误）
  static String _escapeComma(String text) {
    return text.replaceAll(',', '，'); // 替换为中文逗号
  }
}
