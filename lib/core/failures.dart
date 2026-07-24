import 'package:equatable/equatable.dart';

/// Base Failure class
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Server/Network Failures
class ServerFailure extends Failure {
  const ServerFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

/// Authentication Failures
class AuthenticationFailure extends Failure {
  const AuthenticationFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

class UserNotFoundFailure extends Failure {
  const UserNotFoundFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

/// Validation Failures
class ValidationFailure extends Failure {
  const ValidationFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

class InvalidInputFailure extends Failure {
  const InvalidInputFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

/// Data Failures
class DataFailure extends Failure {
  const DataFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

class ParseFailure extends Failure {
  const ParseFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

/// File/Upload Failures
class FileFailure extends Failure {
  const FileFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

class UploadFailure extends Failure {
  const UploadFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

class FileSizeFailure extends Failure {
  const FileSizeFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

class InvalidFileTypeFailure extends Failure {
  const InvalidFileTypeFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

/// Storage/Cache Failures
class CacheFailure extends Failure {
  const CacheFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

class StorageFailure extends Failure {
  const StorageFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

/// Business Logic Failures
class ProductFailure extends Failure {
  const ProductFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

class OrderFailure extends Failure {
  const OrderFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

class PaymentFailure extends Failure {
  const PaymentFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

/// Unknown Failure
class UnknownFailure extends Failure {
  const UnknownFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}
