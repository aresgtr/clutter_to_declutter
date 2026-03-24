import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class Item {
  final String id;
  final String emoji;
  final String name;
  final String price;
  final String buyDate;
  final bool archived;
  final String costMode;
  final int useCount;
  final String category;

  Item({
    required this.id,
    required this.emoji,
    required this.name,
    required this.price,
    required this.buyDate,
    this.archived = false,
    this.costMode = 'day',
    this.useCount = 0,
    this.category = '',
  });

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
      'category': category,
    };
  }

  static Item fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'] ?? '',
      emoji: map['emoji'] ?? '📦',
      name: map['name'] ?? '',
      price: map['price'] ?? '',
      buyDate: map['buyDate'] ?? '',
      archived: map['archived'] == '1' || map['archived'] == 1 || map['archived'] == true,
      costMode: (map['costMode'] ?? 'day').toString(),
      useCount: int.tryParse((map['useCount'] ?? '0').toString()) ?? 0,
      category: map['category'] ?? '',
    );
  }
}

class CsvHelper {
  static const _header = 'id,emoji,name,price,buyDate,archived,costMode,useCount,category\n';

  static Future<String> _getCsvFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/items.csv';
  }

  static Future<void> initCsvFile() async {
    final path = await _getCsvFilePath();
    final file = File(path);
    if (!await file.exists()) {
      await file.writeAsString(_header);
      return;
    }

    final lines = await file.readAsLines();
    if (lines.isEmpty) {
      await file.writeAsString(_header);
      return;
    }

    final firstLine = lines.first.trim();
    if (!firstLine.contains('category')) {
      final migrated = <String>[];
      migrated.add(_header.trimRight());

      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final parts = line.split(',');

        if (parts.length == 5) {
          migrated.add('$line,0,day,0,');
          continue;
        }
        if (parts.length == 6) {
          migrated.add('$line,day,0,');
          continue;
        }
        if (parts.length == 8) {
          migrated.add('$line,');
          continue;
        }
        if (parts.length == 9) {
          migrated.add(line);
        } else {
          migrated.add(line);
        }
      }

      await file.writeAsString('${migrated.join('\n')}\n');
      return;
    }
  }

  static Future<void> _writeAllItems(List<Item> items) async {
    final path = await _getCsvFilePath();
    final file = File(path);
    final buffer = StringBuffer()..write(_header);
    for (final item in items) {
      buffer.writeln(
        '${item.id},${item.emoji},${_escapeComma(item.name)},${item.price},${item.buyDate},${item.archived ? '1' : '0'},${item.costMode},${item.useCount},${_escapeComma(item.category)}',
      );
    }
    await file.writeAsString(buffer.toString());
  }

  static Future<List<Item>> readAllItems() async {
    await initCsvFile();
    final path = await _getCsvFilePath();
    final file = File(path);
    final lines = await file.readAsLines();

    final items = <Item>[];
    if (lines.length <= 1) return items;

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
          category: parts.length >= 9 ? parts[8] : '',
        ),
      );
    }
    return items;
  }

  static Future<void> addItem(Item item) async {
    await initCsvFile();
    final path = await _getCsvFilePath();
    final file = File(path);
    final csvRow =
        '${item.id},${item.emoji},${_escapeComma(item.name)},${item.price},${item.buyDate},${item.archived ? '1' : '0'},${item.costMode},${item.useCount},${_escapeComma(item.category)}\n';
    await file.writeAsString(csvRow, mode: FileMode.append);
  }

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
        category: item.category,
      )
          : item,
    )
        .toList();
    await _writeAllItems(updated);
  }

  static Future<void> deletePermanently(String itemId) async {
    final allItem = await readAllItems();
    final filteredItems = allItem.where((item) => item.id != itemId).toList();
    await _writeAllItems(filteredItems);
  }

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

  static String _escapeComma(String text) {
    return text.replaceAll(',', '，');
  }

  // ========== 导入导出方法 ==========

  static List<Item> parseCSV(String content) {
    final lines = content.split('\n');
    if (lines.isEmpty) throw Exception('文件为空');

    // 检查表头（兼容有/无 category）
    final header = lines.first.trim();
    if (!header.startsWith('id,emoji,name,price,buyDate,archived,costMode,useCount')) {
      throw Exception('CSV格式不正确，缺少表头或列名不符');
    }

    final items = <Item>[];
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final parts = line.split(',');
      // 允许8列（无category）或9列（有category）
      if (parts.length < 8) {
        throw Exception('第 ${i+1} 行列数不足8');
      }

      final id = parts[0];
      if (id.isEmpty) throw Exception('第 ${i+1} 行ID为空');

      final emoji = parts[1];
      final name = parts[2];
      final price = parts[3];
      if (double.tryParse(price) == null) {
        throw Exception('第 ${i+1} 行价格格式错误');
      }

      final buyDate = parts[4];
      if (buyDate != '未填写') {
        final partsDate = buyDate.split('-');
        if (partsDate.length != 3) throw Exception('第 ${i+1} 行日期格式错误');
        final y = int.tryParse(partsDate[0]);
        final m = int.tryParse(partsDate[1]);
        final d = int.tryParse(partsDate[2]);
        if (y == null || m == null || d == null) throw Exception('第 ${i+1} 行日期格式错误');
      }

      final archived = parts[5] == '1';
      final costMode = parts[6];
      if (costMode != 'day' && costMode != 'count') {
        throw Exception('第 ${i+1} 行成本模式错误');
      }

      final useCount = int.tryParse(parts[7]);
      if (useCount == null || useCount < 0) {
        throw Exception('第 ${i+1} 行使用次数错误');
      }

      final category = parts.length >= 9 ? parts[8] : '';

      items.add(Item(
        id: id,
        emoji: emoji,
        name: name,
        price: price,
        buyDate: buyDate,
        archived: archived,
        costMode: costMode,
        useCount: useCount,
        category: category,
      ));
    }
    return items;
  }

  static String itemsToCSV(List<Item> items) {
    final buffer = StringBuffer();
    buffer.writeln(_header.trimRight());
    for (final item in items) {
      buffer.writeln(
        '${item.id},${item.emoji},${_escapeComma(item.name)},${item.price},${item.buyDate},${item.archived ? '1' : '0'},${item.costMode},${item.useCount},${_escapeComma(item.category)}',
      );
    }
    return buffer.toString();
  }

  static Future<void> overwriteAllItems(List<Item> items) async {
    await _writeAllItems(items);
  }

  static Future<void> appendItems(List<Item> newItems) async {
    final existing = await readAllItems();
    final existingIds = existing.map((e) => e.id).toSet();
    final uuid = const Uuid();
    final itemsToAdd = newItems.map((item) {
      if (existingIds.contains(item.id)) {
        return Item(
          id: uuid.v4(),
          emoji: item.emoji,
          name: item.name,
          price: item.price,
          buyDate: item.buyDate,
          archived: item.archived,
          costMode: item.costMode,
          useCount: item.useCount,
          category: item.category,
        );
      }
      return item;
    }).toList();
    final allItems = [...existing, ...itemsToAdd];
    await _writeAllItems(allItems);
  }
}