import 'package:flutter/material.dart';
import '../utils/csv_helper.dart';
import 'item_input_page.dart';
import 'archived_list_page.dart';
import '../widgets/expandable_item_card.dart';

class ItemListPage extends StatefulWidget {
  const ItemListPage({super.key});

  @override
  State<ItemListPage> createState() => _ItemListPageState();
}

class _ItemListPageState extends State<ItemListPage> {
  List<Item> _items = [];
  bool _isLoading = true;
  String? _expandedItemId;

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
    if (item.costMode == 'count') return null;

    final now = DateTime.now();
    final days = now.difference(buyDate).inDays;
    final divisor = days <= 0 ? 1 : days;
    final perDay = price / divisor;

    return '日均：¥${perDay.toStringAsFixed(2)}/天';
  }

  String? _perUseCostText(Item item) {
    if (item.costMode != 'count') return null;
    final price = _tryParsePrice(item.price);
    if (price == null) return null;
    final divisor = item.useCount <= 0 ? 1 : item.useCount;
    final perUse = price / divisor;
    return '单次：¥${perUse.toStringAsFixed(2)}/次';
  }

  Future<void> _setUseCount(Item item, int useCount) async {
    final next = Item(
      id: item.id,
      emoji: item.emoji,
      name: item.name,
      price: item.price,
      buyDate: item.buyDate,
      archived: item.archived,
      costMode: item.costMode,
      useCount: useCount < 0 ? 0 : useCount,
    );

    try {
      await CsvHelper.updateItem(next);
      _loadItems();
    } catch (e) {
      _showSnackBar('更新次数失败：$e');
    }
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

  void _toggleExpanded(String itemId) {
    setState(() {
      _expandedItemId = (_expandedItemId == itemId) ? null : itemId;
    });
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
                final isExpanded = _expandedItemId == item.id;
                return ExpandableItemCard(
                  isExpanded: isExpanded,
                  onToggle: () => _toggleExpanded(item.id),
                  leading: Text(item.emoji, style: const TextStyle(fontSize: 32)),
                  title: item.name,
                  subtitle: [
                    '¥${item.price} | 购买日期：${item.buyDate}',
                    if (_dailyCostText(item) != null) _dailyCostText(item)!,
                    if (_perUseCostText(item) != null) _perUseCostText(item)!,
                  ].join('  ·  '),
                  actionBar: Row(
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () async {
                          final changed = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ItemInputPage(item: item)),
                          );
                          if (changed == true) {
                            _loadItems();
                          }
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('编辑'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonalIcon(
                        onPressed: () async {
                          await _archiveItem(item.id);
                        },
                        icon: const Icon(Icons.archive_outlined),
                        label: const Text('归档'),
                      ),
                      if (item.costMode == 'count') ...[
                        const Spacer(),
                        IconButton(
                          tooltip: '减少次数',
                          onPressed: () => _setUseCount(item, item.useCount - 1),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          '${item.useCount}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        IconButton(
                          tooltip: '增加次数',
                          onPressed: () => _setUseCount(item, item.useCount + 1),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}