import 'dart:io';

import 'package:args/args.dart';
import 'package:eventsource_core/eventsource_core.dart';
import 'package:isar/isar.dart';

import 'todo_app.dart';
import 'todo_list_read_model.dart';

void main(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      'event-store',
      abbr: 'e',
      defaultsTo: 'isar',
      allowed: ['memory', 'isar'],
      help: 'Event store type to use',
    )
    ..addOption(
      'db-path',
      help: 'Path for the Isar database (only used with --event-store=isar)',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show this help message',
    );

  try {
    final results = parser.parse(args);

    if (results['help'] as bool) {
      print('Todo List Example App (Interactive)\n');
      print('Usage: dart run example/todo_app_interactive.dart [options]\n');
      print('Options:');
      print(parser.usage);
      return;
    }

    final storeType = results['event-store'] as String;
    final dbPath = results['db-path'] as String?;

    // Initialize Isar for native environment if needed
    if (storeType == 'isar') {
      print('Initializing Isar native library...');
      await Isar.initializeIsarCore(download: true);
    }

    // Initialize event sourcing system
    final eventStoreFactory = getEventStoreFactory(storeType, dbPath);
    final snapshotStoreFactory = getSnapshotStoreFactory('memory');
    final system = EventSourcingSystem(eventStoreFactory, snapshotStoreFactory);

    // Register event types
    Event.registerFactory('TodoListCreated', TodoListCreated.fromJson);
    Event.registerFactory('TodoItemAdded', TodoItemAdded.fromJson);
    Event.registerFactory('TodoItemCompleted', TodoItemCompleted.fromJson);

    // Register the aggregate type
    system.registerAggregate(TodoListAggregate.new);

    // Create and register the read model
    final readModel = TodoListReadModel();
    final eventStore = await eventStoreFactory.create();
    eventStore.registerSubscriber(readModel);

    // Start the system
    await system.start();

    // Interactive loop variables
    String? currentList;
    final stdin = Stdin();

    try {
      print('\nTodo List Example App\n');

      while (true) {
        print('Available commands:\n');
        print('  create "<title>" - Create a new todo list');
        print('  add "<title>" - Add a todo item to the current list');
        print('  complete <id> - Mark a todo item as completed');
        print('  list - List all items in the current todo list');
        print('  lists - Show all todo lists');
        print('  use <id> - Switch to a different todo list');
        print('  incomplete - Show incomplete items in current list');
        print('  completed - Show completed items in current list');
        print('  exit - Exit the program\n');

        if (currentList != null) {
          print('Current list: ${readModel.todoLists[currentList]}\n');
        }

        stdout.write('> ');
        final input = stdin.readLineSync();
        if (input == null || input.trim().isEmpty) continue;

        final parts = input.trim().split(' ');
        final command = parts[0].toLowerCase();
        final args =
            parts.length > 1 ? input.substring(command.length + 1) : '';

        switch (command) {
          case 'exit':
            return;

          case 'create':
            if (args.isEmpty) {
              print('Error: Title is required');
              break;
            }
            final title = args.trim();
            final listId = newId();
            final cmd = CreateTodoList(listId, DateTime.now(), title);

            await for (final event in system.publish(cmd)) {
              if (event is CommandFailed) {
                print('Failed to create list: ${event.error}');
                break;
              }
            }
            currentList = listId;
            print('Created new todo list with ID: $listId');
            break;

          case 'use':
            if (args.isEmpty) {
              print('Error: List ID is required');
              break;
            }
            final listId = args.trim();
            if (!readModel.todoLists.containsKey(listId)) {
              print('Error: List not found');
              break;
            }
            currentList = listId;
            print('Switched to list: ${readModel.todoLists[listId]}');
            break;

          case 'add':
            if (currentList == null) {
              print('No todo list selected. Create one first.');
              break;
            }
            if (args.isEmpty) {
              print('Error: Title is required');
              break;
            }
            final title = args.trim();
            final itemId = newId();
            final cmd =
                AddTodoItem(currentList!, DateTime.now(), itemId, title);

            await for (final event in system.publish(cmd)) {
              if (event is CommandFailed) {
                print('Failed to add item: ${event.error}');
                break;
              }
            }
            print('Added new item with ID: $itemId');
            break;

          case 'complete':
            if (currentList == null) {
              print('No todo list selected. Create one first.');
              break;
            }
            if (args.isEmpty) {
              print('Error: Item ID is required');
              break;
            }
            final itemId = args.trim();
            final cmd = CompleteTodoItem(currentList!, DateTime.now(), itemId);

            await for (final event in system.publish(cmd)) {
              if (event is CommandFailed) {
                print('Failed to complete item: ${event.error}');
                break;
              }
            }
            print('Marked item as completed: $itemId');
            break;

          case 'list':
            if (currentList == null) {
              print('No todo list selected. Create one first.');
              break;
            }
            final items = readModel.getItems(currentList!);
            print('\nTodo List: ${readModel.todoLists[currentList!]}\n');
            for (final item in items) {
              final status = item.isCompleted ? '[x]' : '[ ]';
              print('$status ${item.id}: ${item.title}');
            }
            print('');
            break;

          case 'lists':
            print('\nAll Todo Lists:\n');
            for (final entry in readModel.todoLists.entries) {
              print('${entry.key}: ${entry.value}');
            }
            print('');
            break;

          case 'incomplete':
            if (currentList == null) {
              print('No todo list selected. Create one first.');
              break;
            }
            final items = readModel.getIncompleteItems(currentList!);
            print('\nIncomplete Items:\n');
            for (final item in items) {
              print('[ ] ${item.id}: ${item.title}');
            }
            print('');
            break;

          case 'completed':
            if (currentList == null) {
              print('No todo list selected. Create one first.');
              break;
            }
            final items = readModel.getCompletedItems(currentList!);
            print('\nCompleted Items:\n');
            for (final item in items) {
              print('[x] ${item.id}: ${item.title}');
            }
            print('');
            break;

          default:
            print('Unknown command: $command');
            break;
        }
      }
    } finally {
      await system.stop();
    }
  } catch (e, stack) {
    print('Error: $e');
    print('Stack trace: $stack');
  }
}
