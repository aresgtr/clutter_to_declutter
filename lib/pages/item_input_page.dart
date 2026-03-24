import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../utils/csv_helper.dart';

// 预设常用emoji
const List<String> commonEmojis = [
  '👕', '👖', '👟', // 衣物类
  '📱', '💻', '🎧', // 电子产品类
  '📚', '🖊️', '📓', // 书籍文具类
  '🍳', '🥣', '🍶', // 厨房用品类
  '🛋️', '🧹', '🪑', // 家居类
  '📦', // 其他
];

// 分类数据
class CategoryData {
  static const Map<String, List<String>> categories = {
    '数码产品': ['手机', '平板', '笔记本电脑', '耳机', '相机', '智能手表', '充电器', '数据线', '其他'],
    '家居用品': ['家具', '床上用品', '灯具', '收纳用品', '装饰品', '清洁工具', '家用电器', '其他'],
    '厨具吧台': ['锅具', '刀具', '餐具', '杯具', '厨房小电器', '调料器具', '烘焙用具', '其他'],
    '服饰装扮': ['上衣', '裤子', '裙子', '外套', '鞋类', '配饰', '箱包', '其他'],
    '美妆护理': ['护肤品', '彩妆', '洗护用品', '香水', '美发工具', '其他'],
    '运动户外': ['运动鞋服', '健身器材', '户外装备', '球类', '瑜伽用品', '其他'],
    '图书文具': ['书籍', '笔记本', '笔类', '办公用品', '其他'],
    '玩具': ['积木拼图', '模型', '玩偶', '电子玩具', '桌游', '其他'],
    '其他': ['其他'],
  };
}

class ItemInputPage extends StatefulWidget {
  final Item? item;

  const ItemInputPage({super.key, this.item});

  @override
  State<ItemInputPage> createState() => _ItemInputPageState();
}

class _ItemInputPageState extends State<ItemInputPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  DateTime? _buyDate;
  late String _selectedEmoji;
  late String _costMode; // day / count
  late int _useCount;
  late String _category; // 分类，格式 "大类:小类"

  final _uuid = const Uuid();

  bool get _isEditMode => widget.item != null;

  @override
  void initState() {
    super.initState();

    final existing = widget.item;
    _selectedEmoji = existing?.emoji ?? '📦';
    _nameController = TextEditingController(text: existing?.name ?? '');

    final priceText = (existing?.price ?? '').trim();
    _priceController = TextEditingController(text: (priceText == '0') ? '' : priceText);

    _buyDate = _tryParseBuyDate(existing?.buyDate);
    _costMode = (existing?.costMode == 'count') ? 'count' : 'day';
    _useCount = existing?.useCount ?? 0;
    _category = existing?.category ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  DateTime? _tryParseBuyDate(String? raw) {
    final text = (raw ?? '').trim();
    if (text.isEmpty || text == '未填写') return null;
    final parts = text.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  // 打开分类选择器
  Future<void> _selectCategory() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _CategoryPicker(
          initialCategory: _category,
        );
      },
    );
    if (result != null && mounted) {
      setState(() {
        _category = '${result['main']}:${result['sub']}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? '编辑商品' : '添加商品')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. Emoji选择器
            const Text('选择商品图标', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: commonEmojis.length,
                itemBuilder: (context, index) {
                  final emoji = commonEmojis[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedEmoji = emoji;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _selectedEmoji == emoji ? Colors.teal[100] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // 2. 商品分类选择器
            GestureDetector(
              onTap: _selectCategory,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _category.isEmpty ? '选择商品分类' : _category.replaceAll(':', ' > '),
                      style: TextStyle(
                        color: _category.isEmpty ? Colors.grey[600] : Colors.black,
                        fontSize: 16,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. 成本计算方式
            Row(
              children: [
                const Expanded(
                  child: Text('成本计算方式', style: TextStyle(fontSize: 16)),
                ),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'day', label: Text('按日期')),
                    ButtonSegment(value: 'count', label: Text('按次数')),
                  ],
                  selected: {_costMode},
                  onSelectionChanged: (value) {
                    setState(() {
                      _costMode = value.first;
                      if (_costMode == 'count' && _useCount < 0) {
                        _useCount = 0;
                      }
                    });
                  },
                ),
              ],
            ),
            if (_costMode == 'count') ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('使用次数', style: TextStyle(fontSize: 16)),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _useCount = (_useCount - 1).clamp(0, 1 << 30);
                          });
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('$_useCount', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _useCount = _useCount + 1;
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ],
              ),
            ],
            // 4. 商品名称输入框
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '物品名称',
                hintText: '比如：纯棉T恤、无线耳机',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // 5. 购买价格输入框
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: '购买价格（元）',
                hintText: '比如99、299（可选）',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            // 6. 购买日期选择按钮
            ElevatedButton(
              onPressed: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _buyDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (pickedDate != null) {
                  setState(() {
                    _buyDate = pickedDate;
                  });
                }
              },
              child: Text(_buyDate == null
                  ? '选择购买日期（可选）'
                  : '购买日期：${_buyDate!.year}-${_buyDate!.month}-${_buyDate!.day}'),
            ),
            const SizedBox(height: 24),
            // 7. 保存按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveItem,
                child: Text(_isEditMode ? '保存修改' : '保存物品'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveItem() async {
    final String name = _nameController.text.trim();
    final String price = _priceController.text.trim();
    if (name.isEmpty) {
      _showSnackBar('请输入商品名称');
      return;
    }

    final String finalPrice = price.isEmpty ? '0' : price;
    final String finalBuyDate = _buyDate == null
        ? '未填写'
        : '${_buyDate!.year}-${_buyDate!.month}-${_buyDate!.day}';

    final item = Item(
      id: widget.item?.id ?? _uuid.v4(),
      emoji: _selectedEmoji,
      name: name,
      price: finalPrice,
      buyDate: finalBuyDate,
      archived: widget.item?.archived ?? false,
      costMode: _costMode,
      useCount: _costMode == 'count' ? _useCount : 0,
      category: _category,
      createdAt: widget.item?.createdAt ?? DateTime.now().toIso8601String(), // 新增：记录添加时间
    );

    try {
      if (_isEditMode) {
        await CsvHelper.updateItem(item);
        _showSnackBar('修改已保存！');
      } else {
        await CsvHelper.addItem(item);
        _showSnackBar('物品添加成功！');
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('${_isEditMode ? '保存' : '添加'}失败：$e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

// 分类选择器组件
class _CategoryPicker extends StatefulWidget {
  final String initialCategory;

  const _CategoryPicker({required this.initialCategory});

  @override
  State<_CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<_CategoryPicker> {
  late String _selectedMain;
  late String _selectedSub;

  final List<String> _mainCategories = CategoryData.categories.keys.toList();

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory.isNotEmpty) {
      final parts = widget.initialCategory.split(':');
      if (parts.length == 2 && _mainCategories.contains(parts[0])) {
        _selectedMain = parts[0];
        _selectedSub = parts[1];
      } else {
        _selectedMain = _mainCategories.first;
        _selectedSub = CategoryData.categories[_selectedMain]!.first;
      }
    } else {
      _selectedMain = _mainCategories.first;
      _selectedSub = CategoryData.categories[_selectedMain]!.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          const Text(
            '选择分类',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                // 左侧大类列表
                Expanded(
                  child: ListView.builder(
                    itemCount: _mainCategories.length,
                    itemBuilder: (context, index) {
                      final main = _mainCategories[index];
                      return ListTile(
                        title: Text(main),
                        selected: _selectedMain == main,
                        selectedTileColor: Colors.teal.withOpacity(0.1),
                        onTap: () {
                          setState(() {
                            _selectedMain = main;
                            _selectedSub = CategoryData.categories[main]!.first;
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // 右侧小类列表
                Expanded(
                  child: ListView.builder(
                    itemCount: CategoryData.categories[_selectedMain]!.length,
                    itemBuilder: (context, index) {
                      final sub = CategoryData.categories[_selectedMain]![index];
                      return ListTile(
                        title: Text(sub),
                        selected: _selectedSub == sub,
                        selectedTileColor: Colors.teal.withOpacity(0.1),
                        onTap: () {
                          setState(() {
                            _selectedSub = sub;
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'main': _selectedMain,
                      'sub': _selectedSub,
                    });
                  },
                  child: const Text('确定'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}