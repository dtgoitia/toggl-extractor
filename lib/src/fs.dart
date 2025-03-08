import 'dart:io' as io;

import 'package:oxidized/oxidized.dart';
import 'package:path/path.dart' as pathUtils;

import 'package:toggl_extractor/src/environment.dart';
import 'package:toggl_extractor/src/model.dart';

/// Returns `true` if path exists, otherwise `false`. It also resolves `~` to the
/// user's `HOME`.
Result<bool, Exception> pathExistsSync(PathStr path) {
  return expandUser(path).map((absolutePath) {
    final type = io.FileSystemEntity.typeSync(absolutePath, followLinks: true);
    switch (type) {
      case io.FileSystemEntityType.notFound:
        return false;
      case io.FileSystemEntityType.file:
        return io.File(absolutePath).existsSync();
      case io.FileSystemEntityType.directory:
        return io.Directory(absolutePath).existsSync();
      default:
        throw Exception('absolutePath is of unrecognized type: ${type}');
    }
  });
}

/// Resolves `~` to the user's `HOME` and returns an absolute path.
Result<PathStr, Exception> expandUser(PathStr path) {
  if (path.startsWith("/")) {
    return Ok(path);
  } else if (path.startsWith("~/")) {
    return readRawEnvironmentVariable('HOME').map((homeDir) {
      String pathRelativeToHome = path.replaceFirst("~/", "");
      PathStr result = pathUtils.join(homeDir, pathRelativeToHome);
      return result;
    });
  } else {
    return toAbsolutePath(path);
  }
}

Result<PathStr, Exception> toAbsolutePath(PathStr path) {
  PathStr cwd = io.Directory.current.toString();
  return Result.of(() => pathUtils.join(cwd, path));
}

Result<PathStr, Exception> resolve(PathStr path) {
  return expandUser(path).map(toAbsolutePath).flatten();
}

Result<Unit, Exception> createFileSync(PathStr path) {
  try {
    io.File(path).createSync(recursive: true);
  } catch (error) {
    return Err(Exception(error));
  }

  return Ok(unit);
}
