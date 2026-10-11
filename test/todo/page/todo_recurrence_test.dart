import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ntodotxt/todo/model/todo_model.dart';
import 'package:ntodotxt/todo/page/todo_create_edit_page.dart';
import 'package:ntodotxt/todo/state/todo_cubit.dart';

import 'todo_create_edit_page_test.dart' show MaterialAppWrapper;

void main() {
  for (final editing in [false, true]) {
    testWidgets('recurrence field in ${editing ? 'edit' : 'create'} mode',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialAppWrapper(
        initTodo: editing ? Todo(description: 'Task rec:1w') : null,
      ));
      await tester.pumpAndSettle();
      final item = find.byType(TodoRecurrenceItem);
      final cubit = tester.element(item).read<TodoCubit>();
      final description = find.descendant(
        of: find.byType(TodoDescriptionTextField),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(description, 'Task rec:+2m');
      await tester.pumpAndSettle();
      expect(cubit.state.todo.recurrence!.strict, true);
      expect(find.descendant(of: item, matching: find.text('+2m')),
          findsOneWidget);

      await tester.tap(item);
      await tester.pumpAndSettle();
      final interval = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextFormField),
      );
      expect(tester.widget<TextFormField>(interval).controller!.text, '+2m');
      await tester.enterText(interval, 'oops');
      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(cubit.state.todo.recurrenceValue, '+2m');
      await tester.enterText(interval, '3b');
      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pumpAndSettle();
      expect(cubit.state.todo.description, 'Task rec:3b');
      expect(tester.widget<TextFormField>(description).controller!.text,
          'Task rec:3b');
      expect(tester.takeException(), isNull);

      await tester.tap(item);
      await tester.pumpAndSettle();
      await tester.enterText(interval, '1y');
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(cubit.state.todo.recurrenceValue, '3b');

      await tester.tap(find.byTooltip('Remove recurrence'));
      await tester.pumpAndSettle();
      expect(cubit.state.todo.recurrenceValue, isNull);
      expect(cubit.state.todo.description, 'Task');

      await tester.tap(item);
      await tester.pumpAndSettle();
      await tester.enterText(interval, 'w');
      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pumpAndSettle();
      expect(cubit.state.todo.recurrence!.amount, 1);
      await tester.tap(item);
      await tester.pumpAndSettle();
      await tester.enterText(interval, '');
      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pumpAndSettle();
      expect(cubit.state.todo.recurrenceValue, isNull);
      expect(tester.takeException(), isNull);
    });
  }
}
