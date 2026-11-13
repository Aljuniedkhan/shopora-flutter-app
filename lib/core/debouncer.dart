import 'dart:async';

import 'package:flutter/foundation.dart';

/// Waits until the user stops typing for [delay] before running an action.
///
/// Every call cancels the previous timer, so only the last call runs.
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() => _timer?.cancel();
}
