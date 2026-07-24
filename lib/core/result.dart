import 'package:equatable/equatable.dart';

/// Result Type - نتيجة العملية إما Success أو Failure
abstract class Result<T> extends Equatable {
  const Result();

  /// تحويل النتيجة بناءً على الحالة
  R fold<R>(
    R Function(Failure) onFailure,
    R Function(T) onSuccess,
  );

  /// الحصول على البيانات أو null
  T? getOrNull();

  /// الحصول على الخطأ أو null
  Failure? getErrorOrNull();

  /// التحقق من النجاح
  bool get isSuccess;

  /// التحقق من الفشل
  bool get isFailure;
}

/// Success Result
class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);

  @override
  R fold<R>(
    R Function(Failure) onFailure,
    R Function(T) onSuccess,
  ) =>
      onSuccess(data);

  @override
  T? getOrNull() => data;

  @override
  Failure? getErrorOrNull() => null;

  @override
  bool get isSuccess => true;

  @override
  bool get isFailure => false;

  @override
  List<Object?> get props => [data];

  @override
  String toString() => 'Success(data: $data)';
}

/// Failure Result
class Failure<T> extends Result<T> {
  final AppFailure error;

  const Failure(this.error);

  @override
  R fold<R>(
    R Function(AppFailure) onFailure,
    R Function(T) onSuccess,
  ) =>
      onFailure(error);

  @override
  T? getOrNull() => null;

  @override
  AppFailure? getErrorOrNull() => error;

  @override
  bool get isSuccess => false;

  @override
  bool get isFailure => true;

  @override
  List<Object?> get props => [error];

  @override
  String toString() => 'Failure(error: $error)';
}

/// Base App Failure Class
abstract class AppFailure extends Equatable {
  final String message;
  final String? code;

  const AppFailure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Server Failure
class ServerAppFailure extends AppFailure {
  const ServerAppFailure({required String message, String? code})
      : super(message: message, code: code);
}

/// Network Failure
class NetworkAppFailure extends AppFailure {
  const NetworkAppFailure({required String message, String? code})
      : super(message: message, code: code);
}

/// Validation Failure
class ValidationAppFailure extends AppFailure {
  const ValidationAppFailure({required String message, String? code})
      : super(message: message, code: code);
}

/// Not Found Failure
class NotFoundAppFailure extends AppFailure {
  const NotFoundAppFailure({required String message, String? code})
      : super(message: message, code: code);
}

/// Authentication Failure
class AuthAppFailure extends AppFailure {
  const AuthAppFailure({required String message, String? code})
      : super(message: message, code: code);
}

/// File Failure
class FileAppFailure extends AppFailure {
  const FileAppFailure({required String message, String? code})
      : super(message: message, code: code);
}

/// Unknown Failure
class UnknownAppFailure extends AppFailure {
  const UnknownAppFailure({required String message, String? code})
      : super(message: message, code: code);
}

/// Extension على Result للـ async handling
extension ResultExtension<T> on Future<Result<T>> {
  /// حول الـ Future<Result> إلى single value أو throw exception
  Future<T> getOrThrow() async {
    final result = await this;
    return result.fold(
      (failure) => throw Exception(failure.message),
      (data) => data,
    );
  }
}
