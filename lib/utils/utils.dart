import 'package:flutter/material.dart';

// 价格解析
double? parsePrice(String? priceStr) {
  if (priceStr == null || priceStr.trim().isEmpty) return null;
  final value = double.tryParse(priceStr.trim());
  if (value == null || value <= 0) return null;
  return value;
}

// 日期解析（支持“未填写”）
DateTime? parseDate(String? dateStr) {
  final text = (dateStr ?? '').trim();
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

// 格式化日期（用于显示）
String formatDateShort(DateTime? date) {
  if (date == null) return '';
  return '${date.year}-${date.month}-${date.day}';
}

// 显示 SnackBar
void showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

// 格式化价格显示
String formatPrice(double? price) {
  if (price == null) return '';
  return '¥${price.toStringAsFixed(2)}';
}