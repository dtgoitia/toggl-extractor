DateTime nMonthsAgo(int n) {
  final now = DateTime.timestamp();

  var year = now.year;
  var month = now.month - 3;
  if (month < 1) {
    month += 12;
    year -= 1;
  }

  return DateTime.utc(year, month, now.day, now.hour, now.minute, now.second)
      .add(Duration(minutes: 10));
}
