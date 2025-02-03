import 'package:args/args.dart';
import 'package:eventsource_core/eventsource_core.dart';
import 'package:eventsource_core/src/stores/store_factories.dart';
import 'package:isar/isar.dart';

// Value object for a todo item
class TodoItem {
  final String id;
  final String title;
  final bool isCompleted;

  TodoItem(this.id, this.title, this.isCompleted);

  TodoItem copyWith({String? id, String? title, bool? isCompleted}) {
    return TodoItem(
      id ?? this.id,
      title ?? this.title,
      isCompleted ?? this.isCompleted,
    );
  }
}

// Events
class TodoListCreated extends Event {
  final String title;

  TodoListCreated(ID id, ID aggregateId, DateTime timestamp, this.title)
      : super(id, aggregateId, timestamp, 1, '');

  @override
  String get type => 'TodoListCreated';

  @override
  Event withVersion(int newVersion) {
    return TodoListCreated(id, aggregateId, timestamp, title);
  }

  @override
  Map<String, dynamic> serializeState(Map<String, dynamic> json) {
    json['title'] = title;
    return json;
  }

  @override
  void deserializeState(Map<String, dynamic> json) {
    // Not needed for this example
  }

  factory TodoListCreated.fromJson(Map<String, dynamic> json) {
    return TodoListCreated(
      json['id'] as ID,
      json['aggregateId'] as ID,
      DateTime.parse(json['timestamp'] as String),
      json['title'] as String,
    );
  }
}

class TodoItemAdded extends Event {
  final String itemId;
  final String title;

  TodoItemAdded(
      ID id, ID aggregateId, DateTime timestamp, this.itemId, this.title)
      : super(id, aggregateId, timestamp, 1, '');

  @override
  String get type => 'TodoItemAdded';

  @override
  Event withVersion(int newVersion) {
    return TodoItemAdded(id, aggregateId, timestamp, itemId, title);
  }

  @override
  Map<String, dynamic> serializeState(Map<String, dynamic> json) {
    json['itemId'] = itemId;
    json['title'] = title;
    return json;
  }

  @override
  void deserializeState(Map<String, dynamic> json) {
    // Not needed for this example
  }

  factory TodoItemAdded.fromJson(Map<String, dynamic> json) {
    return TodoItemAdded(
      json['id'] as ID,
      json['aggregateId'] as ID,
      DateTime.parse(json['timestamp'] as String),
      json['itemId'] as String,
      json['title'] as String,
    );
  }
}

class TodoItemCompleted extends Event {
  final String itemId;

  TodoItemCompleted(ID id, ID aggregateId, DateTime timestamp, this.itemId)
      : super(id, aggregateId, timestamp, 1, '');

  @override
  String get type => 'TodoItemCompleted';

  @override
  Event withVersion(int newVersion) {
    return TodoItemCompleted(id, aggregateId, timestamp, itemId);
  }

  @override
  Map<String, dynamic> serializeState(Map<String, dynamic> json) {
    json['itemId'] = itemId;
    return json;
  }

  @override
  void deserializeState(Map<String, dynamic> json) {
    // Not needed for this example
  }

  factory TodoItemCompleted.fromJson(Map<String, dynamic> json) {
    return TodoItemCompleted(
      json['id'] as ID,
      json['aggregateId'] as ID,
      DateTime.parse(json['timestamp'] as String),
      json['itemId'] as String,
    );
  }
}

// Commands
class CreateTodoList extends Command {
  final String title;

  CreateTodoList(ID aggregateId, DateTime timestamp, this.title)
      : super(aggregateId, 'TodoList', timestamp, '', true);

  @override
  String get type => 'CreateTodoList';

  @override
  Event? handle(Aggregate? aggregate) {
    if (title.isEmpty) {
      throw ArgumentError('Title cannot be empty');
    }
    return TodoListCreated(newId(), aggregateId, timestamp, title);
  }

  @override
  void serializeState(JsonMap json) {
    json['title'] = title;
  }

  @override
  void deserializeState(JsonMap json) {
    // Not needed for this example
  }
}

class AddTodoItem extends Command {
  final String itemId;
  final String title;

  AddTodoItem(ID aggregateId, DateTime timestamp, this.itemId, this.title)
      : super(aggregateId, 'TodoList', timestamp, '', false);

  @override
  String get type => 'AddTodoItem';

  @override
  Event? handle(Aggregate? aggregate) {
    if (!(aggregate is TodoListAggregate)) {
      throw ArgumentError('Invalid aggregate type');
    }

    if (title.isEmpty) {
      throw ArgumentError('Title cannot be empty');
    }

    if (aggregate.items.containsKey(itemId)) {
      throw ArgumentError('Item ID already exists');
    }

    return TodoItemAdded(newId(), aggregateId, timestamp, itemId, title);
  }

  @override
  void serializeState(JsonMap json) {
    json['itemId'] = itemId;
    json['title'] = title;
  }

  @override
  void deserializeState(JsonMap json) {
    // Not needed for this example
  }
}

class CompleteTodoItem extends Command {
  final String itemId;

  CompleteTodoItem(ID aggregateId, DateTime timestamp, this.itemId)
      : super(aggregateId, 'TodoList', timestamp, '', false);

  @override
  String get type => 'CompleteTodoItem';

  @override
  Event? handle(Aggregate? aggregate) {
    if (!(aggregate is TodoListAggregate)) {
      throw ArgumentError('Invalid aggregate type');
    }

    if (!aggregate.items.containsKey(itemId)) {
      throw ArgumentError('Item not found');
    }

    if (aggregate.items[itemId]!.isCompleted) {
      throw ArgumentError('Item is already completed');
    }

    return TodoItemCompleted(newId(), aggregateId, timestamp, itemId);
  }

  @override
  void serializeState(JsonMap json) {
    json['itemId'] = itemId;
  }

  @override
  void deserializeState(JsonMap json) {
    // Not needed for this example
  }
}

// Aggregate
class TodoListAggregate extends Aggregate {
  String title = '';
  final Map<String, TodoItem> items = {};

  TodoListAggregate(super.id);

  @override
  String get type => 'TodoList';

  @override
  void applyEventToState(Event event) {
    if (event is TodoListCreated) {
      title = event.title;
    } else if (event is TodoItemAdded) {
      items[event.itemId] = TodoItem(event.itemId, event.title, false);
    } else if (event is TodoItemCompleted) {
      var item = items[event.itemId];
      if (item != null) {
        items[event.itemId] = item.copyWith(isCompleted: true);
      }
    }
  }

  @override
  Map<String, dynamic> serializeState(Map<String, dynamic> json) {
    json['title'] = title;
    json['items'] = items.map((key, value) => MapEntry(key, {
          'id': value.id,
          'title': value.title,
          'isCompleted': value.isCompleted,
        }));
    return json;
  }

  @override
  void deserializeState(Map<String, dynamic> json) {
    title = json['title'] as String;
    final itemsJson = json['items'] as Map<String, dynamic>;
    items.clear();
    itemsJson.forEach((key, value) {
      items[key] = TodoItem(
        value['id'] as String,
        value['title'] as String,
        value['isCompleted'] as bool,
      );
    });
  }
}

EventStoreFactory getEventStoreFactory(String type, String? dbPath) {
  switch (type.toLowerCase()) {
    case 'isar':
      return isarEventStoreFactory(dbPath ?? 'todo_app.isar');
    case 'memory':
      return inMemoryEventStoreFactory();
    default:
      throw ArgumentError('Unknown event store type: $type');
  }
}

SnapshotStoreFactory getSnapshotStoreFactory(String type) {
  switch (type.toLowerCase()) {
    case 'memory':
      return inMemorySnapshotStoreFactory();
    case 'null':
      return nullSnapshotStoreFactory();
    default:
      throw ArgumentError('Unknown snapshot store type: $type');
  }
}

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
      'snapshot-store',
      abbr: 's',
      defaultsTo: 'memory',
      allowed: ['memory', 'null'],
      help: 'Snapshot store type to use',
    )
    ..addOption(
      'db-path',
      help: 'Path for the Isar database (only used with --event-store=isar)',
    )
    ..addOption(
      'list-id',
      help:
          'ID of an existing todo list. If not provided, a new list will be created.',
    )
    ..addOption(
      'action',
      abbr: 'a',
      allowed: ['create', 'add', 'complete'],
      defaultsTo: 'create',
      help:
          'Action to perform: create a new list, add an item, or complete an item',
    )
    ..addOption(
      'item-id',
      help:
          'ID of the item to add or complete (required for add and complete actions)',
    )
    ..addOption(
      'title',
      help:
          'Title for the new list or item (required for create and add actions)',
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
      print('Todo List Example App\n');
      print('Usage: dart run example/todo_app.dart [options]\n');
      print('Options:');
      print(parser.usage);
      return;
    }

    final eventStoreType = results['event-store'] as String;
    final snapshotStoreType = results['snapshot-store'] as String;
    final dbPath = results['db-path'] as String?;
    final action = results['action'] as String;
    final listId = results['list-id'] as String? ?? newId();
    final itemId = results['item-id'] as String?;
    final title = results['title'] as String?;

    // Validate arguments
    if ((action == 'create' || action == 'add') && title == null) {
      print('Error: --title is required for create and add actions');
      return;
    }

    if ((action == 'add' || action == 'complete') && itemId == null) {
      print('Error: --item-id is required for add and complete actions');
      return;
    }

    // Initialize Isar for native environment
    if (eventStoreType == 'isar') {
      print('Initializing Isar native library...');
      await Isar.initializeIsarCore(download: true);
    }

    // Set up the event sourcing system
    final system = EventSourcingSystem(
        getEventStoreFactory(eventStoreType, dbPath),
        getSnapshotStoreFactory(snapshotStoreType));

    // Register event types
    Event.registerFactory(
        'TodoListCreated', (json) => TodoListCreated.fromJson(json));
    Event.registerFactory(
        'TodoItemAdded', (json) => TodoItemAdded.fromJson(json));
    Event.registerFactory(
        'TodoItemCompleted', (json) => TodoItemCompleted.fromJson(json));

    // Register aggregate type and start the system
    await system.registerAggregate<TodoListAggregate>(TodoListAggregate.new);
    await system.start();

    try {
      switch (action) {
        case 'create':
          print('\nCreating todo list with ID: $listId');
          final createList =
              CreateTodoList(listId, DateTime.now(), title ?? 'My Todo List');
          await for (var event in system.publish(createList)) {
            print('Create list event: ${event.runtimeType}');
            if (event is CommandFailed) {
              print('Failed to create list: ${event.error}');
              return;
            }
          }
          break;

        case 'add':
          print('\nAdding item: $title');
          final addItem = AddTodoItem(listId, DateTime.now(), itemId!, title!);
          await for (var event in system.publish(addItem)) {
            print('Add item event: ${event.runtimeType}');
            if (event is CommandFailed) {
              print('Failed to add item: ${event.error}');
              return;
            }
          }
          break;

        case 'complete':
          print('\nCompleting item: $itemId');
          final completeItem =
              CompleteTodoItem(listId, DateTime.now(), itemId!);
          await for (var event in system.publish(completeItem)) {
            print('Complete item event: ${event.runtimeType}');
            if (event is CommandFailed) {
              print('Failed to complete item: ${event.error}');
              return;
            }
          }
          break;
      }

      // Wait for all commands to be processed
      await system.waitForCompletion();

      // Get the final state
      final todoList =
          await system.getAggregate<TodoListAggregate>(listId, 'TodoList');

      print('\nFinal Todo List State:');
      print('List ID: ${todoList.id}');
      print('Title: ${todoList.title}');
      for (var item in todoList.items.values) {
        print(
            'Item: ${item.id}, Title: ${item.title}, Completed: ${item.isCompleted}');
      }
    } finally {
      // Clean up
      await system.stop();
    }
  } catch (e) {
    print('Error: $e');
  }
}
