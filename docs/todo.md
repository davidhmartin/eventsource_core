# Event Sourcing Framework Development Tasks

## 1. Core Domain Components
- [X] Implement base `Aggregate` class
  - State management
  - Event application logic
  - Version tracking
- [X] Complete base `Event` and `Command` interfaces
  - Add validation methods
  - Implement serialization support
- [X] Create `AggregateStore`
  - Implement snapshot integration
  - Add event replay functionality
  - Handle aggregate reconstruction

## 2. Command Processing
- [X] Implement `CommandHandler` base class
  - Add validation infrastructure
  - Error handling patterns
- [X] Build `CommandProcessor` with queue
  - Command serialization
  - Concurrent command handling
  - Error recovery

## 3. Begin Example Application 
- [ ] Decide on example (e.g. box packing, irc, account management, etc.)
- [ ] Start implementing. 

## 4. Event subscriptions and read model projection
- [ ] Implement `EventStore` for event subscription and read model projection
  - Event filtering
  - Event processing strategies
  - Read model updates

## 5. Finish Example Application 
- [ ] Implement the example - events, commands, aggregates, read model
- [ ] Add command line client

## 6. Documentation
- [ ] API Documentation
- [ ] Document the example project(s)
- [ ] README

## 7. Release v1.0
- [ ] Add changelog
- [ ] Github release (whatever that means)
- [ ] publicity (dart forums, etc.  Figure this out...)
