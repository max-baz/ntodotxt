import 'dart:math';

class Recurrence {
  final int amount;
  final String unit;
  final bool strict;

  const Recurrence({
    required this.amount,
    required this.unit,
    required this.strict,
  });

  static Recurrence? parse(String value) {
    final match = RegExp(r'^(\+)?(\d*)([dbwmy])$').firstMatch(value);
    if (match == null) return null;
    final amount = match[2]!.isEmpty ? 1 : int.tryParse(match[2]!);
    if (amount == null) return null;
    return Recurrence(
      amount: amount == 0 ? 1 : amount,
      unit: match[3]!,
      strict: match[1] != null,
    );
  }

  DateTime advance(DateTime date) {
    switch (unit) {
      case 'd':
      case 'w':
        return DateTime(
          date.year,
          date.month,
          date.day + amount * (unit == 'w' ? 7 : 1),
        );
      case 'b':
        var result = DateTime(date.year, date.month, date.day);
        var remaining = amount;
        if (result.weekday > DateTime.friday) {
          result = DateTime(
            result.year,
            result.month,
            result.day + 8 - result.weekday,
          );
          remaining--;
        }
        final weeks = remaining ~/ 5;
        remaining %= 5;
        result = DateTime(result.year, result.month, result.day + weeks * 7);
        while (remaining > 0) {
          result = DateTime(result.year, result.month, result.day + 1);
          if (result.weekday <= DateTime.friday) remaining--;
        }
        return result;
      case 'm':
      case 'y':
        final month = DateTime(
          date.year + (unit == 'y' ? amount : 0),
          date.month + (unit == 'm' ? amount : 0),
        );
        final lastDay = DateTime(month.year, month.month + 1, 0).day;
        return DateTime(month.year, month.month, min(date.day, lastDay));
      default:
        throw StateError('Unknown recurrence unit: $unit');
    }
  }
}
