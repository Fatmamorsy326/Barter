// ============================================
// FILE: lib/model/item_model.dart
// ============================================

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

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
  final double? latitude;        // NEW - Latitude coordinate
  final double? longitude;       // NEW - Longitude coordinate
  final String? detailedAddress; // NEW - Full address details
  final DateTime createdAt;
  final bool isAvailable;
  final bool isExchanged; // NEW - Indicates if item was exchanged successfully

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
    this.latitude,
    this.longitude,
    this.detailedAddress,
    required this.createdAt,
    this.isAvailable = true,
    this.isExchanged = false,
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
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      detailedAddress: json['detailedAddress'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isAvailable: json['isAvailable'] ?? true,
      isExchanged: json['isExchanged'] ?? false,
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
      'latitude': latitude,
      'longitude': longitude,
      'detailedAddress': detailedAddress,
      'createdAt': createdAt.toIso8601String(),
      'isAvailable': isAvailable,
      'isExchanged': isExchanged,
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
    double? latitude,
    double? longitude,
    String? detailedAddress,
    DateTime? createdAt,
    bool? isAvailable,
    bool? isExchanged,
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
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      detailedAddress: detailedAddress ?? this.detailedAddress,
      createdAt: createdAt ?? this.createdAt,
      isAvailable: isAvailable ?? this.isAvailable,
      isExchanged: isExchanged ?? this.isExchanged,
    );
  }

  // ====================
  // LOCATION HELPER METHODS
  // ====================

  /// Check if item has valid coordinates
  bool get hasCoordinates => latitude != null && longitude != null;

  /// Calculate distance to another item in kilometers
  double? distanceTo(ItemModel other) {
    if (!hasCoordinates || !other.hasCoordinates) {
      return null;
    }
    return Geolocator.distanceBetween(
      latitude!,
      longitude!,
      other.latitude!,
      other.longitude!,
    ) / 1000; // Convert to kilometers
  }

  /// Calculate distance from a specific location in kilometers
  double? distanceFrom(double lat, double lng) {
    if (!hasCoordinates) {
      return null;
    }
    return Geolocator.distanceBetween(
      latitude!,
      longitude!,
      lat,
      lng,
    ) / 1000; // Convert to kilometers
  }

  /// Get formatted distance string
  String? getFormattedDistance(double lat, double lng) {
    final distance = distanceFrom(lat, lng);
    if (distance == null) return null;

    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)}m away';
    } else if (distance < 10) {
      return '${distance.toStringAsFixed(1)}km away';
    } else {
      return '${distance.toStringAsFixed(0)}km away';
    }
  }

  /// Check if item is within a certain radius (in kilometers)
  bool isWithinRadius(double lat, double lng, double radiusKm) {
    final distance = distanceFrom(lat, lng);
    if (distance == null) return false;
    return distance <= radiusKm;
  }
}