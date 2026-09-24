import 'package:flutter/material.dart';

/// Keeps date-picker values as Gregorian calendar fields, independent of the
/// device time zone. This is for date-only values such as task due dates; local
/// date/time pickers for reminders should continue using Flutter's default
/// delegate.
class UtcGregorianCalendarDelegate extends CalendarDelegate<DateTime> {
  const UtcGregorianCalendarDelegate();

  @override
  DateTime now() => DateTime.now();

  @override
  DateTime dateOnly(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);

  @override
  int monthDelta(DateTime startDate, DateTime endDate) =>
      (endDate.year - startDate.year) * DateTime.monthsPerYear +
      endDate.month -
      startDate.month;

  @override
  DateTime addMonthsToMonthDate(DateTime monthDate, int monthsToAdd) =>
      DateTime.utc(monthDate.year, monthDate.month + monthsToAdd);

  @override
  DateTime addDaysToDate(DateTime date, int days) =>
      DateTime.utc(date.year, date.month, date.day + days);

  @override
  int firstDayOffset(int year, int month, MaterialLocalizations localizations) {
    final weekdayFromMonday = DateTime.utc(year, month).weekday - 1;
    final firstDayFromMonday = (localizations.firstDayOfWeekIndex - 1) % 7;
    return (weekdayFromMonday - firstDayFromMonday) % 7;
  }

  @override
  int getDaysInMonth(int year, int month) =>
      DateUtils.getDaysInMonth(year, month);

  @override
  DateTime getMonth(int year, int month) => DateTime.utc(year, month);

  @override
  DateTime getDay(int year, int month, int day) =>
      DateTime.utc(year, month, day);

  @override
  String formatMonthYear(DateTime date, MaterialLocalizations localizations) =>
      localizations.formatMonthYear(date);

  @override
  String formatMediumDate(DateTime date, MaterialLocalizations localizations) =>
      localizations.formatMediumDate(date);

  @override
  String formatShortMonthDay(
    DateTime date,
    MaterialLocalizations localizations,
  ) => localizations.formatShortMonthDay(date);

  @override
  String formatShortDate(DateTime date, MaterialLocalizations localizations) =>
      localizations.formatShortDate(date);

  @override
  String formatFullDate(DateTime date, MaterialLocalizations localizations) =>
      localizations.formatFullDate(date);

  @override
  String formatCompactDate(
    DateTime date,
    MaterialLocalizations localizations,
  ) => localizations.formatCompactDate(date);

  @override
  DateTime? parseCompactDate(
    String? inputString,
    MaterialLocalizations localizations,
  ) {
    final parsed = localizations.parseCompactDate(inputString);
    return parsed == null ? null : dateOnly(parsed);
  }

  @override
  String dateHelpText(MaterialLocalizations localizations) =>
      localizations.dateHelpText;
}
