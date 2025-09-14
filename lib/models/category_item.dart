import 'package:flutter/material.dart'; // Add this import
import 'package:hive/hive.dart';

part 'category_item.g.dart';

@HiveType(typeId: 1)
class CategoryItem {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final double limit;

  @HiveField(2)
  final String icon;

  @HiveField(3)
  final int? iconCodePoint; // New field for Material icon code points

  CategoryItem({
    required this.name,
    required this.limit,
    required this.icon,
    this.iconCodePoint,
  });

  // Helper method to get IconData from stored code point
  IconData? getIconData() {
    if (iconCodePoint != null) {
      return IconData(iconCodePoint!, fontFamily: 'MaterialIcons');
    }
    return null;
  }
}