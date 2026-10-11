import 'package:flutter_test/flutter_test.dart';
import 'package:ntodotxt/todo/model/recurrence.dart';
import 'package:ntodotxt/todo/model/todo_model.dart';

void main() {
  group('recurrence syntax', () {
    for (final unit in ['d', 'b', 'w', 'm', 'y']) {
      for (final prefix in ['', '+']) {
        test('$prefix$unit defaults to one', () {
          final rule = Recurrence.parse('$prefix$unit')!;
          expect(rule.amount, 1);
          expect(rule.strict, prefix == '+');
          expect(rule.unit, unit);
          expect(Recurrence.parse('${prefix}0$unit')!.amount, 1);
          expect(Recurrence.parse('${prefix}12$unit')!.amount, 12);
        });
      }
    }
    for (final value in ['', '+', '1', '-1w', '1W', '1h', '1.5w', '1wmore']) {
      test('$value is inactive and preserved', () {
        final todo = Todo(description: 'Task rec:$value');
        expect(todo.recurrence, isNull);
        expect(todo.description, 'Task rec:$value');
      });
    }
  });

  group('calendar arithmetic', () {
    test('days and weeks', () {
      expect(Recurrence.parse('4d')!.advance(DateTime(2021, 6, 1)),
          DateTime(2021, 6, 5));
      expect(Recurrence.parse('3w')!.advance(DateTime(2021, 6, 1)),
          DateTime(2021, 6, 22));
    });
    test('business days skip weekends including weekend starts', () {
      for (final day in [4, 5, 6]) {
        expect(Recurrence.parse('1b')!.advance(DateTime(2021, 6, day)),
            DateTime(2021, 6, 7));
      }
      expect(Recurrence.parse('4b')!.advance(DateTime(2021, 6, 1)),
          DateTime(2021, 6, 7));
      expect(Recurrence.parse('10b')!.advance(DateTime(2021, 6, 5)),
          DateTime(2021, 6, 18));
    });
    test('months and years clamp rather than overflow', () {
      expect(Recurrence.parse('1m')!.advance(DateTime(2024, 1, 31)),
          DateTime(2024, 2, 29));
      expect(Recurrence.parse('1y')!.advance(DateTime(2024, 2, 29)),
          DateTime(2025, 2, 28));
      expect(Recurrence.parse('3m')!.advance(DateTime(2024, 11, 30)),
          DateTime(2025, 2, 28));
    });
  });

  Todo completed(String description) => Todo(
    completion: true,
    completionDate: DateTime(2021, 6, 25),
    creationDate: DateTime(2021, 1, 1),
    priority: Priority.A,
    description: description,
  );

  group('next occurrence', () {
    test('relative uses completion; strict uses due, even when overdue', () {
      expect(completed('Task due:2021-06-01 rec:1w').nextOccurrence()!.dueDate,
          DateTime(2021, 7, 2));
      expect(completed('Task due:2021-06-01 rec:+1w').nextOccurrence()!.dueDate,
          DateTime(2021, 6, 8));
    });
    test('missing dates get a due date in both modes', () {
      for (final rec in ['w', '+w']) {
        expect(completed('Task rec:$rec').nextOccurrence()!.dueDate,
            DateTime(2021, 7, 2));
      }
    });
    test('threshold only does not introduce a due date', () {
      final relative = completed('Task t:2021-06-01 rec:1w').nextOccurrence()!;
      expect(relative.dueDate, isNull);
      expect(relative.thresholdDate, DateTime(2021, 7, 2));
      final strict = completed('Task t:2021-06-01 rec:+1w').nextOccurrence()!;
      expect(strict.dueDate, isNull);
      expect(strict.thresholdDate, DateTime(2021, 6, 8));
    });
    test('relative preserves positive due/threshold gap', () {
      final next = completed('Task due:2021-06-22 t:2021-06-15 rec:3w')
          .nextOccurrence()!;
      expect(next.dueDate, DateTime(2021, 7, 16));
      expect(next.thresholdDate, DateTime(2021, 7, 9));
    });
    test('strict advances each scheduled date separately', () {
      final next = completed('Task due:2021-06-22 t:2021-06-15 rec:+3w')
          .nextOccurrence()!;
      expect(next.dueDate, DateTime(2021, 7, 13));
      expect(next.thresholdDate, DateTime(2021, 7, 6));
    });
    test('relative zero or negative gaps use completion plus interval', () {
      for (final threshold in ['2021-06-22', '2021-06-23']) {
        final next = completed('Task due:2021-06-22 t:$threshold rec:1w')
            .nextOccurrence()!;
        expect(next.thresholdDate, next.dueDate);
      }
    });
    test('new identity, incomplete, preserves metadata and resets creation', () {
      final original = completed('Task +project @context custom:value rec:1w');
      final next = original.nextOccurrence()!;
      expect(next.id, isNot(original.id));
      expect(next.completion, false);
      expect(next.completionDate, isNull);
      expect(next.creationDate, original.completionDate);
      expect(next.priority, Priority.A);
      expect(next.projects, original.projects);
      expect(next.contexts, original.contexts);
      expect(next.keyValues, containsAll(['custom:value', 'rec:1w']));
      expect(Todo.fromString(value: next.toString()), next);
    });
    test('date replacement preserves ordinary words and unrelated tags', () {
      final next = completed(
        'Task due t custom:due:thing due:2021-06-01 rec:w',
      ).nextOccurrence()!;
      expect(next.description, contains('Task due t custom:due:thing'));
      expect(next.keyValues.where((kv) => kv.startsWith('due:')).length, 1);
    });
    test('no creation date stays unset', () {
      expect(Todo(completion: true, description: 'Task rec:w')
          .nextOccurrence()!.creationDate, isNull);
    });
    test('incomplete and invalid tasks do not recur', () {
      expect(Todo(description: 'Task rec:w').nextOccurrence(), isNull);
      expect(completed('Task rec:invalid').nextOccurrence(), isNull);
    });
  });
}
