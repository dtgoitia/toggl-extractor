import 'dart:convert' as convert;
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_auth/http_auth.dart' as http_auth;
import 'package:logging/logging.dart';
import 'package:oxidized/oxidized.dart';
import 'package:path/path.dart' as pathUtils;
import 'package:toggl_extractor/src/config.dart';

import 'package:toggl_extractor/src/model.dart';
import 'package:toggl_extractor/src/extensions/uri.dart';

final log = Logger('lib.src.toggl');

const TOGGL_API_BASE_URL = "https://api.track.toggl.com/api/v9";

const TOGGLE_API_ENDPOINT__TIME_ENTRIES = 'me/time_entries';

typedef RawTimeEntry = JsonMap;

class Client {
  String baseUrl = TOGGL_API_BASE_URL;
  late http_auth.BasicAuthClient _httpClient;

  Client({required TogglApiToken token}) {
    this._httpClient = http_auth.BasicAuthClient(token, 'api_token');
  }

  void close() {
    this._httpClient.close();
  }

  Future<Result<List<JsonMap>, Exception>> getRawTimeEntries(
      {UnixTimestamp? modifiedSince}) async {
    var url = Uri.parse(
        pathUtils.join(TOGGL_API_BASE_URL, TOGGLE_API_ENDPOINT__TIME_ENTRIES));

    final Map<String, String> params = {};
    if (modifiedSince != null) {
      params['since'] = modifiedSince.toString();
    }

    url = url.setQueryParams(params);

    log.fine("GET ${url}");
    final response = await this._httpClient.get(url);
    log.fine("${response.statusCode} GET ${url}");

    final body = response.body;
    if (response.isJson == false) {
      return Err(UnexpectedResponsePayload(body));
    }

    List<JsonMap> decodedBody = [Map()];
    if (body.length > 0) {
      try {
        decodedBody = (convert.jsonDecode(body) as List<dynamic>)
            .map((item) => item as JsonMap)
            .toList();
      } on FormatException catch (e) {
        return Err(FailedToParseJson(e));
      }
    }

    return Ok(decodedBody);
  }
}

extension on http.Response {
  bool get isJson {
    final headers = this.headers;
    if (headers.containsKey('content-type')) {
      final header = headers['content-type'] as String;
      final contentType = ContentType.parse(header);
      return contentType.toString() == ContentType.json.toString();
    }
    return false;
  }
}

class UnexpectedResponsePayload implements Exception {
  final String payload;
  UnexpectedResponsePayload(this.payload);
  @override
  String toString() => "${runtimeType}(${this.payload})";
}

class FailedToParseJson implements Exception {
  final FormatException exception;
  FailedToParseJson(this.exception);
  @override
  String toString() {
    final e = this.exception.toString().replaceFirst('FormatException: ', '');
    return "${runtimeType}(${e})";
  }
}
