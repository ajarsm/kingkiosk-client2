import 'dart:async';
import 'package:flutter/foundation.dart';

/// Global error handler for the application
class ErrorHandler {
  // Private constructor to prevent instantiation
  ErrorHandler._();
  
  /// Initialize the error handler
  static void init() {
    // Handle Flutter errors
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kReleaseMode) {
        // In release mode, present a user-friendly error
        Zone.current.handleUncaughtError(
          details.exception, 
          details.stack ?? StackTrace.current
        );
      } else {
        // In debug mode, print full error details
        FlutterError.dumpErrorToConsole(details);
        
        // Don't show UI notifications during initialization
        // as they might cause additional errors
        print('ERROR: ${details.exception}');
        print('STACK: ${details.stack}');
      }
    };
  }

  /// Log an error explicitly
  static void logError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
  }) {
    final trace = stackTrace ?? StackTrace.current;
    
    if (kDebugMode) {
      print('ERROR ${context != null ? '[$context]' : ''}: $error');
      print('STACK TRACE: $trace');
    }
    
    // Here you could send this error to a logging service
  }
}