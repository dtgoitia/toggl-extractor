import 'package:toggl_extractor/src/model.dart';

extension DatetimeToUnixTimestamp on DateTime {
  UnixTimestamp get unixTimestamp {
    return (this.millisecondsSinceEpoch / 1000).round();
  }
}
