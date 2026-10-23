import 'package:flutter/foundation.dart';

// HOA05 Step 6: simple logger.
// debugPrint output shows up in the VS Code Debug Console and in `flutter logs`.
void logInfo(String tag, String message) {
  if (kDebugMode) debugPrint('[$tag] $message');
}

void logError(String tag, Object error, [StackTrace? stack]) {
  if (kDebugMode) {
    debugPrint('[$tag] ERROR: $error');
    if (stack != null) debugPrint(stack.toString());
  }
}