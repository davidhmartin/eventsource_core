# eventsource_core

A lightweight, flexible event sourcing framework for Dart.

## Features

- Clean, simple API for implementing event sourcing patterns
- Support for commands, events, and aggregates
- Built-in command queue for serial processing
- Optional snapshot support for performance optimization
- Framework-agnostic design

## Getting started

Add `eventsource_core` to your `pubspec.yaml`:

```yaml
dependencies:
  eventsource_core: ^0.1.0
```

## Usage

```dart
// Define an aggregate
class UserAggregate extends Aggregate<UserState> {
  @override
  void applyEvent(Event event) {
    if (event is UserCreatedEvent) {
      _state = UserState(event.userId, event.name, event.email);
    }
  }
}

// Define a command handler
class CreateUserCommandHandler extends CommandHandler<CreateUserCommand, UserAggregate> {
  @override
  Event? handle(CreateUserCommand command, UserAggregate aggregate) {
    if (aggregate.state != null) {
      throw ValidationError('User already exists');
    }
    
    return UserCreatedEvent(
      aggregateId: command.userId,
      name: command.name,
      email: command.email
    );
  }
}
```

## Additional information

For more examples and documentation, visit the [GitHub repository](https://github.com/yourusername/eventsource_core).
