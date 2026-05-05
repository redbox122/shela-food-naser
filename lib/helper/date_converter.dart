import 'package:flutter/foundation.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:sixam_mart/helper/string_extension.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/util/app_constants.dart';

class DateConverter {
  static int? _cachedServerTimeOffsetMs;

  static void updateServerTimeOffsetMs(int offsetMs) {
    _cachedServerTimeOffsetMs = offsetMs;
  }

  static int _getServerTimeOffsetMs() {
    if (_cachedServerTimeOffsetMs != null) {
      return _cachedServerTimeOffsetMs!;
    }
    try {
      final SharedPreferences prefs = Get.find<SharedPreferences>();
      _cachedServerTimeOffsetMs =
          prefs.getInt(AppConstants.serverTimeOffsetMs) ?? 0;
    } catch (_) {
      _cachedServerTimeOffsetMs = 0;
    }
    return _cachedServerTimeOffsetMs!;
  }

  static DateTime _now() {
    final int offsetMs = _getServerTimeOffsetMs();
    if (offsetMs == 0) {
      return DateTime.now();
    }
    return DateTime.now().add(Duration(milliseconds: offsetMs));
  }

  static String formatDate(DateTime dateTime) {
    final String formatted =
        DateFormat('yyyy-MM-dd hh:mm:ss a', _getLocale().toString())
            .format(dateTime);
    return _convertToArabicIndic(formatted);
  }

  static String dateToTimeOnly(DateTime dateTime) {
    final String formatted =
        DateFormat(_timeFormatter(), _getLocale().toString()).format(dateTime);
    return _convertToArabicIndic(formatted);
  }

  static String dateToDateAndTime(DateTime dateTime) {
    final String formatted =
        DateFormat('yyyy-MM-dd HH:mm', _getLocale().toString())
            .format(dateTime);
    return _convertToArabicIndic(formatted);
  }

  static String dateToDateAndTimeAm(DateTime dateTime) {
    final String formatted =
        DateFormat('yyyy-MM-dd ${_timeFormatter()}', _getLocale().toString())
            .format(dateTime);
    return _convertToArabicIndic(formatted);
  }

  static String dateToDate(DateTime dateTime) {
    final String formatted =
        DateFormat('yyyy-MM-dd', _getLocale().toString()).format(dateTime);
    return _convertToArabicIndic(formatted);
  }

  static String dateToReadableDate(DateTime dateTime) {
    final String formatted =
        DateFormat('dd MMM, yyy', _getLocale().toString()).format(dateTime);
    return _convertToArabicIndic(formatted);
  }

  static String dateTimeStringToDateTime(String dateTime) {
    debugPrint(
        '[CHAT:DATE_PARSE_CALLER] function=dateTimeStringToDateTime raw=$dateTime');
    final DateTime? parsedDate = tryParseDateTimeSafely(dateTime);
    if (parsedDate == null) {
      debugPrint(
          '[CHAT:DATE_PARSE_FAIL_SAFE] function=dateTimeStringToDateTime raw=$dateTime');
      final DateTime fallbackNow = DateTime.now();
      final String fallbackFormatted = DateFormat(
              'dd MMM yyyy,  ${_timeFormatter()}', _getLocale().toString())
          .format(fallbackNow);
      return _convertToArabicIndic(fallbackFormatted);
    }
    final String formatted =
        DateFormat('dd MMM yyyy,  ${_timeFormatter()}', _getLocale().toString())
            .format(parsedDate);
    return _convertToArabicIndic(formatted);
  }

  static String taxiDateTimeToString(DateTime dateTime) {
    final String formatted =
        DateFormat('dd MMM yyyy,  ${_timeFormatter()}', _getLocale().toString())
            .format(dateTime);
    return _convertToArabicIndic(formatted);
  }

  static String dateTimeStringToUTCTime(String dateTime) {
    final String formatted =
        DateFormat('dd MMM yyyy  ${_timeFormatter()}', _getLocale().toString())
            .format(DateFormat('yyyy-MM-ddTHH:mm:ss.SSS').parse(dateTime));
    return _convertToArabicIndic(formatted);
  }

  static String dateTimeStringToDateOnly(String dateTime) {
    final String formatted = DateFormat('dd MMM yyyy', _getLocale().toString())
        .format(_parseFlexibleDateTime(dateTime));
    return _convertToArabicIndic(formatted);
  }

  static DateTime dateTimeStringToDate(String dateTime) {
    return _parseFlexibleDateTime(dateTime);
  }

  static DateTime isoStringToLocalDate(String dateTime) {
    return _parseFlexibleDateTime(dateTime);
  }

  static String isoStringToLocalString(String dateTime) {
    debugPrint(
        '[CHAT:DATE_PARSE_CALLER] function=isoStringToLocalString raw=$dateTime');
    final DateTime? parsedDate = tryParseDateTimeSafely(dateTime);
    if (parsedDate == null) {
      debugPrint(
          '[CHAT:DATE_PARSE_FAIL_SAFE] function=isoStringToLocalString raw=$dateTime');
      return '';
    }
    final String formatted =
        DateFormat('yyyy-MM-dd HH:mm:ss', _getLocale().toString())
            .format(parsedDate);
    return _convertToArabicIndic(formatted);
  }

  static String isoStringToReadableString(String dateTime) {
    debugPrint(
        '[CHAT:DATE_PARSE_CALLER] function=isoStringToReadableString raw=$dateTime');
    final DateTime? parsedDate = tryParseDateTimeSafely(dateTime);
    if (parsedDate == null) {
      debugPrint(
          '[CHAT:DATE_PARSE_FAIL_SAFE] function=isoStringToReadableString raw=$dateTime');
      return '';
    }
    final String formatted =
        DateFormat('dd MMMM, yyyy HH:mm a', _getLocale().toString())
            .format(parsedDate);
    return _convertToArabicIndic(formatted);
  }

  static String stringToReadableString(String dateTime) {
    debugPrint(
        '[CHAT:DATE_PARSE_CALLER] function=stringToReadableString raw=$dateTime');
    final DateTime? parsedDate = tryParseDateTimeSafely(dateTime);
    if (parsedDate == null) {
      debugPrint(
          '[CHAT:DATE_PARSE_FAIL_SAFE] function=stringToReadableString raw=$dateTime');
      return '';
    }
    final String formatted =
        DateFormat('dd MMMM, yyyy', _getLocale().toString())
            .format(parsedDate);
    return _convertToArabicIndic(formatted);
  }

  static String isoStringToDateTimeString(String dateTime) {
    final String formatted =
        DateFormat('dd MMM yyyy  ${_timeFormatter()}', _getLocale().toString())
            .format(isoStringToLocalDate(dateTime));
    return _convertToArabicIndic(formatted);
  }

  static String isoStringToLocalDateOnly(String dateTime) {
    final String formatted = DateFormat('dd MMM yyyy', _getLocale().toString())
        .format(isoStringToLocalDate(dateTime));
    return _convertToArabicIndic(formatted);
  }

  static String stringToLocalDateOnly(String dateTime) {
    debugPrint(
        '[CHAT:DATE_PARSE_CALLER] function=stringToLocalDateOnly raw=$dateTime');
    final DateTime? parsedDate = tryParseDateTimeSafely(dateTime);
    if (parsedDate == null) {
      debugPrint(
          '[CHAT:DATE_PARSE_FAIL_SAFE] function=stringToLocalDateOnly raw=$dateTime');
      return '';
    }
    final String formatted = DateFormat('dd MMM yyyy', _getLocale().toString())
        .format(parsedDate);
    return _convertToArabicIndic(formatted);
  }

  static String localDateToIsoString(DateTime dateTime) {
    final String formatted =
        DateFormat('yyyy-MM-ddTHH:mm:ss.SSS', _getLocale().toString())
            .format(dateTime);
    return _convertToArabicIndic(formatted);
  }

  static String convertTimeToTime(String time) {
    final String formatted =
        DateFormat(_timeFormatter(), _getLocale().toString())
            .format(DateFormat('HH:mm').parse(time));
    return _convertToArabicIndic(formatted);
  }

  static DateTime convertStringTimeToDate(String time) {
    return DateFormat('HH:mm').parse(time);
  }

  static String convertTimeToTimeDate(DateTime time) {
    final String formatted =
        DateFormat('HH:mm', _getLocale().toString()).format(time);
    return _convertToArabicIndic(formatted);
  }

  static bool isAvailable(String? start, String? end, {DateTime? time}) {
    DateTime currentTime;
    if (time != null) {
      currentTime = time;
    } else {
      currentTime = _now();
    }
    final DateTime start0 = start != null
        ? DateFormat('HH:mm').parse(start)
        : DateTime(currentTime.year);
    final DateTime end0 = end != null
        ? DateFormat('HH:mm').parse(end)
        : DateTime(
            currentTime.year, currentTime.month, currentTime.day, 23, 59, 59);
    DateTime startTime = DateTime(currentTime.year, currentTime.month,
        currentTime.day, start0.hour, start0.minute, start0.second);
    DateTime endTime = DateTime(currentTime.year, currentTime.month,
        currentTime.day, end0.hour, end0.minute, end0.second);
    if (endTime.isBefore(startTime)) {
      if (currentTime.isBefore(startTime) && currentTime.isBefore(endTime)) {
        startTime = startTime.add(const Duration(days: -1));
      } else {
        endTime = endTime.add(const Duration(days: 1));
      }
    }
    return currentTime.isAfter(startTime) && currentTime.isBefore(endTime);
  }

  static String _timeFormatter() {
    return Get.find<SplashController>().configModel!.timeformat == '24'
        ? 'HH:mm'
        : 'hh:mm a';
  }

  static String convertFromMinute(int minMinute, int maxMinute) {
    int firstValue = minMinute;
    int secondValue = maxMinute;
    String type = 'min';
    if (minMinute >= 525600) {
      firstValue = (minMinute / 525600).floor();
      secondValue = (maxMinute / 525600).floor();
      type = 'year';
    } else if (minMinute >= 43200) {
      firstValue = (minMinute / 43200).floor();
      secondValue = (maxMinute / 43200).floor();
      type = 'month';
    } else if (minMinute >= 10080) {
      firstValue = (minMinute / 10080).floor();
      secondValue = (maxMinute / 10080).floor();
      type = 'week';
    } else if (minMinute >= 1440) {
      firstValue = (minMinute / 1440).floor();
      secondValue = (maxMinute / 1440).floor();
      type = 'day';
    } else if (minMinute >= 60) {
      firstValue = (minMinute / 60).floor();
      secondValue = (maxMinute / 60).floor();
      type = 'hour';
    }
    final String result = '$firstValue-$secondValue ${type.tr}';
    return _convertToArabicIndic(result);
  }

  static String localDateToIsoStringAMPM(DateTime dateTime) {
    final String formatted =
        DateFormat('${_timeFormatter()} | d-MMM-yyyy ', _getLocale().toString())
            .format(dateTime.toLocal());
    return _convertToArabicIndic(formatted);
  }

  static bool isBeforeTime(String? dateTime) {
    if (dateTime == null) {
      return false;
    }
    final DateTime scheduleTime = dateTimeStringToDate(dateTime);
    return scheduleTime.isBefore(_now());
  }

  static int differenceInMinute(String? deliveryTime, String? orderTime,
      int? processingTime, String? scheduleAt) {
    // 'min', 'hours', 'days'
    int minTime = processingTime ?? 0;
    if (deliveryTime != null &&
        deliveryTime.isNotEmpty &&
        processingTime == null) {
      try {
        final List<String> timeList = deliveryTime.split('-'); // ['15', '20']
        minTime = int.parse(timeList[0]);
      } catch (e) {
        if (kDebugMode) debugPrint('$e');
      }
    }
    final DateTime deliveryTime0 =
        dateTimeStringToDate(scheduleAt ?? orderTime!)
            .add(Duration(minutes: minTime));
    return deliveryTime0.difference(_now()).inMinutes;
  }

  static String containTAndZToUTCFormat(String time) {
    if (time.length < 23) {
      return time; // Return original if format is invalid
    }
    final newTime =
        '${time.safeSubstring(10, ellipsis: '')} ${time.length > 23 ? time.substring(11, 23) : time.substring(11)}';
    final String formatted = DateFormat('dd MMM, yyyy', _getLocale().toString())
        .format(DateFormat('yyyy-MM-dd HH:mm:ss').parse(newTime));
    return _convertToArabicIndic(formatted);
  }

  static String convertTodayYesterdayFormat(String createdAt) {
    debugPrint(
        '[CHAT:DATE_PARSE_CALLER] function=convertTodayYesterdayFormat raw=$createdAt');
    final now = _now();
    final DateTime? createdAtDate = tryParseDateTimeSafely(createdAt);
    if (createdAtDate == null) {
      debugPrint(
          '[CHAT:DATE_PARSE_FAIL_SAFE] function=convertTodayYesterdayFormat raw=$createdAt');
      return '';
    }

    if (createdAtDate.year == now.year &&
        createdAtDate.month == now.month &&
        createdAtDate.day == now.day) {
      String time =
          DateFormat.jm(_getLocale().toString()).format(createdAtDate);
      time = _convertToArabicIndic(time);
      return '${"today".tr}, $time';
    } else if (createdAtDate.year == now.year &&
        createdAtDate.month == now.month &&
        createdAtDate.day == now.day - 1) {
      String time =
          DateFormat.jm(_getLocale().toString()).format(createdAtDate);
      time = _convertToArabicIndic(time);
      return '${"yesterday".tr}, $time';
    } else {
      return DateConverter.localDateToIsoStringAMPM(createdAtDate);
    }
  }

  static String convertOnlyTodayTime(String createdAt) {
    debugPrint(
        '[CHAT:DATE_PARSE_CALLER] function=convertOnlyTodayTime raw=$createdAt');
    final now = _now();
    final DateTime? createdAtDate = tryParseDateTimeSafely(createdAt);
    if (createdAtDate == null) {
      debugPrint(
          '[CHAT:DATE_PARSE_FAIL_SAFE] function=convertOnlyTodayTime raw=$createdAt');
      return '';
    }

    if (createdAtDate.year == now.year &&
        createdAtDate.month == now.month &&
        createdAtDate.day == now.day) {
      final String formatted =
          DateFormat('h:mm a', _getLocale().toString()).format(createdAtDate);
      return _convertToArabicIndic(formatted);
    } else {
      return DateConverter.localDateToIsoStringAMPM(createdAtDate);
    }
  }

  static String convertRestaurantOpenTime(String time) {
    final String formatted = DateFormat('hh:mm a', _getLocale().toString())
        .format(DateFormat('HH:mm:ss').parse(time).toLocal());
    return _convertToArabicIndic(formatted);
  }

  static String dateTimeStringToFormattedTime(String dateTime) {
    final String formatted =
        DateFormat(_timeFormatter(), _getLocale().toString())
            .format(_parseFlexibleDateTime(dateTime));
    return _convertToArabicIndic(formatted);
  }

  static DateTime _parseFlexibleDateTime(String dateTime) {
    final DateTime? parsedDate = tryParseDateTimeSafely(dateTime);
    if (parsedDate != null) {
      return parsedDate;
    }
    if (kDebugMode) {
      debugPrint(
          '[CHAT:DATE_PARSE_FAIL_SAFE] function=_parseFlexibleDateTime raw=$dateTime');
    }
    return DateTime.now();
  }

  static DateTime formattingTripDateTime(
      DateTime pickedTime, DateTime pickedDate) {
    return DateTime(pickedDate.year, pickedDate.month, pickedDate.day,
        pickedTime.hour, pickedTime.minute);
  }

  static bool isSameDate(DateTime pickedTime) {
    final DateTime now = _now();
    return pickedTime.year == now.year &&
        pickedTime.month == now.month &&
        pickedTime.day == now.day &&
        pickedTime.hour == now.hour &&
        pickedTime.minute == now.minute;
  }

  static bool isAfterCurrentDateTime(DateTime pickedTime) {
    final DateTime pick = DateTime(pickedTime.year, pickedTime.month,
        pickedTime.day, pickedTime.hour, pickedTime.minute);
    final DateTime now = _now();
    final DateTime current =
        DateTime(now.year, now.month, now.day, now.hour, now.minute);
    return pick.isAfter(current);
  }

  static int durationFromNow(String time) {
    final DateTime parsedTime = DateTime.parse(time);
    return parsedTime.difference(_now()).inMinutes;
  }

  // Helper methods for locale-aware date formatting
  static Locale _getLocale() {
    try {
      return Get.find<LocalizationController>().locale;
    } catch (e) {
      return const Locale('en', 'US');
    }
  }

  static bool _isArabicLocale() {
    return _getLocale().languageCode == 'ar';
  }

  static String _convertToArabicIndic(String text) {
    if (!_isArabicLocale()) return text;
    const western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabicIndic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    String result = text;
    for (int i = 0; i < western.length; i++) {
      result = result.replaceAll(western[i], arabicIndic[i]);
    }
    return result;
  }

  static String normalizeArabicDigits(String input) {
    const List<String> arabicIndic = <String>[
      '٠',
      '١',
      '٢',
      '٣',
      '٤',
      '٥',
      '٦',
      '٧',
      '٨',
      '٩'
    ];
    const List<String> easternArabicIndic = <String>[
      '۰',
      '۱',
      '۲',
      '۳',
      '۴',
      '۵',
      '۶',
      '۷',
      '۸',
      '۹'
    ];
    String normalized = input;
    for (int index = 0; index < arabicIndic.length; index++) {
      normalized = normalized.replaceAll(arabicIndic[index], index.toString());
      normalized =
          normalized.replaceAll(easternArabicIndic[index], index.toString());
    }
    return normalized;
  }

  static DateTime? tryParseDateTimeSafely(String dateTime) {
    final String normalizedDateTime = normalizeArabicDigits(dateTime).trim();
    final DateTime? directParsed = DateTime.tryParse(normalizedDateTime);
    if (directParsed != null) {
      return directParsed.toLocal();
    }
    const List<String> patterns = <String>[
      'yyyy-MM-dd HH:mm:ss',
      'yyyy-MM-ddTHH:mm:ss',
      'yyyy-MM-ddTHH:mm:ss.SSS',
      'yyyy-MM-ddTHH:mm:ss.SSSSSS',
      'yyyy-MM-dd HH:mm:ss.SSS',
      'yyyy-MM-dd HH:mm:ss.SSSSSS',
    ];
    for (final String pattern in patterns) {
      try {
        return DateFormat(pattern).parse(normalizedDateTime, true).toLocal();
      } catch (_) {}
    }
    return null;
  }
}
