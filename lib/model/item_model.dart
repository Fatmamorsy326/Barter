// ============================================
// FILE: lib/model/item_model.dart
// ============================================

import 'package:flutter/material.dart';

enum ItemCategory {
  electronics,
  clothing,
  books,
  furniture,
  sports,
  other
}

enum ItemCondition {
  newItem,
  likeNew,
  good,
  fair,
  poor
}

// Extensions for display names
extension ItemCategoryExtension on ItemCategory {
  String get displayName {
    switch (this) {
      case ItemCategory.electronics:
        return 'Electronics';
      case ItemCategory.clothing:
        return 'Clothing';
      case ItemCategory.books:
        return 'Books';
      case ItemCategory.furniture:
        return 'Furniture';
      case ItemCategory.sports:
        return 'Sports';
      case ItemCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case ItemCategory.electronics:
        return Icons.devices;
      case ItemCategory.clothing:
        return Icons.checkroom;
      case ItemCategory.books:
        return Icons.menu_book;
      case ItemCategory.furniture:
        return Icons.chair;
      case ItemCategory.sports:
        return Icons.sports_soccer;
      case ItemCategory.other:
        return Icons.category;
    }
  }
}

extension ItemConditionExtension on ItemCondition {
  String get displayName {
    switch (this) {
      case ItemCondition.newItem:
        return 'New';
      case ItemCondition.likeNew:
        return 'Like New';
      case ItemCondition.good:
        return 'Good';
      case ItemCondition.fair:
        return 'Fair';
      case ItemCondition.poor:
        return 'Poor';
    }
  }

  Color get color {
    switch (this) {
      case ItemCondition.newItem:
        return Colors.green;
      case ItemCondition.likeNew:
        return Colors.lightGreen;
      case ItemCondition.good:
        return Colors.orange;
      case ItemCondition.fair:
        return Colors.deepOrange;
      case ItemCondition.poor:
        return Colors.red;
    }
  }
}

class ItemModel {
  final String id;
  final String ownerId;
  final String ownerName;
  final String title;
  final String description;
  final List<String> imageUrls;
  final ItemCategory category;
  final ItemCondition condition;
  final String? preferredExchange;
  final String location;
  final DateTime createdAt;
  final bool isAvailable;

  ItemModel({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.title,
    required this.description,
    required this.imageUrls,
    required this.category,
    required this.condition,
    this.preferredExchange,
    required this.location,
    required this.createdAt,
    this.isAvailable = true,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'] ?? '',
      ownerId: json['ownerId'] ?? '',
      ownerName: json['ownerName'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      category: ItemCategory.values[json['category'] ?? 5],
      condition: ItemCondition.values[json['condition'] ?? 2],
      preferredExchange: json['preferredExchange'],
      location: json['location'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'title': title,
      'description': description,
      'imageUrls': imageUrls,
      'category': category.index,
      'condition': condition.index,
      'preferredExchange': preferredExchange,
      'location': location,
      'createdAt': createdAt.toIso8601String(),
      'isAvailable': isAvailable,
    };
  }

  // CopyWith method for easy updates
  ItemModel copyWith({
    String? id,
    String? ownerId,
    String? ownerName,
    String? title,
    String? description,
    List<String>? imageUrls,
    ItemCategory? category,
    ItemCondition? condition,
    String? preferredExchange,
    String? location,
    DateTime? createdAt,
    bool? isAvailable,
  }) {
    return ItemModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      preferredExchange: preferredExchange ?? this.preferredExchange,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}