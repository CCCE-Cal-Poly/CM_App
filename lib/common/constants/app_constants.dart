/// Central location for app-wide constants
/// Including error messages, durations, limits, and validation rules

import 'package:flutter/material.dart';

class AppConstants {
  // PASSWORD VALIDATION
  static const int minPasswordLength = 8;
  static const int minPasswordLengthChange = 8;

  // ERROR MESSAGES - AUTHENTICATION
  static const String errorWeakPassword = 'Password is too weak';
  static const String errorInvalidEmail = 'Invalid Email';
  static const String errorEmailAlreadyInUse = 'Email already in use';
  static const String errorInvalidCredentials = 'Invalid Credentials';
  static const String errorUserNotFound = 'User not found';
  static const String errorWrongPassword = 'Wrong password';
  static const String errorUserDisabled = 'User account has been disabled';
  static const String errorPasswordRequirementNotMet =
      'Password must be at least $minPasswordLength characters';
  static const String errorPasswordMismatch = 'Passwords do not match';
  static const String errorPasswordMismatchChange =
      'New passwords do not match';
  static const String errorFirstNameRequired = 'First name is required';
  static const String errorLastNameRequired = 'Last name is required';
  static const String errorPasswordRequired = 'Password is required';
  static const String errorEmailRequired = 'Email is required';
  static const String errorAllFieldsRequired = 'All fields are required';

  // ERROR MESSAGES - GENERAL
  static const String errorFailedCreateUser =
      'Failed to create user. Please try again';
  static const String errorUnexpected = 'An unexpected error occurred';
  static const String errorNetworkError =
      'Network error. Please check your connection';

  // SUCCESS MESSAGES
  static const String successEmailSent = 'Verification email sent!';
  static const String successPasswordChanged = 'Password changed successfully';
  static const String successProfileUpdated = 'Profile updated successfully';

  // DURATIONS
  static const Duration snackBarDuration = Duration(seconds: 3);
  static const Duration verificationCheckInterval = Duration(seconds: 3);
  static const Duration tokenRefreshDebounce = Duration(seconds: 1);

  // LIMITS & PAGINATION
  static const int eventsPageSize = 20;
  static const int clubsPageSize = 20;
  static const int jobsPageSize = 20;
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // FIRESTORE RULES
  static const String collectionUsers = 'users';
  static const String collectionEvents = 'events';
  static const String collectionClubs = 'clubs';
  static const String collectionCompanies = 'companies';
  static const String collectionNotifications = 'notifications';

  // TIMEOUTS
  static const Duration fcmTokenTimeout = Duration(hours: 1);
  static const Duration tokenCleanupThreshold = Duration(days: 90);
  static const Duration notificationCleanupThreshold = Duration(days: 3);
  static const Duration eventArchiveThreshold = Duration(days: 7);
}
