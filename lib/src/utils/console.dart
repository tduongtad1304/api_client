import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show kDebugMode;

class Console {
  static void log(String message) {
    if (kDebugMode) {
      developer.log(message);
    }
  }
}
