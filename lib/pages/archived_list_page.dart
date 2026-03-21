import 'package:flutter/material.dart';

import '../utils/csv_helper.dart';
import '../widgets/expandable_item_card.dart';
import '../widgets/settings_drawer.dart';  // 新增导入

class ArchivedListPage extends StatefulWidget {
  const ArchivedListPage({super.key});

  @override
  State<ArchivedListPage> createState() => _ArchivedListPageState();
}

class _ArchivedListPageState extends State<ArchivedListPage> {
  List<Item> _items = [];
  bool _isLoading = true;
  String? _expandedItemId;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final items = await CsvHelper.readAllItems();
      setState(() {
        _items = items.where((e) => e.archived).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('加载失败：$e');
    }
  }

  void _toggleExpanded(String itemId) {
    setState(() {
      _expandedItemId = (_expandedItemId == itemId) ? null : itemId;
    });
  }

  Future<void> _deletePermanently(String itemId) async {
    try {
      await CsvHelper.deletePermanently(itemId);
      _showSnackBar('已永久删除');
      _loadItems();
    } catch (e) {
      _showSnackBar('删除失败：$e');
    }
  }

  Future<void> _unarchive(String itemId) async {
    try {
      await CsvHelper.setArchived(itemId, false);
      _showSnackBar('已移回清单');
      _loadItems();
    } catch (e) {
      _showSnackBar('操作失败：$e');
    }
  }

  Future<bool> _confirmPermanentDelete() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认永久删除'),
        content: const Text('永久删除后无法恢复，是否继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('永久删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ??
        false;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('归档箱'),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const SettingsDrawer(),  // 新增抽屉
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('归档箱为空', style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 16),
            Text('在清单页左滑即可归档物品', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        final isExpanded = _expandedItemId == item.id;

        return ExpandableItemCard(
          isExpanded: isExpanded,
          onToggle: () => _toggleExpanded(item.id),
          leading: Text(item.emoji, style: const TextStyle(fontSize: 24)),
          title: Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
          subtitle: const SizedBox.shrink(),
          actionBar: Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: () async {
                  await _unarchive(item.id);
                },
                icon: const Icon(Icons.unarchive_outlined),
                label: const Text('恢复'),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: () async {
                  final ok = await _confirmPermanentDelete();
                  if (ok) {
                    await _deletePermanently(item.id);
                  }
                },
                icon: const Icon(Icons.delete_forever_outlined),
                label: const Text('永久删除'),
              ),
            ],
          ),
        );
      },
    );
  }
}