// import 'package:intl/intl.dart';
//
// extension DateTimeExt on DateTime {
//   String toFormattedString() => DateFormat('yyyy-MM-dd').format(this);
// }

extension ListExt<T> on List<T>? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
}
