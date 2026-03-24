import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/csv_helper.dart';
import '../utils/utils.dart'; // 新增

class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({super.key});

  Future<void> _importCSV(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null) return;

    final file = result.files.first;
    if (file.path == null) return;

    final content = await File(file.path!).readAsString();

    List<Item>? importedItems;
    try {
      importedItems = CsvHelper.parseCSV(content);
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'CSV格式错误: $e');
      }
      return;
    }

    final overwrite = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入模式'),
        content: const Text('选择“覆盖”将清空现有数据，选择“追加”将合并数据（重复ID会生成新ID）。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('追加'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('覆盖', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (overwrite == null) return;

    try {
      if (overwrite) {
        await CsvHelper.overwriteAllItems(importedItems!);
      } else {
        await CsvHelper.appendItems(importedItems!);
      }
      if (context.mounted) {
        showSnackBar(context, '导入成功');
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, '导入失败: $e');
      }
    }
  }

  Future<void> _exportCSV(BuildContext context) async {
    try {
      final items = await CsvHelper.readAllItems();
      final csvContent = CsvHelper.itemsToCSV(items);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/export_items.csv');
      await file.writeAsString(csvContent);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '断舍离物品清单',
      );
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, '导出失败: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // 移除 DrawerHeader
            ListTile(
              leading: const Icon(Icons.file_upload_outlined),
              title: const Text('导入 CSV'),
              onTap: () => _importCSV(context),
            ),
            ListTile(
              leading: const Icon(Icons.file_download_outlined),
              title: const Text('导出 CSV'),
              onTap: () => _exportCSV(context),
            ),
          ],
        ),
      ),
    );
  }
}