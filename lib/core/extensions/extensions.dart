import 'package:barter/model/item_model.dart';
import 'package:intl/intl.dart';

extension DateEx on DateTime{
  String get monthName{
    DateFormat date=DateFormat("MMM");
    return date.format(this);
  }
}
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

extension ItemCategoryExtension on ItemCategory {
  String get displayName {
    switch (this) {
      case ItemCategory.electronics: return 'Electronics';
      case ItemCategory.clothing: return 'Clothing';
      case ItemCategory.books: return 'Books';
      case ItemCategory.furniture: return 'Furniture';
      case ItemCategory.sports: return 'Sports';
      case ItemCategory.other: return 'Other';
    }
  }
}

extension ItemConditionExtension on ItemCondition {
  String get displayName {
    switch (this) {
      case ItemCondition.newItem: return 'New';
      case ItemCondition.likeNew: return 'Like New';
      case ItemCondition.good: return 'Good';
      case ItemCondition.fair: return 'Fair';
      case ItemCondition.poor: return 'Poor';
    }
  }
}