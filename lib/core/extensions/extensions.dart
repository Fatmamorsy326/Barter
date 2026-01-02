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