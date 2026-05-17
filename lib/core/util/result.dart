/// A minimal sealed result type for operations that can fail without throwing.
///
/// Use [Result] where a caller should explicitly handle the error path — e.g.
/// file imports, parsing, or repository writes that may fail recoverably.
/// Because it is `sealed`, a `switch` over [Ok] / [Err] is exhaustive:
///
/// ```dart
/// final label = switch (result) {
///   Ok(:final value) => 'got $value',
///   Err(:final error) => 'failed: $error',
/// };
/// ```
sealed class Result<T> {
  const Result();

  /// Wraps a successful [value].
  const factory Result.ok(T value) = Ok<T>;

  /// Wraps a failure [error] with an optional [stackTrace].
  const factory Result.err(Object error, [StackTrace? stackTrace]) = Err<T>;

  /// Whether this is an [Ok].
  bool get isOk => this is Ok<T>;

  /// Whether this is an [Err].
  bool get isErr => this is Err<T>;

  /// The success value, or `null` if this is an [Err].
  T? get valueOrNull => switch (this) {
    Ok<T>(:final value) => value,
    Err<T>() => null,
  };

  /// The error object, or `null` if this is an [Ok].
  Object? get errorOrNull => switch (this) {
    Ok<T>() => null,
    Err<T>(:final error) => error,
  };

  /// Returns the success value if this is an [Ok], otherwise [fallback].
  T getOrElse(T fallback) => switch (this) {
    Ok<T>(:final value) => value,
    Err<T>() => fallback,
  };
}

/// The success variant of [Result].
final class Ok<T> extends Result<T> {
  const Ok(this.value);

  /// The wrapped success value.
  final T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Ok<T> && other.value == value);

  @override
  int get hashCode => Object.hash(Ok<T>, value);

  @override
  String toString() => 'Ok($value)';
}

/// The failure variant of [Result].
final class Err<T> extends Result<T> {
  const Err(this.error, [this.stackTrace]);

  /// The error that caused the failure.
  final Object error;

  /// The stack trace captured when the failure occurred, if available.
  final StackTrace? stackTrace;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Err<T> &&
          other.error == error &&
          other.stackTrace == stackTrace);

  @override
  int get hashCode => Object.hash(Err<T>, error, stackTrace);

  @override
  String toString() => 'Err($error)';
}
