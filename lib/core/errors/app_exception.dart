class AppException implements Exception {
  const AppException({
    required this.message,
    this.code = 'unknown',
    this.cause,
    this.stackTrace,
  });

  final String message;
  final String code;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => 'AppException(code: $code, message: $message)';
}
