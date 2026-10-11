import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ntodotxt/todo/api/todo_list_api.dart';
import 'package:ntodotxt/todo/model/todo_model.dart';
import 'package:ntodotxt/todo/repository/todo_list_repository.dart';
import 'package:ntodotxt/todo/state/todo_list_bloc.dart';
import 'package:ntodotxt/todo/state/todo_list_event.dart';
import 'package:ntodotxt/todo/state/todo_list_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final viaEditor in [false, true]) {
    test('completion via ${viaEditor ? 'editor save' : 'list toggle'} recurs once',
        () async {
      final file = MemoryFileSystem().file('todo.txt')..createSync();
      final api = LocalTodoListApi.fromFile(localFile: file);
      final repository = TodoListRepository(api);
      final original = Todo(description: 'Task rec:1w +project @context');
      repository.saveTodo(original);
      final bloc = TodoListBloc(repository: repository);
      addTearDown(() async {
        await bloc.close();
        api.dispose();
      });
      bloc.add(const TodoListSubscriptionRequested());
      await bloc.stream.firstWhere(
        (state) => state.todoList.length == 1,
      );
      final saved = bloc.stream.firstWhere(
        (state) => state is TodoListSuccess && state.todoList.length == 2,
      );
      bloc.add(viaEditor
          ? TodoListTodoSubmitted(
              todo: original.copyWith(completion: true),
            )
          : TodoListTodoCompletionToggled(
              todo: original,
              completion: true,
            ));
      final state = await saved.timeout(const Duration(seconds: 5));
      final completed = state.todoList.singleWhere((todo) => todo.completion);
      final next = state.todoList.singleWhere((todo) => !todo.completion);
      expect(completed.id, original.id);
      expect(next.id, isNot(original.id));
      expect(next.dueDate, completed.recurrence!.advance(completed.completionDate!));
      expect(next.projects, original.projects);
      expect(file.readAsLinesSync().length, 2);
      expect(Todo.fromString(value: file.readAsLinesSync().last), next);

      final resaved = bloc.stream.firstWhere((state) => state is TodoListSuccess);
      bloc.add(TodoListTodoSubmitted(
        todo: completed.copyWith(description: '${completed.description} edited'),
      ));
      await resaved.timeout(const Duration(seconds: 5));
      expect((await repository.getTodoList().first).length, 2);

      final undone = bloc.stream.firstWhere((state) => state is TodoListSuccess);
      bloc.add(TodoListTodoCompletionToggled(todo: completed, completion: false));
      await undone.timeout(const Duration(seconds: 5));
      final todos = await repository.getTodoList().first;
      expect(todos.length, 2);
      expect(todos.every((todo) => !todo.completion), true);
    });
  }

  test('importing or creating an already completed task does not recur', () async {
    final file = MemoryFileSystem().file('todo.txt')..createSync();
    final api = LocalTodoListApi.fromFile(localFile: file);
    final repository = TodoListRepository(api);
    final bloc = TodoListBloc(repository: repository);
    addTearDown(() async {
      await bloc.close();
      api.dispose();
    });
    final saved = bloc.stream.firstWhere((state) => state is TodoListSuccess);
    bloc.add(TodoListTodoSubmitted(
      todo: Todo(completion: true, description: 'Task rec:w'),
    ));
    await saved.timeout(const Duration(seconds: 5));
    expect(file.readAsLinesSync().length, 1);
  });
}
