import 'dart:io' as io;

import 'package:logging/logging.dart';
import 'package:oxidized/oxidized.dart';

final log = Logger('lib.src.environment');

enum TestMode { ON, OFF }

TestMode TEST_MODE = TestMode.OFF;

typedef Environment = Map<String, String>;

/// Mockable `io.Platform` replacement;
class Platform {
  static Environment _environment = Map();

  static Environment get environment {
    switch (TEST_MODE) {
      case TestMode.ON:
        return _environment;
      case TestMode.OFF:
        return io.Platform.environment;
    }
  }

  /// Copies the `io.Platform.environment` values and exposes them through the
  /// mock. Values mutates after running this method do not change the actual
  /// environment, only the mock.
  void cloneOriginal() {
    if (TEST_MODE == TestMode.OFF) {
      log.warning("nothing to do, reason: TEST_MODE=${TEST_MODE}");
      return;
    }

    _environment = Map.of(io.Platform.environment);
  }

  /// Removes all values.
  void empty() {
    if (TEST_MODE == TestMode.OFF) {
      log.warning("nothing to do, reason: TEST_MODE=${TEST_MODE}");
      return;
    }

    _environment = Map();
  }

  void setEnvironmentVariable(String variable, String value) {
    if (TEST_MODE == TestMode.OFF) {
      log.warning("nothing to do, reason: TEST_MODE=${TEST_MODE}");
      return;
    }

    _environment[variable] = value;
  }
}

Platform platform = Platform();

typedef TestFunction = void Function(Platform platform);

void runInTestMode(TestFunction callable) {
  TEST_MODE = TestMode.ON;
  try {
    callable(
        platform); // TODO: pass the singleton here -- make it thread-safe, aka the singleton should keep track of the environment of each thread
  } catch (e) {
    TEST_MODE = TestMode.OFF;
    throw e;
  }
}

Map<String, bool> STRINGS_THAT_MAP_TO_BOOLEAN = {
  'y': true,
  'n': false,
  'yes': true,
  'no': false,
  't': true,
  'f': false,
  'true': true,
  'false': false,
  '1': true,
  '0': false,
};

class EnvironmentVariableNotFound implements Exception {
  final String message;

  EnvironmentVariableNotFound(this.message);

  @override
  String toString() => 'EnvironmentVariableNotFound(${message})';
}

Result<String, EnvironmentVariableNotFound> readRawEnvironmentVariable(
    String name) {
  // String? raw = io.Platform.environment[name];
  String? raw = Platform.environment[name];
  if (raw == null) {
    return Err(EnvironmentVariableNotFound(
        "expected '${name}' environment variable to be set but is not"));
  } else {
    return Ok(raw);
  }
}

enum Error {
  environmentVariableNotFound,
  environmentVariableIsNotBoolean,
}

Result<bool, Error> readEnvironmentVariableAsBoolean(String name) {
  return readRawEnvironmentVariable(name).when(
    ok: (s) {
      return stringToBoolean(s).mapOrElse(Result.ok, (unit) {
        return Err(Error.environmentVariableIsNotBoolean);
      });
    },
    err: (err) {
      return Err(Error.environmentVariableNotFound);
    },
  );
}

Result<bool, Unit> stringToBoolean(String s) {
  final bool? b = STRINGS_THAT_MAP_TO_BOOLEAN[s.toLowerCase()];
  if (b == null) {
    return Err(unit);
  }

  return Ok(b);
}
