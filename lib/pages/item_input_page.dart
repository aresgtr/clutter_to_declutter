import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // 生成唯一ID（需在pubspec.yaml添加uuid: ^4.4.0）
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

  // 生成唯一id
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? '编辑商品' : '添加商品')),
      body: SingleChildScrollView(  // 避免键盘遮挡
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
            // 2. 成本计算方式
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
            // 2. 商品名称输入框
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '物品名称',
                hintText: '比如：纯棉T恤、无线耳机',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // 3. 购买价格输入框
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
            // 4. 购买日期选择按钮
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
                    : '购买日期：${_buyDate!.year}-${_buyDate!.month}-${_buyDate!.day}')
            ),
            const SizedBox(height: 24),
            // 5. 保存按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: _saveItem,
                  child: Text(_isEditMode ? '保存修改' : '保存物品'),
              ),
            )
          ],
        ),
      ),
    );
  }

  // 保存物品到csv
  Future<void> _saveItem() async {
    // 1. 基础校验
    final String name = _nameController.text.trim();
    final String price = _priceController.text.trim();
    if (name.isEmpty) {
      _showSnackBar('请输入商品名称');
      return;
    }

    // 2. 处理可选字段空值
    final String finalPrice = price.isEmpty ? '0' : price;
    final String finalBuyDate = _buyDate == null
        ? '未填写'
        : '${_buyDate!.year}-${_buyDate!.month}-${_buyDate!.day}';

    // 3. 构建商品对象
    final item = Item(
      id: widget.item?.id ?? _uuid.v4(), // 编辑保留id，新增生成id
      emoji: _selectedEmoji,
      name: name,
      price: finalPrice,
      buyDate: finalBuyDate,
      archived: widget.item?.archived ?? false,
      costMode: _costMode,
      useCount: _costMode == 'count' ? _useCount : 0,
    );

    // 3. 写入csv
    try {
      if (_isEditMode) {
        await CsvHelper.updateItem(item);
        _showSnackBar('修改已保存！');
      } else {
        await CsvHelper.addItem(item);
        _showSnackBar('物品添加成功！');
      }

      // 4. 关闭页面，返回列表页
      if (!mounted) return;
      Navigator.pop(context, true); // 传true通知列表页刷新
    } catch (e) {
      _showSnackBar('${_isEditMode ? '保存' : '添加'}失败：$e');
    }
  }

  // 辅助：显示提示
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}