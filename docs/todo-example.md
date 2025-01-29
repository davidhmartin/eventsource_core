# TODO List Example - Event Sourcing Specification

## Domain Overview
A simple TODO list application that allows users to create lists, add items to them, and mark items as complete or incomplete. This serves as a demonstration of basic event sourcing patterns.

## Aggregate

### TodoList
The root aggregate representing a TODO list. Contains all items and enforces business rules around item operations.
(Mandatory fields, such as id and version, are omitted for brevity)

#### Properties
- `title: String` - Name of the TODO list
- `items: Map<String, TodoItem>` - Collection of items where TodoItem is a value object

#### Value Object: TodoItem
A value object representing a single item in the list.
- `id: String` - Unique identifier for the item
- `title: String` - Description of the TODO item
- `isCompleted: bool` - Completion status

#### Business Rules
1. List title cannot be empty
2. Items must have unique IDs within the list
3. Cannot complete/uncomplete non-existent items
4. Cannot complete already completed items
5. Cannot uncomplete items that aren't completed

## Commands

### CreateTodoList
Creates a new TODO list.

#### Parameters
- `title: String` - Name of the list

#### Validation
- Title must not be empty
- List ID must not already exist

### AddTodoItem
Adds a new item to a TODO list.

#### Parameters
- `listId: String` - ID of the list to add to
- `itemId: String` - Unique identifier for the new item
- `title: String` - Description of the TODO item

#### Validation
- List must exist
- Item ID must be unique within list
- Item title must not be empty

### CompleteTodoItem
Marks a TODO item as completed.

#### Parameters
- `listId: String` - ID of the containing list
- `itemId: String` - ID of the item to complete

#### Validation
- List must exist
- Item must exist in list
- Item must not already be completed

### UncompleteTodoItem
Marks a completed TODO item as not completed.

#### Parameters
- `listId: String` - ID of the containing list
- `itemId: String` - ID of the item to uncomplete

#### Validation
- List must exist
- Item must exist in list
- Item must currently be completed

## Events

### TodoListCreated
Emitted when a new TODO list is created.

#### Properties
- `listId: String`
- `title: String`
- `timestamp: DateTime`

### TodoItemAdded
Emitted when a new item is added to a list.

#### Properties
- `listId: String`
- `itemId: String`
- `title: String`
- `timestamp: DateTime`

### TodoItemCompleted
Emitted when an item is marked as completed.

#### Properties
- `listId: String`
- `itemId: String`
- `timestamp: DateTime`

### TodoItemUncompleted
Emitted when an item is marked as not completed.

#### Properties
- `listId: String`
- `itemId: String`
- `timestamp: DateTime`

## Read Models

### TodoListOverview
A denormalized view of TODO lists showing summary information.

#### Schema
```dart
class TodoListOverview {
  final String id;
  final String title;
  final int totalItems;
  final int completedItems;
  final DateTime lastUpdated;
}
```

#### Updated By
- `TodoListCreated`: Creates new overview
- `TodoItemAdded`: Increments totalItems
- `TodoItemCompleted`: Increments completedItems
- `TodoItemUncompleted`: Decrements completedItems

### TodoListDetail
A complete view of a TODO list with all items.

#### Schema
```dart
class TodoListDetail {
  final String id;
  final String title;
  final DateTime lastUpdated;
  final List<TodoItemDetail> items;
}

class TodoItemDetail {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime createdAt;
}
```

#### Updated By
- `TodoListCreated`: Creates new detail view
- `TodoItemAdded`: Adds new item to items list
- `TodoItemCompleted`: Updates item completion status to true
- `TodoItemUncompleted`: Updates item completion status to false

### CompletionStats
Statistical view of completion rates.

#### Schema
```dart
class CompletionStats {
  final String listId;
  final double completionRate;  // percentage of completed items
  final int totalItems;
  final int completedItems;
  final int pendingItems;
}
```

#### Updated By
- `TodoListCreated`: Creates new stats record
- `TodoItemAdded`: Updates totals
- `TodoItemCompleted`: Updates completion counts and rate
- `TodoItemUncompleted`: Updates completion counts and rate

## Query Interface

### Available Queries
1. `GetTodoListOverviews(): List<TodoListOverview>`
   - Returns overview of all TODO lists

2. `GetTodoListDetail(String listId): TodoListDetail`
   - Returns detailed view of a specific list including all items

3. `GetCompletionStats(String listId): CompletionStats`
   - Returns completion statistics for a specific list

4. `GetPendingItems(String listId): List<TodoItemDetail>`
   - Returns list of uncompleted items

5. `GetCompletedItems(String listId): List<TodoItemDetail>`
   - Returns list of completed items
