import 'package:flutter/foundation.dart' show debugPrint;
import 'package:logging/logging.dart';

export 'package:logging/logging.dart' show Level, Logger;

abstract class LgrLogNames {
  static const _root = 'lgr';
  static const render = '$_root.render';
  static const layer = '$_root.layer';
  static const geometry = '$_root.geometry';
}

abstract class LgrLogs {
  static final _root = Logger(LgrLogNames._root);
  static final _activeLoggers = <Logger>{};

  static void initLoggers(Set<Logger> loggers, [Level level = Level.ALL]) {
    hierarchicalLoggingEnabled = true;
    for (final logger in loggers) {
      if (!_activeLoggers.contains(logger)) {
        logger.level = level;
        logger.onRecord.listen(_printLog);
        _activeLoggers.add(logger);
      }
    }
  }

  static void initAllLogs([Level level = Level.ALL]) {
    initLoggers({_root}, level);
  }

  static bool isLogActive(Logger logger) {
    return _activeLoggers.contains(logger);
  }

  static void deactivateLoggers(Set<Logger> loggers) {
    for (final logger in loggers) {
      if (_activeLoggers.contains(logger)) {
        logger.clearListeners();
        _activeLoggers.remove(logger);
      }
    }
  }

  static void _printLog(LogRecord record) {
    debugPrint('${record.loggerName} > ${record.level.name}: ${record.message}');
  }
}
