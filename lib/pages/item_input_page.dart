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
  const ItemInputPage({super.key});

  @override
  State<ItemInputPage> createState() => _ItemInputPageState();
}

class _ItemInputPageState extends State<ItemInputPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  DateTime? _buyDate;
  String _selectedEmoji = '📦'; // 默认emoji

  // 生成唯一id
  final _uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('添加商品')),
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
                      initialDate: DateTime.now(),
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
                  child: const Text('保存物品'),
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
      id: _uuid.v4(),   // 生成唯一id
      emoji: _selectedEmoji,
      name: name,
      price: finalPrice,
      buyDate: finalBuyDate,
    );

    // 3. 写入csv
    try {
      await CsvHelper.addItem(item);
      _showSnackBar('物品添加成功！');
      // 4. 关闭录入页，返回列表页
      Navigator.pop(context, true); // 传true通知列表页刷新
    } catch (e) {
      _showSnackBar('添加失败：$e');
    }
  }

  // 辅助：显示提示
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}