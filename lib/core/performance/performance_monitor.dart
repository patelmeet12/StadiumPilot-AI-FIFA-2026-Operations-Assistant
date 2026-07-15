import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

class PerformanceMonitor {
  static final PerformanceMonitor instance = PerformanceMonitor._internal();

  PerformanceMonitor._internal() {
    if (!kReleaseMode) {
      _startMonitoring();
    }
  }

  double _currentFps = 60.0;
  double get currentFps => _currentFps;

  final StreamController<double> _fpsController = StreamController<double>.broadcast();
  Stream<double> get fpsStream => _fpsController.stream;

  final List<int> _jankFrames = []; // Buffer of jank durations (ms)
  List<int> get jankFrames => List.unmodifiable(_jankFrames);

  DateTime? _lastFrameTime;

  void _startMonitoring() {
    SchedulerBinding.instance.addPersistentFrameCallback((_) {
      final now = DateTime.now();
      if (_lastFrameTime != null) {
        final elapsed = now.difference(_lastFrameTime!).inMicroseconds;
        if (elapsed > 0) {
          final fps = 1000000.0 / elapsed;
          // Apply low-pass filter to smooth the FPS value
          _currentFps = (_currentFps * 0.9) + (fps * 0.1);
          if (_currentFps > 60.0) _currentFps = 60.0;
          _fpsController.add(_currentFps);

          // If frame took more than 16.6ms, log as a jank frame
          final elapsedMs = elapsed ~/ 1000;
          if (elapsedMs > 16) {
            _jankFrames.add(elapsedMs);
            if (_jankFrames.length > 50) {
              _jankFrames.removeAt(0); // circular buffer
            }
          }
        }
      }
      _lastFrameTime = now;
    });
  }

  void dispose() {
    _fpsController.close();
  }
}
