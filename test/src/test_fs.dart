import 'package:oxidized/oxidized.dart';
import 'package:test/test.dart';

import 'package:toggl_extractor/src/fs.dart' as fs;
import 'package:toggl_extractor/src/environment.dart' as environment;

void main() {
  test("expands tilde to user home directory", () {
    environment.runInTestMode((platform) {
      platform.empty();
      platform.setEnvironmentVariable('HOME', '/home/testuser');

      final actual = fs.expandUser("~/foo.txt");
      expect(
          actual,
          equals(Result<String, environment.EnvironmentVariableNotFound>.ok(
              '/home/testuser/foo.txt')));
    });
  });
}
