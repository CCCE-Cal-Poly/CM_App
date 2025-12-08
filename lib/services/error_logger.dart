import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Central error logging and handling service for the app
class ErrorLogger {
  /// Log an error with context
  static void logError(
    String context,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      print('❌ ERROR [$context]: $message');
      if (error != null) {
        print('Error: $error');
      }
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
    }
    // TODO: In production, send to Firebase Crashlytics or Sentry
    // FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: context);
  }

  /// Log a warning
  static void logWarning(String context, String message) {
    if (kDebugMode) {
      print('⚠️ WARNING [$context]: $message');
    }
  }

  /// Log info message
  static void logInfo(String context, String message) {
    if (kDebugMode) {
      print('ℹ️ INFO [$context]: $message');
    }
  }

  /// Get user-friendly error message from Firebase Auth exception
  static String getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Invalid email or password.';
      case 'invalid-email':
        return 'The email address is badly formatted.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'email-already-in-use':
        return 'Email already in use.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'requires-recent-login':
        return 'Please sign in again to complete this action.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      default:
        logWarning('Firebase Auth', 'Unknown error code: ${e.code}');
        return e.message ?? 'An unexpected error occurred.';
    }
  }

  /// Get user-friendly error message from generic exception
  static String getGenericErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      return getAuthErrorMessage(error);
    }
    
    final errorString = error.toString();
    if (errorString.contains('network')) {
      return 'Network error. Check your internet connection.';
    }
    if (errorString.contains('permission')) {
      return 'Permission denied. Please contact support.';
    }
    
    return 'An unexpected error occurred. Please try again.';
  }
}
