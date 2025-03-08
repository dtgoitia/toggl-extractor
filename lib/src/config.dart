import 'dart:convert';
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:oxidized/oxidized.dart';
import 'package:path/path.dart' as path;

import 'model.dart';
import 'environment.dart';

final log = Logger('lib.src.config');

const String HOME_ENV_VAR = 'HOME';
const PathStr DEFAULT_CONFIG_FILE_LOCATION =
    "~/.config/toggl-extractor/config.json";

Result<String, Exception> getHome() {
  final result = readRawEnvironmentVariable(HOME_ENV_VAR);
  if (result.isErr()) {
    return Err(Exception(
        "expected '${HOME_ENV_VAR}' environment variable to be set but is not"));
  }

  final homeDir = result.unwrap();
  final file = File(homeDir);
  if (file.exists() == false) {
    return Err(Exception(
        "the path in '${HOME_ENV_VAR}' environment variable does not exist: '${file}'"));
  }

  return Ok(homeDir);
}

Result<String, Exception> _getConfigPath() {
  if (DEFAULT_CONFIG_FILE_LOCATION.startsWith('/')) {
    return Ok(DEFAULT_CONFIG_FILE_LOCATION);
  }

  if (DEFAULT_CONFIG_FILE_LOCATION.startsWith('~/')) {
    return getHome().map((home) {
      String configRelativePath =
          DEFAULT_CONFIG_FILE_LOCATION.replaceFirst('~/', "");
      return path.join(home, configRelativePath);
    });
  }

  return Err(Exception("config file location must be an absolute path"));
}

Result<String, Exception> getConfigPath() {
  final _configPath = _getConfigPath();
  if (_configPath.isErr()) {
    return _configPath;
  }

  String configPath = _configPath.unwrap();
  if (File(configPath).existsSync()) {
    return Ok(configPath);
  } else {
    return Err(Exception(
        "expected configuration file at ${DEFAULT_CONFIG_FILE_LOCATION}, but file is missing"));
  }
}

typedef TogglApiToken = String;

class Config {
  Config({required this.dataDir, required this.togglApiToken});

  final PathStr dataDir;
  final TogglApiToken togglApiToken;
}

Result<Config, Exception> readConfigFromFile() {
  log.info("resolving configuration path");
  final _configPath = getConfigPath();
  if (_configPath.isErr()) {
    return Err(_configPath.unwrapErr());
  }

  PathStr configPath = _configPath.unwrap();
  log.info("looking for configuration file at '${configPath}'");
  final content = File(configPath).readAsStringSync();
  final Map<String, dynamic> configMap = jsonDecode(content);

  final apiTokenReadResult = readRawEnvironmentVariable('TOGGL_API_TOKEN');
  if (apiTokenReadResult.isErr()) {
    return Err(apiTokenReadResult.unwrapErr());
  }

  final config = Config(
    dataDir: configMap['data_dir'] as String,
    togglApiToken: apiTokenReadResult.unwrap(),
  );
  return Ok(config);
}
