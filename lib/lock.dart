import 'dart:async';

/// A simple mutex lock for synchronizing access to shared resources
class Lock {
  Completer<void>? _completer;

  /// Executes the given function while holding the lock
  Future<T> synchronized<T>(Future<T> Function() fn) async {
    while (_completer != null) {
      await _completer!.future;
    }

    _completer = Completer<void>();
    try {
      final result = await fn();
      return result;
    } finally {
      _completer?.complete();
      _completer = null;
    }
  }
}
