enum AppErrorCode {
  unauthorized,
  forbidden,
  notFound,
  networkError,
  serverError,
  validationError,
  migrationError,
  storageError,
}

class AppException implements Exception {
  final AppErrorCode code;
  final String message;
  final dynamic details;

  const AppException({
    required this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() => 'AppException(${code.name}): $message';
}
