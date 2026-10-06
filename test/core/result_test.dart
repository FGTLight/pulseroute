import 'package:flutter_test/flutter_test.dart';
import 'package:pulseroute/core/errors/failures.dart';
import 'package:pulseroute/core/errors/result.dart';

void main() {
  test('Success exposes its value', () {
    const Result<int> result = Success(42);

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, 42);
    expect(result.failureOrNull, isNull);
    expect(result.fold((v) => 'ok $v', (f) => f.message), 'ok 42');
  });

  test('Err exposes its failure', () {
    const Result<int> result = Err(NetworkFailure());

    expect(result.isSuccess, isFalse);
    expect(result.valueOrNull, isNull);
    expect(result.failureOrNull, const NetworkFailure());
    expect(
      result.fold((v) => 'ok', (f) => f.message),
      'You appear to be offline.',
    );
  });
}
