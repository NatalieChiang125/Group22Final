class GameLogic {
  static int calculateStreak(List<Map<String, dynamic>> records) {
    if (records.isEmpty) return 0;

    // 複製並排序紀錄（時間戳記從新到舊）
    final sortedRecords = List<Map<String, dynamic>>.from(records)
      ..sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));

    final now = DateTime.now();
    // 👉 這裡修正為 .year
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // 使用 Set 去除同一天重複記錄的情況，只存取各日期「零點」的時間戳
    final recordDates = sortedRecords.map((r) {
      final d = DateTime.fromMillisecondsSinceEpoch(r['timestamp'] as int);
      // 👉 這裡也修正為 .year
      return DateTime(d.year, d.month, d.day).millisecondsSinceEpoch;
    }).toSet();

    int streak = 0;
    DateTime checkDate = today;

    // 檢查今天是否有紀錄
    if (recordDates.contains(checkDate.millisecondsSinceEpoch)) {
      while (recordDates.contains(checkDate.millisecondsSinceEpoch)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    } else {
      // 如果今天沒紀錄，檢查昨天是否有紀錄，有的話代表 Streak 還沒斷
      checkDate = yesterday;
      if (recordDates.contains(checkDate.millisecondsSinceEpoch)) {
        while (recordDates.contains(checkDate.millisecondsSinceEpoch)) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        }
      } else {
        return 0; // 今天跟昨天都沒記，熱血連擊歸零
      }
    }

    return streak;
  }
}