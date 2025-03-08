import 'package:oxidized/oxidized.dart';

extension StringToDatetime on String {
  Result<DateTime, Exception> toDateTime() {
    try {
      return Ok(DateTime.parse(this));
    } catch (e) {
      return Err(Exception(e));
    }
  }
}

RegExp STRING_FORMAT = RegExp(r'{(.*?)}');

extension TemplateFormatting on String {
  /// Find all `{key}` occurrences in the string and replace them with their
  /// corresponding value.
  ///
  /// Usage example:
  ///
  /// ```dart
  /// String template = "see the {animal}? it's a {size} {animal}";
  /// print(template.format({"animal": "fox", "size": "big"}));
  /// // "see the fox? it's a big fox"
  /// ```
  ///
  /// if a key is not provided in the parameters, the key will be left untouched:
  ///
  /// ```dart
  /// print(template.format({"animal": "fox"}));
  /// // "see the fox? it's a {size} fox"
  /// ```
  ///
  String format(Map<String, String> params) {
    return this.replaceAllMapped(STRING_FORMAT, (match) {
      final key = match.group(1) as String;
      if (params.containsKey(key)) {
        return params[key].toString();
      } else {
        // do not replace `key` not present
        return '{${key}}';
      }
    });
  }
}
