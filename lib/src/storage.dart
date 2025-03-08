import 'dart:io' as io;
import 'dart:convert' as convert;

import 'package:logging/logging.dart';
import 'package:oxidized/oxidized.dart';
import 'package:path/path.dart' as pathUtils;

import 'package:toggl_extractor/src/config.dart';
import 'package:toggl_extractor/src/extensions/string.dart';
import 'package:toggl_extractor/src/model.dart';
import 'package:toggl_extractor/src/fs.dart' as fs;

final log = Logger('lib.src.storage');

class Storage {
  static Storage? _instance;

  final PathStr dataDir;

  Storage._(this.dataDir); // private constructor

  /// Creates `dataDir` directory if missing.
  static Result<Storage, Exception> initialize(Config config) {
    log.finer('initializing ${Storage} with ${config}');

    final dataDirOp = fs.resolve(config.dataDir);
    if (dataDirOp.isErr()) {
      return Err(Exception(
          'failed to initialize ${Storage}, reason: ${dataDirOp.unwrapErr()}'));
    }

    PathStr dataDir = dataDirOp.unwrap();

    if (_instance != null) {
      final msg =
          "failed to initialize with dataDir='${dataDir}', already initialized with dataDir='${dataDir}'";
      return Err(StorageAlreadyInitialized(msg));
    }

    final instance = Storage._(dataDir);

    return instance._createDataFile(dataDir).map((_) {
      // only save the result for future calls if successful
      _instance = instance;
      return instance;
    });
  }

  Result<Unit, Exception> _createDataFile(PathStr dataDir) {
    log.fine('making sure data directory is set up: ${dataDir}');

    final dataFilePath = this.dataFile;

    final existsOp = fs.pathExistsSync(dataFilePath);
    if (existsOp.isErr()) {
      return Err(Exception(
          "failed to determine if path '${dataFilePath}' exists, reason: ${existsOp.unwrapErr()}"));
    }

    final exists = existsOp.unwrap();
    if (exists) {
      log.info('data directory already exists: ${dataFilePath}');
      return Ok(unit);
    }

    log.info('data file not found: ${dataFilePath}');
    log.info('creating data file');

    return fs.createFileSync(dataFilePath).map((_) {
      log.fine('data file created');
      return unit;
    });
  }

  Result<Unit, Exception> append(String line) {
    final lastChar = line[line.length - 1];
    final toAppend = (lastChar == "\n") ? line : "${line}\n";

    final file = io.File(this.dataFile);
    try {
      file.writeAsStringSync(toAppend, mode: io.FileMode.append);
    } catch (e) {
      return Err(Exception(e));
    }

    return Ok(unit);
  }

  PathStr get dataFile {
    return pathUtils.join(this.dataDir, 'entries.jsonl');
  }

  Future<Result<Option<DateTime>, Exception>> readLastFetch() async {
    final existsOp = fs.pathExistsSync(this.dataFile);
    if (existsOp.isErr()) {
      return Err(existsOp.unwrapErr());
    }

    final exists = existsOp.unwrap();
    if (exists == false) {
      return Ok(None());
    }

    final file = io.File(this.dataFile);

    final readLastLineOp = await file.readLastLine();
    if (readLastLineOp.isErr()) {
      return Err(readLastLineOp.unwrapErr());
    }

    final maybeLastLine = readLastLineOp.unwrap();
    if (maybeLastLine.isNone()) {
      return Ok(None());
    }

    final lastLine = maybeLastLine.unwrap();

    final JsonMap lastEntry = convert.jsonDecode(lastLine);
    final String lastFetch = lastEntry['at'];
    return lastFetch.toDateTime().map((datetime) => Some(datetime));
  }

  @override
  String toString() => "${runtimeType}(dataDir=${dataDir})";
}

class StorageAlreadyInitialized implements Exception {
  final String message;
  StorageAlreadyInitialized(this.message);
  @override
  String toString() => "${runtimeType}(${message})";
}

extension on io.File {
  Future<Result<Option<String>, Exception>> readLastLine() async {
    final bool exists;
    try {
      exists = await this.exists();
    } catch (e) {
      return Err(Exception(e.toString()));
    }

    if (!exists) {
      return Err(Exception("failed to read '${this}', reason: file not found"));
    }

    final stream = this.openRead();
    String? lastLine;
    try {
      await stream
          .transform(convert.utf8.decoder)
          .transform(convert.LineSplitter())
          .listen((line) {
        lastLine = line;
      }).asFuture();
    } catch (e) {
      return Err(Exception("failed to read '${this}', reason: ${e}"));
    }

    if (lastLine == null) {
      return Ok(None());
    }
    return Ok(Some(lastLine as String));
  }
}
