import 'package:flutter/material.dart';
import '../utils/csv_helper.dart';
import 'item_input_page.dart';

class ItemListPage extends StatefulWidget {
  const ItemListPage({super.key});

  @override
  State<ItemListPage> createState() => _ItemListPageState();
}

class _ItemListPageState extends State<ItemListPage> {
  List<Item> _items = [];
  bool _isLoading = true;

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
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('加载失败：$e');
    }
  }

  // 删除商品
  Future<void> _deleteItem(String itemId) async {
    try {
      await CsvHelper.deleteItem(itemId);
      _showSnackBar('商品已删除');
      // 重新加载列表
      _loadItems();
    } catch (e) {
      _showSnackBar('删除失败：$e');
    }
  }

  // 长按删除确认
  void _showDeleteConfirmDialog(String itemId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('是否确定删除该商品？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteItem(itemId);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
    // 无商品
    if (_items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('暂无商品', style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 16),
            Text('点击右下角+号添加你的第一个商品吧～', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    // 商品列表
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        // 左滑删除（Dismissible）+ 长按删除
        return Dismissible(
          key: Key(item.id), // 唯一key
          direction: DismissDirection.endToStart, // 从右向左滑
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            // 左滑时弹出确认框
            return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('确认删除'),
                content: const Text('是否删除该商品？'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除', style: TextStyle(color: Colors.red))),
                ],
              ),
            );
          },
          onDismissed: (direction) => _deleteItem(item.id),
          child: GestureDetector(
            onLongPress: () => _showDeleteConfirmDialog(item.id), // 长按删除
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              elevation: 2,
              child: ListTile(
                // Emoji图标
                leading: Text(
                  item.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
                // 商品名称
                title: Text(
                  item.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                // 价格+日期
                subtitle: Text(
                  '¥${item.price} | 购买日期：${item.buyDate}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}