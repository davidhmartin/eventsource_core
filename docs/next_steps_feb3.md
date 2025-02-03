# Event Sourcing Framework Next Steps

## Immediate Priority

### 1. Read Model Projections
- Implement read model store using Isar
- Create projection handler for event subscriptions
- Add query methods for efficient data retrieval
- Extend todo app CLI with read model queries
  - `--action=list`: Show all todo lists
  - `--action=view`: Show details of a specific list

### 2. Testing Infrastructure
- Unit tests for core framework components
- Integration tests with Isar event store
- Test utilities for event sourcing applications
- Performance tests for large event streams
- Test helpers for implementing event-sourced applications

### 3. Error Handling
- Robust concurrent modification handling
- Command failure recovery mechanisms
- Event store consistency checks
- Clear error messages and recovery suggestions
- Retry strategies for transient failures

## Near-term Priority

### 4. Logging
- Implement structured logging using `logging` package
- Define appropriate log levels
  - finest: Detailed debugging
  - finer: Less detailed debugging
  - fine: Basic debugging
  - config: Configuration events
  - info: Runtime events
  - warning: Potential issues
  - severe: Serious issues
  - shout: Critical failures
- Add correlation IDs for command/event tracking
- Separate business logic from framework logs

### 5. CLI Tools
- Event store inspector
  - View all events
  - Filter by aggregate, type, time range
  - Export events
- Aggregate state viewer
- Read model rebuilder
- System health checker
- Backup/restore utilities

### 6. Flutter UI Example
- Todo app with Flutter UI
- State management (Bloc/Riverpod)
- Optimistic updates
- Real-time changes
- Error handling and retries

## Future Enhancements

### 7. Documentation
- API documentation with examples
- Architecture decision records
- Best practices guide
- Migration guides
- Sample implementations

### 8. Performance Optimization
- Snapshot strategies
- Event store indexing
- Batch processing
- Caching strategies
- Read model optimization

## Notes
- All new features should include appropriate tests
- Focus on maintainable, well-documented code
- Consider Flutter/mobile use cases in design decisions
- Keep the core framework lightweight and extensible

## Questions to Consider
1. How to handle schema evolution?
2. What monitoring/metrics should we add?
3. How to support multiple read models?
4. What security features are needed?
5. How to handle very large event streams?
