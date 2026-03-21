import 'package:flutter/material.dart';
import '../utils/csv_helper.dart';
import 'item_input_page.dart';
import 'archived_list_page.dart';
import '../widgets/expandable_item_card.dart';
import '../widgets/settings_drawer.dart';  // 新增导入

class ItemListPage extends StatefulWidget {
  const ItemListPage({super.key});

  @override
  State<ItemListPage> createState() => _ItemListPageState();
}

class _ItemListPageState extends State<ItemListPage> {
  List<Item> _items = [];
  bool _isLoading = true;
  String? _expandedItemId;

  static const Color _accent = Color(0xFF2F3A34); // 深墨绿：断舍离高级感

  double _totalValue() {
    double sum = 0;
    for (final item in _items) {
      final price = _tryParsePrice(item.price);
      if (price != null) {
        sum += price;
      }
    }
    return sum;
  }

  DateTime? _tryParseBuyDate(String raw) {
    final text = raw.trim();
    if (text.isEmpty || text == '未填写') return null;

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

    return '¥${perDay.toStringAsFixed(2)}/天';
  }

  String? _perUseCostText(Item item) {
    if (item.costMode != 'count') return null;
    final price = _tryParsePrice(item.price);
    if (price == null) return null;
    final divisor = item.useCount <= 0 ? 1 : item.useCount;
    final perUse = price / divisor;
    return '¥${perUse.toStringAsFixed(2)}/次';
  }

  String _priceText(Item item) {
    final price = _tryParsePrice(item.price);
    if (price == null) return '';
    return '¥${price.toStringAsFixed(2)}';
  }

  String _dateText(Item item) {
    final date = _tryParseBuyDate(item.buyDate);
    if (date == null) return '';
    return '${date.year}-${date.month}-${date.day}';
  }

  String _costLineText(Item item) {
    return _dailyCostText(item) ?? _perUseCostText(item) ?? '';
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
    _loadItems();
  }

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

  Future<void> _archiveItem(String itemId) async {
    try {
      await CsvHelper.setArchived(itemId, true);
      _showSnackBar('已归档');
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
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
      drawer: const SettingsDrawer(),  // 新增抽屉
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ItemInputPage()),
          );
          _loadItems();
        },
        backgroundColor: const Color(0xFFF5F3EE),
        foregroundColor: _accent,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _accent.withValues(alpha: 0.22)),
        ),
        child: const Icon(Icons.add, size: 28),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: _StatsCard(
            itemCount: _items.length,
            totalValue: _totalValue(),
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final isExpanded = _expandedItemId == item.id;
                final costText = _costLineText(item);
                return ExpandableItemCard(
                  isExpanded: isExpanded,
                  onToggle: () => _toggleExpanded(item.id),
                  leading: Text(item.emoji, style: const TextStyle(fontSize: 24)),
                  title: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: _priceText(item).isEmpty ? 1 : 2,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            item.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      if (_priceText(item).isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              _priceText(item),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B665D),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: costText.isEmpty
                            ? const SizedBox.shrink()
                            : FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            costText,
                            style: const TextStyle(color: Color(0xFF6B665D)),
                          ),
                        ),
                      ),
                      if (_dateText(item).isNotEmpty)
                        Text(
                          _dateText(item),
                          style: const TextStyle(fontSize: 12, color: Color(0xFF9E9A92)),
                        ),
                    ],
                  ),
                  actionBar: Row(
                    children: [
                      FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          minimumSize: const Size(0, 36),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        onPressed: () async {
                          final changed = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ItemInputPage(item: item)),
                          );
                          if (changed == true) {
                            _loadItems();
                          }
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('编辑'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          minimumSize: const Size(0, 36),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        onPressed: () async {
                          await _archiveItem(item.id);
                        },
                        icon: const Icon(Icons.archive_outlined, size: 18),
                        label: const Text('归档'),
                      ),
                      if (item.costMode == 'count') ...[
                        const Spacer(),
                        IconButton(
                          tooltip: '减少次数',
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                          onPressed: () => _setUseCount(item, item.useCount - 1),
                          icon: const Icon(Icons.remove_circle_outline, size: 22),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${item.useCount}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          tooltip: '增加次数',
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                          onPressed: () => _setUseCount(item, item.useCount + 1),
                          icon: const Icon(Icons.add_circle_outline, size: 22),
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

class _StatsCard extends StatelessWidget {
  final int itemCount;
  final double totalValue;

  const _StatsCard({
    required this.itemCount,
    required this.totalValue,
  });

  @override
  Widget build(BuildContext context) {
    const accent = _ItemListPageState._accent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFF5F3EE),
        border: Border.all(color: const Color(0xFFE6E1D8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _Metric(
            icon: Icons.inventory_2_outlined,
            label: '物品总数',
            value: '$itemCount',
            accent: accent,
          ),
          const SizedBox(width: 16),
          Container(
            width: 1,
            height: 42,
            color: const Color(0xFFD8D2C7),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _Metric(
              icon: Icons.payments_outlined,
              label: '总价值',
              value: '¥${totalValue.toStringAsFixed(2)}',
              valueAlignEnd: true,
              accent: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool valueAlignEnd;
  final Color accent;

  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
    this.valueAlignEnd = false,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withValues(alpha: 0.16)),
          ),
          child: Icon(icon, color: accent.withValues(alpha: 0.95), size: 18),
        ),
        const SizedBox(width: 10),
        Flexible(
          fit: FlexFit.loose,
          child: Column(
            crossAxisAlignment: valueAlignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF6B665D),
                  fontSize: 12,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: valueAlignEnd ? Alignment.centerRight : Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Color(0xFF1F1F1B),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}