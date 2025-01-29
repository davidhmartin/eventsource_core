import 'package:test/test.dart';
import '../../lib/src/domain/todo_list.dart';

void main() {
  group('TodoItem', () {
    test('serializes to JSON', () {
      final item = TodoItem(
        id: 'item-1',
        title: 'Buy groceries',
        isCompleted: false,
      );

      final json = item.toJson();

      expect(json, equals({
        'id': 'item-1',
        'title': 'Buy groceries',
        'isCompleted': false,
      }));
    });

    test('deserializes from JSON', () {
      final json = {
        'id': 'item-1',
        'title': 'Buy groceries',
        'isCompleted': false,
      };

      final item = TodoItem.fromJson(json);

      expect(item.id, equals('item-1'));
      expect(item.title, equals('Buy groceries'));
      expect(item.isCompleted, equals(false));
    });

    test('serialization is reversible', () {
      final original = TodoItem(
        id: 'item-1',
        title: 'Buy groceries',
        isCompleted: false,
      );

      final deserialized = TodoItem.fromJson(original.toJson());

      expect(deserialized.id, equals(original.id));
      expect(deserialized.title, equals(original.title));
      expect(deserialized.isCompleted, equals(original.isCompleted));
    });
  });

  group('TodoList', () {
    test('serializes empty list to JSON', () {
      final list = TodoList(
        id: 'list-1',
        title: 'Shopping List',
      );

      final json = list.toJson();

      expect(json, equals({
        'id': 'list-1',
        'version': 0,
        'title': 'Shopping List',
        'items': {},
      }));
    });

    test('serializes list with items to JSON', () {
      final list = TodoList(
        id: 'list-1',
        title: 'Shopping List',
      );

      final item = TodoItem(
        id: 'item-1',
        title: 'Buy groceries',
        isCompleted: false,
      );

      // Need to add item through event handling
      list._items[item.id] = item;

      final json = list.toJson();

      expect(json, equals({
        'id': 'list-1',
        'version': 0,
        'title': 'Shopping List',
        'items': {
          'item-1': {
            'id': 'item-1',
            'title': 'Buy groceries',
            'isCompleted': false,
          },
        },
      }));
    });

    test('deserializes empty list from JSON', () {
      final json = {
        'id': 'list-1',
        'version': 0,
        'title': 'Shopping List',
        'items': {},
      };

      final list = TodoList.fromJson(json);

      expect(list.id, equals('list-1'));
      expect(list.version, equals(0));
      expect(list.title, equals('Shopping List'));
      expect(list.items, isEmpty);
    });

    test('deserializes list with items from JSON', () {
      final json = {
        'id': 'list-1',
        'version': 0,
        'title': 'Shopping List',
        'items': {
          'item-1': {
            'id': 'item-1',
            'title': 'Buy groceries',
            'isCompleted': false,
          },
        },
      };

      final list = TodoList.fromJson(json);

      expect(list.id, equals('list-1'));
      expect(list.version, equals(0));
      expect(list.title, equals('Shopping List'));
      expect(list.items, hasLength(1));
      
      final item = list.items['item-1'];
      expect(item, isNotNull);
      expect(item?.id, equals('item-1'));
      expect(item?.title, equals('Buy groceries'));
      expect(item?.isCompleted, equals(false));
    });

    test('serialization is reversible', () {
      final original = TodoList(
        id: 'list-1',
        title: 'Shopping List',
      );

      final item = TodoItem(
        id: 'item-1',
        title: 'Buy groceries',
        isCompleted: false,
      );

      // Need to add item through event handling
      original._items[item.id] = item;

      final deserialized = TodoList.fromJson(original.toJson());

      expect(deserialized.id, equals(original.id));
      expect(deserialized.version, equals(original.version));
      expect(deserialized.title, equals(original.title));
      expect(deserialized.items, equals(original.items));
    });
  });
}
