import '../../enums/app_enums.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class LoggerService {
  final String _className;

  LoggerService({required String className}) : _className = className;

  // Debug log
  void debug(String message, {String? tag, dynamic data}) {
    if (kDebugMode) {
      _log(LogLevel.debug, message, tag: tag, data: data);
    }
  }

  // Info log
  void info(String message, {String? tag, dynamic data}) {
    _log(LogLevel.info, message, tag: tag, data: data);
  }

  // Warning log
  void warning(String message, {String? tag, dynamic data}) {
    _log(LogLevel.warning, message, tag: tag, data: data);
  }

  // success log
  void success(String message, {String? tag, dynamic data}) {
    _log(LogLevel.info, '✅ $message', tag: tag, data: data);
  }

  // Error log
  void error(
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.error,
      message,
      tag: tag,
      data: error,
      stackTrace: stackTrace,
    );
  }

  // Critical log
  void critical(
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.critical,
      message,
      tag: tag,
      data: error,
      stackTrace: stackTrace,
    );
  }

  // Network log
  void network(String message, {String? tag, dynamic data}) {
    if (kDebugMode) {
      _log(LogLevel.info, '[NETWORK] $message', tag: tag, data: data);
    }
  }

  // Provider log
  void provider(String message, {String? tag, dynamic data}) {
    if (kDebugMode) {
      _log(LogLevel.info, '[PROVIDER] $message', tag: tag, data: data);
    }
  }

  // Navigation log
  void navigation(String message, {String? tag, dynamic data}) {
    if (kDebugMode) {
      _log(LogLevel.info, '[NAVIGATION] $message', tag: tag, data: data);
    }
  }

  // Internal log method
  void _log(
    LogLevel level,
    String message, {
    String? tag,
    dynamic data,
    StackTrace? stackTrace,
  }) {
    final tagPrefix = tag != null ? '[$tag] ' : '';

    final emoji = _getEmojiForLevel(level);
    final timestamp = DateTime.now().toString().substring(11, 19);
    final logMessage = '$emoji [$timestamp] $tagPrefix$message';

    debugPrint(
      'LOG: [$_className] [${level.name}] -> $logMessage ${data ?? ''}',
    ); // For debugging purposes

    switch (level) {
      case LogLevel.debug:
        developer.log(logMessage, name: _className, level: 500, error: data);
        break;

      case LogLevel.info:
        developer.log(logMessage, name: _className, level: 800, error: data);
        break;

      case LogLevel.warning:
        developer.log(logMessage, name: _className, level: 900, error: data);
        break;

      case LogLevel.error:
        developer.log(
          logMessage,
          name: _className,
          level: 1000,
          error: data,
          stackTrace: stackTrace,
        );
        break;

      case LogLevel.critical:
        developer.log(
          logMessage,
          name: _className,
          level: 1200,
          error: data,
          stackTrace: stackTrace,
        );
        break;
    }
  }

  String _getEmojiForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🐛';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.critical:
        return '🔥';
    }
  }
}

// Usage examples:
// LoggerService.debug('User logged in', tag: 'Auth');
// LoggerService.info('Fetching inventory items', data: {'page': 1});
// LoggerService.error('Failed to load data', error: e, stackTrace: stackTrace);
// LoggerService.network('POST /api/login', data: requestBody);
