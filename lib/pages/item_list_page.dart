import 'package:flutter/material.dart';
import '../utils/csv_helper.dart';
import 'item_input_page.dart';
import 'archived_list_page.dart';
import '../widgets/expandable_item_card.dart';
import '../widgets/settings_drawer.dart';
import '../utils/utils.dart';

enum SortOption {
  nameAsc,
  priceAsc,
  priceDesc,
  daysAsc,
  daysDesc,
  recentAdd,
  purchaseDateAsc,
  purchaseDateDesc,
  dailyCostAsc,
  dailyCostDesc,
}

class ItemListPage extends StatefulWidget {
  const ItemListPage({super.key});

  @override
  State<ItemListPage> createState() => _ItemListPageState();
}

class _ItemListPageState extends State<ItemListPage> {
  List<Item> _allItems = [];
  List<Item> _items = [];
  bool _isLoading = true;
  String? _expandedItemId;

  String _searchKeyword = '';
  String? _selectedCategory;
  double? _minPrice;
  double? _maxPrice;
  SortOption _sortOption = SortOption.nameAsc;

  static const Color _accent = Color(0xFF2F3A34);
  static const Color _lightText = Color(0xFF6B665D);
  static const Color _borderColor = Color(0xFFE6E1D8);

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadItems();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchKeyword = _searchController.text.trim();
      _applyFiltersAndSort();
    });
  }

  int? _getDaysSincePurchase(Item item) {
    final buyDate = parseDate(item.buyDate);
    if (buyDate == null) return null;
    return DateTime.now().difference(buyDate).inDays;
  }

  double? _getDailyCostValue(Item item) {
    if (item.costMode == 'count') return null;
    final price = parsePrice(item.price);
    final buyDate = parseDate(item.buyDate);
    if (price == null || buyDate == null) return null;
    final days = DateTime.now().difference(buyDate).inDays;
    if (days <= 0) return price;
    return price / days;
  }

  void _applyFiltersAndSort() {
    try {
      List<Item> filtered = List.from(_allItems);

      if (_searchKeyword.isNotEmpty) {
        filtered = filtered.where((item) =>
            item.name.toLowerCase().contains(_searchKeyword.toLowerCase())).toList();
      }

      if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
        filtered = filtered.where((item) {
          final parts = item.category.split(':');
          return parts.isNotEmpty && parts[0] == _selectedCategory;
        }).toList();
      }

      if (_minPrice != null) {
        filtered = filtered.where((item) {
          final price = parsePrice(item.price);
          return price != null && price >= _minPrice!;
        }).toList();
      }
      if (_maxPrice != null) {
        filtered = filtered.where((item) {
          final price = parsePrice(item.price);
          return price != null && price <= _maxPrice!;
        }).toList();
      }

      switch (_sortOption) {
        case SortOption.nameAsc:
          filtered.sort((a, b) => a.name.compareTo(b.name));
          break;
        case SortOption.priceAsc:
          filtered.sort((a, b) {
            final pa = parsePrice(a.price) ?? 0.0;
            final pb = parsePrice(b.price) ?? 0.0;
            return pa.compareTo(pb);
          });
          break;
        case SortOption.priceDesc:
          filtered.sort((a, b) {
            final pa = parsePrice(a.price) ?? 0.0;
            final pb = parsePrice(b.price) ?? 0.0;
            return pb.compareTo(pa);
          });
          break;
        case SortOption.daysAsc:
          filtered.sort((a, b) {
            final da = _getDaysSincePurchase(a);
            final db = _getDaysSincePurchase(b);
            if (da == null && db == null) return 0;
            if (da == null) return 1;
            if (db == null) return -1;
            return da.compareTo(db);
          });
          break;
        case SortOption.daysDesc:
          filtered.sort((a, b) {
            final da = _getDaysSincePurchase(a);
            final db = _getDaysSincePurchase(b);
            if (da == null && db == null) return 0;
            if (da == null) return 1;
            if (db == null) return -1;
            return db.compareTo(da);
          });
          break;
        case SortOption.recentAdd:
          filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case SortOption.purchaseDateAsc:
          filtered.sort((a, b) {
            final da = parseDate(a.buyDate);
            final db = parseDate(b.buyDate);
            if (da == null && db == null) return 0;
            if (da == null) return 1;
            if (db == null) return -1;
            return da.compareTo(db);
          });
          break;
        case SortOption.purchaseDateDesc:
          filtered.sort((a, b) {
            final da = parseDate(a.buyDate);
            final db = parseDate(b.buyDate);
            if (da == null && db == null) return 0;
            if (da == null) return 1;
            if (db == null) return -1;
            return db.compareTo(da);
          });
          break;
        case SortOption.dailyCostAsc:
          filtered.sort((a, b) {
            final ca = _getDailyCostValue(a);
            final cb = _getDailyCostValue(b);
            if (ca == null && cb == null) return 0;
            if (ca == null) return 1;
            if (cb == null) return -1;
            return ca.compareTo(cb);
          });
          break;
        case SortOption.dailyCostDesc:
          filtered.sort((a, b) {
            final ca = _getDailyCostValue(a);
            final cb = _getDailyCostValue(b);
            if (ca == null && cb == null) return 0;
            if (ca == null) return 1;
            if (cb == null) return -1;
            return cb.compareTo(ca);
          });
          break;
      }

      setState(() {
        _items = filtered;
      });
    } catch (e) {
      showSnackBar(context, '排序失败: $e');
    }
  }

  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('排序方式', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              _buildSortOptionTile('默认（名称升序）', SortOption.nameAsc),
              _buildSortOptionTile('价格升序', SortOption.priceAsc),
              _buildSortOptionTile('价格降序', SortOption.priceDesc),
              _buildSortOptionTile('使用天数升序', SortOption.daysAsc),
              _buildSortOptionTile('使用天数降序', SortOption.daysDesc),
              _buildSortOptionTile('最近添加', SortOption.recentAdd),
              _buildSortOptionTile('购买时间升序', SortOption.purchaseDateAsc),
              _buildSortOptionTile('购买时间降序', SortOption.purchaseDateDesc),
              _buildSortOptionTile('每日成本升序', SortOption.dailyCostAsc),
              _buildSortOptionTile('每日成本降序', SortOption.dailyCostDesc),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOptionTile(String title, SortOption option) {
    return ListTile(
      title: Text(title),
      trailing: _sortOption == option ? const Icon(Icons.check, color: _accent) : null,
      onTap: () {
        setState(() {
          _sortOption = option;
          _applyFiltersAndSort();
        });
        Navigator.pop(context);
      },
    );
  }

  void _showCategoryMenu() {
    final Set<String> categories = {};
    for (final item in _allItems) {
      final parts = item.category.split(':');
      if (parts.isNotEmpty && parts[0].isNotEmpty) {
        categories.add(parts[0]);
      }
    }
    final categoryList = categories.toList()..sort();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('选择分类', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                title: const Text('全部'),
                trailing: _selectedCategory == null ? const Icon(Icons.check, color: _accent) : null,
                onTap: () {
                  setState(() {
                    _selectedCategory = null;
                    _applyFiltersAndSort();
                  });
                  Navigator.pop(context);
                },
              ),
              ...categoryList.map((cat) => ListTile(
                title: Text(cat),
                trailing: _selectedCategory == cat ? const Icon(Icons.check, color: _accent) : null,
                onTap: () {
                  setState(() {
                    _selectedCategory = cat;
                    _applyFiltersAndSort();
                  });
                  Navigator.pop(context);
                },
              )),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showPriceRangeDialog() {
    final TextEditingController minController = TextEditingController(text: _minPrice?.toString() ?? '');
    final TextEditingController maxController = TextEditingController(text: _maxPrice?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('价格区间'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: minController,
                decoration: const InputDecoration(labelText: '最低价（元）', hintText: '不限'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: maxController,
                decoration: const InputDecoration(labelText: '最高价（元）', hintText: '不限'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final min = minController.text.trim().isEmpty ? null : double.tryParse(minController.text);
                final max = maxController.text.trim().isEmpty ? null : double.tryParse(maxController.text);
                setState(() {
                  _minPrice = min;
                  _maxPrice = max;
                  _applyFiltersAndSort();
                });
                Navigator.pop(context);
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  // ========== 辅助方法（使用工具类） ==========
  double _totalValue() {
    double sum = 0;
    for (final item in _items) {
      final price = parsePrice(item.price);
      if (price != null) sum += price;
    }
    return sum;
  }

  String? _dailyCostText(Item item) {
    final price = parsePrice(item.price);
    final buyDate = parseDate(item.buyDate);
    if (price == null || buyDate == null) return null;
    if (item.costMode == 'count') return null;
    final days = DateTime.now().difference(buyDate).inDays;
    final divisor = days <= 0 ? 1 : days;
    final perDay = price / divisor;
    return '¥${perDay.toStringAsFixed(2)}/天';
  }

  String? _perUseCostText(Item item) {
    if (item.costMode != 'count') return null;
    final price = parsePrice(item.price);
    if (price == null) return null;
    final divisor = item.useCount <= 0 ? 1 : item.useCount;
    final perUse = price / divisor;
    return '¥${perUse.toStringAsFixed(2)}/次';
  }

  String _priceText(Item item) {
    final price = parsePrice(item.price);
    if (price == null) return '';
    return '¥${price.toStringAsFixed(2)}';
  }

  String _dateText(Item item) {
    final date = parseDate(item.buyDate);
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
      category: item.category,
      createdAt: item.createdAt,
    );

    try {
      await CsvHelper.updateItem(next);
      _loadItems();
    } catch (e) {
      showSnackBar(context, '更新次数失败：$e');
    }
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final items = await CsvHelper.readAllItems();
      setState(() {
        _allItems = items.where((e) => !e.archived).toList();
        _isLoading = false;
      });
      _applyFiltersAndSort();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      showSnackBar(context, '加载失败：$e');
    }
  }

  Future<void> _archiveItem(String itemId) async {
    try {
      await CsvHelper.setArchived(itemId, true);
      showSnackBar(context, '已归档');
      _loadItems();
    } catch (e) {
      showSnackBar(context, '归档失败：$e');
    }
  }

  void _toggleExpanded(String itemId) {
    setState(() {
      _expandedItemId = (_expandedItemId == itemId) ? null : itemId;
    });
  }
  // ==========================================

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
      drawer: const SettingsDrawer(),
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2), // 进一步缩小垂直内边距
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: _borderColor),
              bottom: BorderSide(color: _borderColor),
            ),
            color: const Color(0xFFFAF9F7),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: 160, // 略微缩小宽度
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: '搜索名称',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), // 进一步减小
                      isDense: true,
                      prefixIcon: const Icon(Icons.search, size: 18),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _applyFiltersAndSort(),
                  ),
                ),
                const SizedBox(width: 4), // 减小间距
                OutlinedButton(
                  onPressed: _showSortMenu,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), // 进一步减小
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_getSortButtonText()),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, size: 18),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                OutlinedButton(
                  onPressed: _showCategoryMenu,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_getCategoryButtonText()),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, size: 18),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                OutlinedButton(
                  onPressed: _showPriceRangeDialog,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_getPriceRangeText()),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, size: 18),
                    ],
                  ),
                ),
              ],
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
                                color: _lightText,
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
                            style: const TextStyle(color: _lightText),
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

  String _getSortButtonText() {
    switch (_sortOption) {
      case SortOption.nameAsc:
        return '默认排序';
      case SortOption.priceAsc:
        return '价格升序';
      case SortOption.priceDesc:
        return '价格降序';
      case SortOption.daysAsc:
        return '使用天数升序';
      case SortOption.daysDesc:
        return '使用天数降序';
      case SortOption.recentAdd:
        return '最近添加';
      case SortOption.purchaseDateAsc:
        return '购买时间升序';
      case SortOption.purchaseDateDesc:
        return '购买时间降序';
      case SortOption.dailyCostAsc:
        return '每日成本升序';
      case SortOption.dailyCostDesc:
        return '每日成本降序';
    }
  }

  String _getCategoryButtonText() {
    if (_selectedCategory == null) return '全部类别';
    return _selectedCategory!;
  }

  String _getPriceRangeText() {
    if (_minPrice != null && _maxPrice != null) {
      return '¥${_minPrice!.toStringAsFixed(0)}-${_maxPrice!.toStringAsFixed(0)}';
    } else if (_minPrice != null) {
      return '≥¥${_minPrice!.toStringAsFixed(0)}';
    } else if (_maxPrice != null) {
      return '≤¥${_maxPrice!.toStringAsFixed(0)}';
    }
    return '价格范围';
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