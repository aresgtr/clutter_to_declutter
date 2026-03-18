import 'dart:io';

import 'package:path_provider/path_provider.dart';

class Item {
  final String id;
  final String emoji;
  final String name;
  final String price;
  final String buyDate;
  final bool archived;
  // 成本模式：day=按天（默认），count=按次数
  final String costMode;
  // 使用次数（仅costMode=count时有意义）
  final int useCount;

  Item({
    required this.id,
    required this.emoji,
    required this.name,
    required this.price,
    required this.buyDate,
    this.archived = false,
    this.costMode = 'day',
    this.useCount = 0,
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
      'costMode': costMode,
      'useCount': useCount.toString(),
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
      costMode: (map['costMode'] ?? 'day').toString(),
      useCount: int.tryParse((map['useCount'] ?? '0').toString()) ?? 0,
    );
  }
}

// csv工具类（负责读写物品数据）
class CsvHelper {
  static const _header = 'id,emoji,name,price,buyDate,archived,costMode,useCount\n';

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

    // 兼容迁移：旧版本缺列则自动补齐
    final lines = await file.readAsLines();
    if (lines.isEmpty) {
      await file.writeAsString(_header);
      return;
    }

    final firstLine = lines.first.trim();
    if (!firstLine.contains('archived') || !firstLine.contains('costMode') || !firstLine.contains('useCount')) {
      final migrated = <String>[];
      migrated.add(_header.trimRight());

      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final parts = line.split(',');

        // 旧格式1：id,emoji,name,price,buyDate
        if (parts.length == 5) {
          migrated.add('$line,0,day,0');
          continue;
        }

        // 旧格式2：id,emoji,name,price,buyDate,archived
        if (parts.length == 6) {
          migrated.add('$line,day,0');
          continue;
        }

        // 已经是新格式（或更长），尽量保留原行
        migrated.add(line);
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
        '${item.id},${item.emoji},${_escapeComma(item.name)},${item.price},${item.buyDate},${item.archived ? '1' : '0'},${item.costMode},${item.useCount}',
      );
    }
    await file.writeAsString(buffer.toString());
  }

  // 读取所有物品（启动app时加载）
  //
  // 为了避免第三方CSV解析在不同行尾/编码下的兼容问题，这里改为手动解析：
  // - 按行拆分
  // - 跳过表头
  // - 每一行按逗号切成8列（archived,costMode,useCount）
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
          costMode: parts.length >= 7 ? parts[6] : 'day',
          useCount: parts.length >= 8 ? (int.tryParse(parts[7]) ?? 0) : 0,
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
        '${item.id},${item.emoji},${_escapeComma(item.name)},${item.price},${item.buyDate},${item.archived ? '1' : '0'},${item.costMode},${item.useCount}\n';
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
                  costMode: item.costMode,
                  useCount: item.useCount,
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
