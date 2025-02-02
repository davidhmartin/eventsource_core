import 'package:eventsource_core/eventsource_core.dart';
import 'package:ulid/ulid.dart';

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

  TodoListCreated(Ulid id, Ulid aggregateId, DateTime timestamp, this.title)
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
}

class TodoItemAdded extends Event {
  final String itemId;
  final String title;

  TodoItemAdded(
      Ulid id, Ulid aggregateId, DateTime timestamp, this.itemId, this.title)
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
}

class TodoItemCompleted extends Event {
  final String itemId;

  TodoItemCompleted(Ulid id, Ulid aggregateId, DateTime timestamp, this.itemId)
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
}

// Commands
class CreateTodoList extends Command {
  final String title;

  CreateTodoList(Ulid aggregateId, DateTime timestamp, this.title)
      : super(aggregateId, 'TodoList', timestamp);

  @override
  String get type => 'CreateTodoList';

  @override
  Event? handle(Aggregate aggregate) {
    if (title.isEmpty) {
      throw ArgumentError('Title cannot be empty');
    }
    return TodoListCreated(Ulid(), aggregateId, timestamp, title);
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
}

class AddTodoItem extends Command {
  final String itemId;
  final String title;

  AddTodoItem(Ulid aggregateId, DateTime timestamp, this.itemId, this.title)
      : super(aggregateId, 'TodoList', timestamp);

  @override
  String get type => 'AddTodoItem';

  @override
  Event? handle(Aggregate aggregate) {
    if (title.isEmpty) {
      throw ArgumentError('Title cannot be empty');
    }

    var todoList = aggregate as TodoListAggregate;
    if (todoList.items.containsKey(itemId)) {
      throw ArgumentError('Item ID already exists');
    }

    return TodoItemAdded(Ulid(), aggregateId, timestamp, itemId, title);
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
}

class CompleteTodoItem extends Command {
  final String itemId;

  CompleteTodoItem(Ulid aggregateId, DateTime timestamp, this.itemId)
      : super(aggregateId, 'TodoList', timestamp);

  @override
  String get type => 'CompleteTodoItem';

  @override
  Event? handle(Aggregate aggregate) {
    var todoList = aggregate as TodoListAggregate;
    var item = todoList.items[itemId];

    if (item == null) {
      throw ArgumentError('Item does not exist');
    }
    if (item.isCompleted) {
      throw ArgumentError('Item is already completed');
    }

    return TodoItemCompleted(Ulid(), aggregateId, timestamp, itemId);
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

// Example usage
void main() async {
  // Set up the event sourcing system
  final system = EventSourcingSystem(
    eventStoreFactory: EventStores.memory,
    snapshotStoreFactory: SnapshotStores.memory,
  )..registerAggregate<TodoListAggregate>(TodoListAggregate.new);

  // Start processing commands
  await system.start();

  try {
    // Create a new todo list
    final listId = Ulid();
    print('\nCreating todo list with ID: $listId');
    final createList = CreateTodoList(listId, DateTime.now(), 'My Todo List');
    await for (var event in system.publish(createList)) {
      print('Create list event: ${event.runtimeType}');
      if (event is CommandFailed) {
        print('Failed to create list: ${event.error}');
        return;
      }
      if (event is CommandHandled) {
        print(
            'List created successfully with event: ${event.generatedEvent?.type}');
      }
      if (event is EventPublished) {
        print('Event published: ${event.event.type}');
      }
    }

    // Add some items
    print('\nAdding item 1: Buy groceries');
    final addItem1 =
        AddTodoItem(listId, DateTime.now(), 'item1', 'Buy groceries');
    await for (var event in system.publish(addItem1)) {
      print('Add item 1 event: ${event.runtimeType}');
      if (event is CommandFailed) {
        print('Failed to add item 1: ${event.error}');
        return;
      }
      if (event is CommandHandled) {
        print(
            'Item 1 added successfully with event: ${event.generatedEvent?.type}');
      }
      if (event is EventPublished) {
        print('Event published: ${event.event.type}');
      }
    }

    print('\nAdding item 2: Call plumber');
    final addItem2 =
        AddTodoItem(listId, DateTime.now(), 'item2', 'Call plumber');
    await for (var event in system.publish(addItem2)) {
      print('Add item 2 event: ${event.runtimeType}');
      if (event is CommandFailed) {
        print('Failed to add item 2: ${event.error}');
        return;
      }
      if (event is CommandHandled) {
        print(
            'Item 2 added successfully with event: ${event.generatedEvent?.type}');
      }
      if (event is EventPublished) {
        print('Event published: ${event.event.type}');
      }
    }

    // Complete an item
    print('\nCompleting item 1');
    final completeItem = CompleteTodoItem(listId, DateTime.now(), 'item1');
    await for (var event in system.publish(completeItem)) {
      print('Complete item event: ${event.runtimeType}');
      if (event is CommandFailed) {
        print('Failed to complete item: ${event.error}');
        return;
      }
      if (event is CommandHandled) {
        print(
            'Item completed successfully with event: ${event.generatedEvent?.type}');
      }
      if (event is EventPublished) {
        print('Event published: ${event.event.type}');
      }
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
}
