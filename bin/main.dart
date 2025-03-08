import 'dart:convert' as convert;
import 'dart:io';

import 'package:args/args.dart' as args;
import 'package:logging/logging.dart' as logging;
import 'package:oxidized/oxidized.dart';

import 'package:toggl_extractor/src/config.dart';
import 'package:toggl_extractor/src/datetime.dart';
import 'package:toggl_extractor/src/extensions/datetime.dart';
import 'package:toggl_extractor/src/log.dart';
import 'package:toggl_extractor/src/storage.dart';
import 'package:toggl_extractor/src/toggl.dart' as toggl;

final log = logging.Logger('bin.main');

void main(List<String> arguments) async {
  configureLogging(simple: true);

  var parser = args.ArgParser();

  parser.addFlag(
    'verbose',
    abbr: 'v',
    negatable: false,
    defaultsTo: false,
    help: 'show debug-level logs',
  );
  parser.addFlag('help',
      abbr: 'h', negatable: false, help: 'show this help menu');

  var results = parser.parse(arguments);
  if (results['verbose']) {
    logging.Logger.root.level = logging.Level.FINE;
    configureLogging(simple: false);
    log.fine('DEBUG logs ON');
  }

  if (results['help']) {
    print(parser.usage);
    return;
  }

  final readConfigOp = readConfigFromFile();
  if (readConfigOp.isErr()) {
    log.severe('configuration failure, reason: ${readConfigOp.unwrapErr()}');
    exit(-1);
  }

  final config = readConfigOp.unwrap();

  final initOp = Storage.initialize(config);
  if (initOp.isErr()) {
    log.severe(initOp.unwrapErr().toString());
    exit(-2);
  }

  final storage = initOp.unwrap();

  log.info('looking for last download date');
  final lastFetchReadOp = (await storage.readLastFetch()).map((d) {
    return d.when(some: (value) {
      log.info('last download date is ${value}');
      return value;
    }, none: () {
      log.info('nothing downloaded yet');
      return nMonthsAgo(3);
    });
  });

  if (lastFetchReadOp.isErr()) {
    exit(-3);
  }

  final since = lastFetchReadOp.unwrap();
  log.info("downloading entries since ${since}");

  final client = toggl.Client(token: config.togglApiToken);
  final getEntriesOp =
      await client.getRawTimeEntries(modifiedSince: since.unixTimestamp);
  if (getEntriesOp.isErr()) {
    final reason = getEntriesOp.unwrapErr();
    log.severe("failed to download Toggl time entries, reason: ${reason}");
    exit(-4);
  }
  client.close();

  final List<toggl.RawTimeEntry> entries = getEntriesOp.unwrap();
  log.info("${entries.length} entries downloaded");

  if (entries.length == 0) {
    exit(0);
  }

  entries.sort((a, b) => (a['at'] as String).compareTo(b['at'] as String));

  final jsonLines =
      entries.map((entry) => convert.jsonEncode(entry)).join("\n");

  final writeOp = storage
      .append(jsonLines)
      .map((_) => log.info("${entries.length} entries stored"));

  if (writeOp.isErr()) {
    log.severe(
        'failed to append downloaded entries, reason: ${writeOp.unwrapErr()}');
    exit(-5);
  }

  exit(0);
}
