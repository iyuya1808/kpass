import 'package:kpass/core/errors/failures.dart';
import 'package:kpass/core/errors/error_handler.dart';

/// A Result type that represents either a success value or a failure
/// This is similar to Either&lt;Failure, T&gt; but more explicit
sealed class Result<T> {
  const Result();

  /// Create a success result
  const factory Result.success(T value) = Success<T>;

  /// Create a failure result
  const factory Result.failure(Failure failure) = ResultFailure<T>;

  /// Check if this result is a success
  bool get isSuccess => this is Success<T>;

  /// Check if this result is a failure
  bool get isFailure => this is ResultFailure<T>;

  /// Get the success value, or null if this is a failure
  T? get valueOrNull => switch (this) {
    Success<T>(value: final value) => value,
    ResultFailure<T>() => null,
  };

  /// Get the failure, or null if this is a success
  Failure? get failureOrNull => switch (this) {
    Success<T>() => null,
    ResultFailure<T>(failure: final failure) => failure,
  };

  /// Transform the success value if present
  Result<R> map<R>(R Function(T value) transform) {
    return switch (this) {
      Success<T>(value: final value) => Result.success(transform(value)),
      ResultFailure<T>(failure: final failure) => Result.failure(failure),
    };
  }

  /// Transform the success value asynchronously if present
  Future<Result<R>> mapAsync<R>(Future<R> Function(T value) transform) async {
    return switch (this) {
      Success<T>(value: final value) => Result.success(await transform(value)),
      ResultFailure<T>(failure: final failure) => Result.failure(failure),
    };
  }

  /// Chain another operation that returns a Result
  Result<R> flatMap<R>(Result<R> Function(T value) transform) {
    return switch (this) {
      Success<T>(value: final value) => transform(value),
      ResultFailure<T>(failure: final failure) => Result.failure(failure),
    };
  }

  /// Chain another async operation that returns a Result
  Future<Result<R>> flatMapAsync<R>(
    Future<Result<R>> Function(T value) transform,
  ) async {
    return switch (this) {
      Success<T>(value: final value) => await transform(value),
      ResultFailure<T>(failure: final failure) => Result.failure(failure),
    };
  }

  /// Transform the failure if present
  Result<T> mapFailure(Failure Function(Failure failure) transform) {
    return switch (this) {
      Success<T>() => this,
      ResultFailure<T>(failure: final failure) => Result.failure(transform(failure)),
    };
  }

  /// Execute a function on success
  Result<T> onSuccess(void Function(T value) action) {
    if (this case Success<T>(value: final value)) {
      action(value);
    }
    return this;
  }

  /// Execute a function on failure
  Result<T> onFailure(void Function(Failure failure) action) {
    if (this case ResultFailure<T>(failure: final failure)) {
      action(failure);
    }
    return this;
  }

  /// Get the value or throw the failure
  T getOrThrow() {
    return switch (this) {
      Success<T>(value: final value) => value,
      ResultFailure<T>(failure: final failure) => throw failure,
    };
  }

  /// Get the value or return a default
  T getOrElse(T defaultValue) {
    return switch (this) {
      Success<T>(value: final value) => value,
      ResultFailure<T>() => defaultValue,
    };
  }

  /// Get the value or compute a default from the failure
  T getOrElseWith(T Function(Failure failure) defaultValue) {
    return switch (this) {
      Success<T>(value: final value) => value,
      ResultFailure<T>(failure: final failure) => defaultValue(failure),
    };
  }

  /// Fold the result into a single value
  R fold<R>(
    R Function(Failure failure) onFailure,
    R Function(T value) onSuccess,
  ) {
    return switch (this) {
      Success<T>(value: final value) => onSuccess(value),
      ResultFailure<T>(failure: final failure) => onFailure(failure),
    };
  }

  /// Convert to a nullable value
  T? toNullable() => valueOrNull;

  @override
  String toString() {
    return switch (this) {
      Success<T>(value: final value) => 'Success($value)',
      ResultFailure<T>(failure: final failure) => 'Failure($failure)',
    };
  }
}

/// Success case of Result
final class Success<T> extends Result<T> {
  final T value;

  const Success(this.value);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Success<T> && other.value == value);
  }

  @override
  int get hashCode => value.hashCode;
}

/// Failure case of Result
final class ResultFailure<T> extends Result<T> {
  final Failure failure;

  const ResultFailure(this.failure);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ResultFailure<T> && other.failure == failure);
  }

  @override
  int get hashCode => failure.hashCode;
}

/// Extension methods for Future&lt;Result&lt;T&gt;&gt;
extension FutureResultExtensions<T> on Future<Result<T>> {
  /// Transform the success value asynchronously if present
  Future<Result<R>> mapAsync<R>(Future<R> Function(T value) transform) async {
    final result = await this;
    return result.mapAsync(transform);
  }

  /// Chain another async operation that returns a Result
  Future<Result<R>> flatMapAsync<R>(
    Future<Result<R>> Function(T value) transform,
  ) async {
    final result = await this;
    return result.flatMapAsync(transform);
  }

  /// Execute a function on success
  Future<Result<T>> onSuccess(void Function(T value) action) async {
    final result = await this;
    return result.onSuccess(action);
  }

  /// Execute a function on failure
  Future<Result<T>> onFailure(void Function(Failure failure) action) async {
    final result = await this;
    return result.onFailure(action);
  }

  /// Get the value or return a default
  Future<T> getOrElse(T defaultValue) async {
    final result = await this;
    return result.getOrElse(defaultValue);
  }

  /// Fold the result into a single value
  Future<R> fold<R>(
    R Function(Failure failure) onFailure,
    R Function(T value) onSuccess,
  ) async {
    final result = await this;
    return result.fold(onFailure, onSuccess);
  }
}

/// Utility functions for working with Results
class ResultUtils {
  /// Combine multiple Results into a single Result containing a list
  static Result<List<T>> combine<T>(List<Result<T>> results) {
    final values = <T>[];
    
    for (final result in results) {
      switch (result) {
        case Success<T>(value: final value):
          values.add(value);
        case ResultFailure<T>(failure: final failure):
          return Result.failure(failure);
      }
    }
    
    return Result.success(values);
  }

  /// Execute a function that might throw and wrap the result
  static Result<T> tryCall<T>(T Function() function) {
    try {
      return Result.success(function());
    } catch (error, stackTrace) {
      final failure = _convertErrorToFailure(error, stackTrace);
      return Result.failure(failure);
    }
  }

  /// Execute an async function that might throw and wrap the result
  static Future<Result<T>> tryCallAsync<T>(
    Future<T> Function() function,
  ) async {
    try {
      final value = await function();
      return Result.success(value);
    } catch (error, stackTrace) {
      final failure = _convertErrorToFailure(error, stackTrace);
      return Result.failure(failure);
    }
  }

  static Failure _convertErrorToFailure(dynamic error, StackTrace stackTrace) {
    // Use the ErrorHandler to convert the error to a failure
    return ErrorHandler.handleException(error, stackTrace);
  }
}

/// Extension for converting nullable values to Results
extension NullableToResult<T> on T? {
  /// Convert a nullable value to a Result
  Result<T> toResult([Failure? failure]) {
    if (this != null) {
      return Result.success(this as T);
    } else {
      return Result.failure(
        failure ?? const GeneralFailure(
          message: 'Value is null',
          code: 'NULL_VALUE',
        ),
      );
    }
  }
}

