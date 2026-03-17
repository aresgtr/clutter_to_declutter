import 'package:flutter/material.dart';

import '../utils/csv_helper.dart';

class ArchivedListPage extends StatefulWidget {
  const ArchivedListPage({super.key});

  @override
  State<ArchivedListPage> createState() => _ArchivedListPageState();
}

class _ArchivedListPageState extends State<ArchivedListPage> {
  List<Item> _items = [];
  bool _isLoading = true;

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
      ),
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

        return Dismissible(
          key: Key('archived-${item.id}'),
          direction: DismissDirection.horizontal,
          background: Container(
            color: Colors.teal,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Icon(Icons.unarchive, color: Colors.white),
          ),
          secondaryBackground: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Icon(Icons.delete_forever, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              await _unarchive(item.id);
              return false;
            }

            final ok = await _confirmPermanentDelete();
            if (ok) {
              await _deletePermanently(item.id);
            }
            return ok;
          },
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            elevation: 2,
            child: ListTile(
              leading: Text(item.emoji, style: const TextStyle(fontSize: 32)),
              title: Text(
                item.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                '¥${item.price} | 购买日期：${item.buyDate}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ),
        );
      },
    );
  }
}

