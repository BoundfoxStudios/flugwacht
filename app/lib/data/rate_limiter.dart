import 'dart:async';

class RateLimiter {
  RateLimiter({required this.minimumInterval});

  final Duration minimumInterval;

  Future<void> _previousTurn = Future<void>.value();

  Future<T> schedule<T>(Future<T> Function() action) {
    final previousTurn = _previousTurn;
    final turn = Completer<void>();
    _previousTurn = turn.future;
    return _dispatch(previousTurn, action, turn);
  }

  Future<T> _dispatch<T>(
    Future<void> previousTurn,
    Future<T> Function() action,
    Completer<void> turn,
  ) async {
    await previousTurn;
    final spacingElapsed = Future<void>.delayed(minimumInterval);
    try {
      return await action();
    } finally {
      turn.complete(spacingElapsed);
    }
  }
}
