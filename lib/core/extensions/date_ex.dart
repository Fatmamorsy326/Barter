import 'package:intl/intl.dart';

extension DateEx on DateTime{
  String get monthName{
    DateFormat date=DateFormat("MMM");
    return date.format(this);
  }
}