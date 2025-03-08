import 'dart:async';

import 'package:logging/logging.dart';

import 'package:toggl_extractor/src/extensions/string.dart';

final log = Logger('lib.src.log');

const SIMPLE_LOG_TEMPLATE = "{message}";
const DETAILED_LOG_TEMPLATE = '{time} [{level}] {message} [{loggerName}]';

StreamSubscription<LogRecord>? logSubscription = null;

void configureLogging({required bool simple}) {
  final firstTime = logSubscription == null;

  // --- log level -------------------------------------------------------------
  if (firstTime) {
    Logger.root.level = Level.INFO;
  } else {
    // preserve existing logging level
  }

  // --- log format ------------------------------------------------------------
  if (!firstTime) {
    // make sure
    logSubscription?.cancel();
  }

  final handleLog = simple
      ? (LogRecord record) {
          print(SIMPLE_LOG_TEMPLATE.format({'message': record.message}));
        }
      : (LogRecord record) {
          print(DETAILED_LOG_TEMPLATE.format({
            'time': record.time.toString(),
            'level': record.level.toString(),
            'message': record.message,
            'loggerName': record.loggerName,
          }));
        };

  logSubscription = Logger.root.onRecord.listen(handleLog);

  if (firstTime) {
    log.fine('logging configuration set');
  } else {
    log.fine('logging configuration updated');
  }
}
