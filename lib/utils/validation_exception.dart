// Thrown when data fails validation (shown to the user as a plain message).
class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);

  @override
  String toString() => message;
}