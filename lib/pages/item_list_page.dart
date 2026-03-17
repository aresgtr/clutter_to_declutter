import 'package:flutter/material.dart';
import '../utils/csv_helper.dart';
import 'item_input_page.dart';
import 'archived_list_page.dart';

class ItemListPage extends StatefulWidget {
  const ItemListPage({super.key});

  @override
  State<ItemListPage> createState() => _ItemListPageState();
}

class _ItemListPageState extends State<ItemListPage> {
  List<Item> _items = [];
  bool _isLoading = true;

  DateTime? _tryParseBuyDate(String raw) {
    final text = raw.trim();
    if (text.isEmpty || text == '未填写') return null;

    // 期望格式：YYYY-M-D（录入页就是这么存的）
    final parts = text.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;

    try {
      return DateTime(y, m, d);
    } catch (_) {
      return null;
    }
  }

  double? _tryParsePrice(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    final value = double.tryParse(text);
    if (value == null || value <= 0) return null;
    return value;
  }

  String? _dailyCostText(Item item) {
    final price = _tryParsePrice(item.price);
    final buyDate = _tryParseBuyDate(item.buyDate);
    if (price == null || buyDate == null) return null;

    final now = DateTime.now();
    final days = now.difference(buyDate).inDays;
    final divisor = days <= 0 ? 1 : days;
    final perDay = price / divisor;

    return '日均：¥${perDay.toStringAsFixed(2)}/天';
  }

  @override
  void initState() {
    super.initState();
    // 启动时加载CSV中的所有商品
    _loadItems();
  }

  // 加载商品数据
  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final items = await CsvHelper.readAllItems();
      setState(() {
        _items = items.where((e) => !e.archived).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('加载失败：$e');
    }
  }

  // 归档商品（软删除）
  Future<void> _archiveItem(String itemId) async {
    try {
      await CsvHelper.setArchived(itemId, true);
      _showSnackBar('已归档');
      // 重新加载列表
      _loadItems();
    } catch (e) {
      _showSnackBar('归档失败：$e');
    }
  }

  // 显示提示
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的物品清单'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '归档箱',
            icon: const Icon(Icons.archive_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ArchivedListPage()),
              );
              _loadItems();
            },
          ),
        ],
      ),
      // 浮动添加按钮（右下角）
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 跳转到录入页，返回后无论结果如何都刷新列表，避免因返回值异常导致不刷新
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ItemInputPage()),
          );
          _loadItems();
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
      body: _buildBody(),
    );
  }

  // 构建页面主体
  Widget _buildBody() {
    // 加载中
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Center(
            child: Text(
              '你一共拥有 ${_items.length} 件物品',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (_items.isEmpty)
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('暂无商品', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 16),
                  Text('点击右下角+号添加你的第一个商品吧～', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                // 左滑归档（软删除）
                return Dismissible(
                  key: Key(item.id), // 唯一key
                  direction: DismissDirection.endToStart, // 从右向左滑
                  background: Container(
                    color: Colors.blueGrey,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Icon(Icons.archive, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    // 清单页的“删除” = 归档，不需要确认
                    await _archiveItem(item.id);
                    return true;
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
                        [
                          '¥${item.price} | 购买日期：${item.buyDate}',
                          if (_dailyCostText(item) != null) _dailyCostText(item)!,
                        ].join('  ·  '),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}