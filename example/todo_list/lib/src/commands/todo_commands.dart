import 'package:eventsource_core/command_handler.dart';

/// Command to create a new todo list
class CreateTodoList extends Command {
  final String title;

  CreateTodoList({
    required String id,
    required this.title,
  }) : super(id: id);
}

/// Command to add a new item to a todo list
class AddTodoItem extends Command {
  final String itemId;
  final String title;

  AddTodoItem({
    required String id,  // This is the list ID
    required this.itemId,
    required this.title,
  }) : super(id: id);
}

/// Command to mark a todo item as complete
class CompleteTodoItem extends Command {
  final String itemId;

  CompleteTodoItem({
    required String id,  // This is the list ID
    required this.itemId,
  }) : super(id: id);
}

/// Command to mark a todo item as incomplete
class UncompleteTodoItem extends Command {
  final String itemId;

  UncompleteTodoItem({
    required String id,  // This is the list ID
    required this.itemId,
  }) : super(id: id);
}
