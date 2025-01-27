import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

// methods for converting between board's GMT time and local time
class TimeConverter {

  // Convert board GMT time to local time
  static String parseBoardTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return "";
    try {
      final timeFormatRegex = RegExp(r'^\d{2}:\d{2}$');
      if (!timeFormatRegex.hasMatch(timeStr)) {
        throw FormatException("Invalid time format: $timeStr");
      }
      DateTime gmtTime = DateFormat("HH:mm").parseUtc(timeStr);
      DateTime localTime = gmtTime.toLocal();
      return DateFormat("HH:mm").format(localTime);
    } catch (e) {
      return "Invalid Time";
    }
  }

  // convert a local timezone to GMT string for feeder to parse
  static String convertToBoardTime(TimeOfDay time) {
    try {
      final now = DateTime.now();
      final DateTime dateTime = DateTime(
          now.year, now.month, now.day, time.hour, time.minute);
      final DateTime gmtDateTime = dateTime.toUtc();
      final String formattedTime = DateFormat('HH:mm').format(gmtDateTime);
      return formattedTime;
    } catch (e) {
      return "error";
    }
  }

  static TimeOfDay parseTimeOfDayString(String time) {
    try {
      final parts = time.split(':');
      if (parts.length != 2) throw FormatException('Invalid time format');
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      if (hours < 0 || hours > 23 || minutes < 0 || minutes > 59) {
        throw FormatException('Invalid hour or minute value');
      }
      return TimeOfDay(hour: hours, minute: minutes);
    } catch (e) {
      throw FormatException('Error parsing time: $e');
    }
  }
}