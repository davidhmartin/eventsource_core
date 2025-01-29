import 'package:eventsource_core/eventsource_core.dart';

/// A value object representing a single item in a todo list
class TodoItem {
  final String id;
  final String title;
  final bool isCompleted;

  const TodoItem({
    required this.id,
    required this.title,
    required this.isCompleted,
  });

  TodoItem copyWith({
    String? id,
    String? title,
    bool? isCompleted,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'isCompleted': isCompleted,
  };

  factory TodoItem.fromJson(Map<String, dynamic> json) => TodoItem(
    id: json['id'] as String,
    title: json['title'] as String,
    isCompleted: json['isCompleted'] as bool,
  );
}

/// The root aggregate representing a TODO list
class TodoList extends Aggregate {
  String _title;
  final Map<String, TodoItem> _items;

  TodoList({
    required String id,
    required String title,
  }) : _title = title,
       _items = {},
       super(id);

  // Getters
  String get title => _title;
  Map<String, TodoItem> get items => Map.unmodifiable(_items);

  // Business rule validations
  void _validateTitle(String title) {
    if (title.isEmpty) {
      throw ArgumentError('List title cannot be empty');
    }
  }

  void _validateItemId(String itemId) {
    if (_items.containsKey(itemId)) {
      throw ArgumentError('Item ID already exists in list');
    }
  }

  void _validateItemExists(String itemId) {
    if (!_items.containsKey(itemId)) {
      throw ArgumentError('Item does not exist in list');
    }
  }

  void _validateItemCompletion(String itemId, bool complete) {
    final item = _items[itemId];
    if (item == null) {
      throw ArgumentError('Item does not exist in list');
    }
    if (item.isCompleted == complete) {
      throw ArgumentError(
          complete ? 'Item is already completed' : 'Item is already uncompleted');
    }
  }

  @override
  void applyEventToState(Event event) {
    // TODO: Implement event handling
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'version': version,
    'title': _title,
    'items': _items.map((key, value) => MapEntry(key, value.toJson())),
  };

  factory TodoList.fromJson(Map<String, dynamic> json) {
    final list = TodoList(
      id: json['id'] as String,
      title: json['title'] as String,
    );
    
    final items = (json['items'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(
        key, 
        TodoItem.fromJson(value as Map<String, dynamic>)
      )
    );
    list._items.addAll(items);
    
    return list;
  }
}
