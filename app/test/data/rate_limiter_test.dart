import 'package:fake_async/fake_async.dart';
import 'package:flugwacht/data/rate_limiter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  RateLimiter limiter() =>
      RateLimiter(minimumInterval: const Duration(seconds: 1));

  test('runs the first scheduled action immediately', () {
    fakeAsync((async) {
      var ran = false;
      limiter().schedule(() async => ran = true);

      async.flushMicrotasks();

      expect(ran, isTrue);
    });
  });

  test('passes the scheduled action return value through', () {
    fakeAsync((async) {
      int? result;
      limiter().schedule(() async => 42).then((value) => result = value);

      async.flushMicrotasks();

      expect(result, 42);
    });
  });

  test('spaces two back-to-back actions one interval apart', () {
    fakeAsync((async) {
      var secondRan = false;
      limiter()
        ..schedule(() async {})
        ..schedule(() async => secondRan = true);

      async.elapse(const Duration(milliseconds: 999));
      expect(secondRan, isFalse);

      async.elapse(const Duration(milliseconds: 1));
      expect(secondRan, isTrue);
    });
  });

  test('starts the spacing gate at dispatch, not at enqueue', () {
    fakeAsync((async) {
      var thirdRan = false;
      limiter()
        ..schedule(() async {})
        ..schedule(() async {})
        ..schedule(() async => thirdRan = true);

      async.elapse(const Duration(milliseconds: 1999));
      expect(thirdRan, isFalse);

      async.elapse(const Duration(milliseconds: 1));
      expect(thirdRan, isTrue);
    });
  });

  test('spaces from the previous dispatch, not from its completion', () {
    fakeAsync((async) {
      var secondRan = false;
      limiter()
        ..schedule(
          () => Future<void>.delayed(const Duration(milliseconds: 500)),
        )
        ..schedule(() async => secondRan = true);

      async.elapse(const Duration(milliseconds: 999));
      expect(secondRan, isFalse);

      async.elapse(const Duration(milliseconds: 1));
      expect(secondRan, isTrue);
    });
  });

  test('serializes: an action longer than the interval delays the next', () {
    fakeAsync((async) {
      var secondRan = false;
      limiter()
        ..schedule(() => Future<void>.delayed(const Duration(seconds: 3)))
        ..schedule(() async => secondRan = true);

      async.elapse(const Duration(milliseconds: 2999));
      expect(secondRan, isFalse);

      async
        ..elapse(const Duration(milliseconds: 1))
        ..flushMicrotasks();
      expect(secondRan, isTrue);
    });
  });

  test('dispatches immediately after more than one interval of idle time', () {
    fakeAsync((async) {
      final scheduler = limiter()..schedule(() async {});
      async.elapse(const Duration(milliseconds: 1500));

      var secondRan = false;
      scheduler.schedule(() async => secondRan = true);
      async.flushMicrotasks();

      expect(secondRan, isTrue);
    });
  });

  test('completes queued actions in FIFO order', () {
    fakeAsync((async) {
      final scheduler = limiter();
      final order = <int>[];
      for (var index = 0; index < 3; index++) {
        scheduler.schedule(() async => order.add(index));
      }

      async.elapse(const Duration(seconds: 3));

      expect(order, [0, 1, 2]);
    });
  });

  test('propagates an async action error without poisoning the chain', () {
    fakeAsync((async) {
      var errorCaught = false;
      var secondRan = false;
      limiter()
        ..schedule<void>(() async => throw StateError('boom')).then(
          (_) {},
          onError: (_) {
            errorCaught = true;
          },
        )
        ..schedule(() async => secondRan = true);

      async.flushMicrotasks();
      expect(errorCaught, isTrue);
      expect(secondRan, isFalse);

      async.elapse(const Duration(seconds: 1));
      expect(secondRan, isTrue);
    });
  });

  test('propagates a synchronous action throw without deadlocking', () {
    fakeAsync((async) {
      var errorCaught = false;
      var secondRan = false;
      limiter()
        ..schedule<void>(() => throw StateError('boom')).then(
          (_) {},
          onError: (_) {
            errorCaught = true;
          },
        )
        ..schedule(() async => secondRan = true);

      async.flushMicrotasks();
      expect(errorCaught, isTrue);

      async.elapse(const Duration(seconds: 1));
      expect(secondRan, isTrue);
    });
  });
}
