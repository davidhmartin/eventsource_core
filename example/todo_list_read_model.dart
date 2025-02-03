import 'package:eventsource_core/eventsource_core.dart';
import 'package:eventsource_core/src/event_subscription.dart';

import 'todo_app.dart';

/// A read model that maintains a list of all todo items and their status
class TodoListReadModel implements EventSubscriber {
  // Map of todo list ID to list title
  final Map<String, String> _todoLists = {};

  // Map of todo list ID to list of todo items
  final Map<String, List<TodoItem>> _todoItems = {};

  @override
  void onEvent(Event event) {
    switch (event.type) {
      case 'TodoListCreated':
        final e = event as TodoListCreated;
        _todoLists[e.aggregateId] = e.title;
        _todoItems[e.aggregateId] = [];
        break;

      case 'TodoItemAdded':
        final e = event as TodoItemAdded;
        final items = _todoItems[e.aggregateId]!;
        items.add(TodoItem(e.itemId, e.title, false));
        break;

      case 'TodoItemCompleted':
        final e = event as TodoItemCompleted;
        final items = _todoItems[e.aggregateId]!;
        final index = items.indexWhere((item) => item.id == e.itemId);
        if (index != -1) {
          final item = items[index];
          items[index] = item.copyWith(isCompleted: true);
        }
        break;
    }
  }

  /// Get all todo lists
  Map<String, String> get todoLists => Map.unmodifiable(_todoLists);

  /// Get items for a specific todo list
  List<TodoItem> getItems(String todoListId) {
    return List.unmodifiable(_todoItems[todoListId] ?? []);
  }

  /// Get all incomplete items for a todo list
  List<TodoItem> getIncompleteItems(String todoListId) {
    final items = _todoItems[todoListId] ?? [];
    return List.unmodifiable(items.where((item) => !item.isCompleted).toList());
  }

  /// Get all completed items for a todo list
  List<TodoItem> getCompletedItems(String todoListId) {
    final items = _todoItems[todoListId] ?? [];
    return List.unmodifiable(items.where((item) => item.isCompleted).toList());
  }

  /// Clear all data (useful for testing)
  void clear() {
    _todoLists.clear();
    _todoItems.clear();
  }
}
