// lib/services/task_parser_service.dart

class ParsedTask {
  final String title;
  final DateTime? scheduledAt;
  final String? fullText;

  const ParsedTask({
    required this.title,
    this.scheduledAt,
    this.fullText,
  });
}

class TaskParserService {
  static final _arNumbers = {
    'الواحدة': 1, 'الثانية': 2, 'الثالثة': 3, 'الرابعة': 4, 'الخامسة': 5,
    'السادسة': 6, 'السابعة': 7, 'الثامنة': 8, 'التاسعة': 9, 'العاشرة': 10,
    'الحادية عشر': 11, 'الثانية عشر': 12, 'الحادية عشرة': 11, 'الثانية عشرة': 12,
    'صفر': 0, 'واحد': 1, 'واحدة': 1, 'اثنان': 2, 'اثنتان': 2, 'ثلاثة': 3,
    'ثلاث': 3, 'أربعة': 4, 'أربع': 4, 'خمسة': 5, 'خمس': 5, 'ستة': 6,
    'ست': 6, 'سبعة': 7, 'سبع': 7, 'ثمانية': 8, 'تسعة': 9, 'عشرة': 10,
    'أحد عشر': 11, 'اثنا عشر': 12, 'ثلاثة عشر': 13,
    'أربعة عشر': 14, 'خمسة عشر': 15, 'ستة عشر': 16, 'سبعة عشر': 17,
    'ثمانية عشر': 18, 'تسعة عشر': 19, 'عشرون': 20, 'ثلاثون': 30,
    'أربعون': 40, 'خمسون': 50, 'ستون': 60, 'سبعون': 70, 'ثمانون': 80,
    'تسعون': 90,
  };

  static final _enNumbers = {
    'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
    'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
    'eleven': 11, 'twelve': 12, 'thirteen': 13, 'fourteen': 14,
    'fifteen': 15, 'sixteen': 16, 'seventeen': 17, 'eighteen': 18,
    'nineteen': 19, 'twenty': 20, 'thirty': 30, 'forty': 40,
    'fifty': 50,
  };


  String _replaceWordNumbers(String text, Map<String, int> numberMap) {
    String result = text;
    for (final entry in numberMap.entries) {
      if (RegExp(r'[a-zA-Z]').hasMatch(entry.key)) {
        result = result.replaceAll(RegExp(r'\b' + entry.key + r'\b', caseSensitive: false), entry.value.toString());
      } else {
        result = result.replaceAll(entry.key, entry.value.toString());
      }
    }
    return result;
  }

  ParsedTask parse(String input) {
    final isArabic = RegExp(r'[؀-ۿ]').hasMatch(input);
    return isArabic ? _parseArabic(input) : _parseEnglish(input);
  }

  ParsedTask _parseEnglish(String input) {
    final now = DateTime.now();
    String text = _replaceWordNumbers(input, _enNumbers);
    final lower = text.toLowerCase();

    DateTime? scheduledAt;

    // Try "at X PM/AM" patterns first
    final atMatch = RegExp(
      r'at\s+(\d{1,2})\s*:?\s*(\d{2})?\s*(am|pm|صباحا|morning|مساء|morning|evening|صباح|مساء)',
      caseSensitive: false,
    ).firstMatch(text);

    if (atMatch != null) {
      int hour = int.parse(atMatch.group(1)!);
      final minuteStr = atMatch.group(2);
      int minute = minuteStr != null ? int.parse(minuteStr) : 0;
      final period = atMatch.group(3)?.toLowerCase() ?? '';

      if (period.contains('pm') || period.contains('مساء') || period.contains('evening')) {
        if (hour < 12) hour += 12;
      } else if (period.contains('am') || period.contains('صباح') || period.contains('morning')) {
        if (hour == 12) hour = 0;
      }

      scheduledAt = _resolveDate(lower, now, hour, minute);
    }

    // Try standalone hour:minute
    if (scheduledAt == null) {
      final timeMatch = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(text);
      if (timeMatch != null) {
        int hour = int.parse(timeMatch.group(1)!);
        final minute = int.parse(timeMatch.group(2)!);
        if (lower.contains('pm')) hour = (hour < 12) ? hour + 12 : hour;
        if (lower.contains('am') && hour == 12) hour = 0;
        scheduledAt = _resolveDate(lower, now, hour, minute);
      }
    }

    // Extract title — remove time/date phrases
    String title = text
        .replaceAll(RegExp(r'\s+at\s+\d[\d:\s]*\s*(am|pm)?', caseSensitive: false), '')
        .replaceAll(RegExp(r'\d{1,2}:\d{2}\s*(am|pm)?', caseSensitive: false), '')
        .replaceAll(RegExp(r'tomorrow|today|tonight|مساءً?|صباح|صباحا|مساء', caseSensitive: false), '')
        .replaceAll(RegExp(r'(on|in|at|by)\s+\w+\s+\d+', caseSensitive: false), '')
        .trim();

    if (title.isEmpty) title = input.trim();

    return ParsedTask(title: title, scheduledAt: scheduledAt, fullText: input);
  }

  ParsedTask _parseArabic(String input) {
    final now = DateTime.now();
    String text = _replaceWordNumbers(input, _arNumbers);

    DateTime? scheduledAt;

    // Pattern: الساعة 10 مساءً / الساعة 10:30 / الساعة 10
    final sa3aMatch = RegExp(
      r'الساعة\s+(\d{1,2})\s*:?\s*(\d{2})?\s*(صباحا|مساء|صباح|مساءً)?',
    ).firstMatch(text);

    if (sa3aMatch != null) {
      int hour = int.parse(sa3aMatch.group(1)!);
      final minuteStr = sa3aMatch.group(2);
      int minute = minuteStr != null ? int.parse(minuteStr) : 0;
      final period = sa3aMatch.group(3) ?? '';

      if (period.contains('مساء') && hour < 12) hour += 12;
      if (hour == 12 && period.contains('صباح')) hour = 0;

      scheduledAt = _resolveDateAr(text, now, hour, minute);
    }

    // Extract title
    String title = text
        .replaceAll(RegExp(r'\s*الساعة\s+\d+[\d:\s]*\s*(صباحا|مساء)?'), '')
        .replaceAll(RegExp(r'(غدا|اليوم|مساءً?|صباح|ليل)', caseSensitive: false), '')
        .replaceAll(RegExp(r'(في|in|at)\s+\w+'), '')
        .trim();

    if (title.isEmpty) title = input.trim();

    return ParsedTask(title: title, scheduledAt: scheduledAt, fullText: input);
  }

  DateTime _resolveDate(String lower, DateTime now, int hour, int minute) {
    bool isTomorrow = lower.contains('tomorrow') || lower.contains('tonight');
    bool isToday = lower.contains('today') || !isTomorrow;

    int dayOffset = 0;
    if (isTomorrow || (isToday && _isPastTime(now, hour, minute))) {
      dayOffset = 1;
    }

    return DateTime(now.year, now.month, now.day + dayOffset, hour, minute);
  }

  DateTime _resolveDateAr(String lower, DateTime now, int hour, int minute) {
    bool isTomorrow = lower.contains('غد') || lower.contains('غدا');
    bool isToday = !isTomorrow;

    int dayOffset = 0;
    if (isTomorrow || (isToday && _isPastTime(now, hour, minute))) {
      dayOffset = 1;
    }

    return DateTime(now.year, now.month, now.day + dayOffset, hour, minute);
  }

  bool _isPastTime(DateTime now, int hour, int minute) {
    final testDate = DateTime(now.year, now.month, now.day, hour, minute);
    return testDate.isBefore(now);
  }

  String getPrompt(String locale) {
    if (locale == 'ar') {
      return 'قل مهمتك كاملة مع الوقت والتاريخ، مثل: أريد الذهاب إلى الصالة الرياضية الساعة 10 مساءً غداً';
    }
    return 'Say your task with the date and time, for example: I need to go to the gym at 10 PM tomorrow';
  }
}
