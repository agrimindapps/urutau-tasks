// Formatação de datas pela região do dispositivo (spec 09, RF-04/CA-06):
// os textos seguem o idioma da interface e os formatos seguem a região
// do sistema, mesmo quando as duas diferem.
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

Locale _deviceLocale() =>
    WidgetsBinding.instance.platformDispatcher.locale;

/// Converte o locale para o formato `pt_BR` usado pelo `intl`.
String _intlLocale(Locale locale) {
  final country = locale.countryCode;
  return (country == null || country.isEmpty)
      ? locale.languageCode
      : '${locale.languageCode}_$country';
}

/// Data de calendário no formato curto da região do dispositivo.
String formatDeviceDate(DateTime date) {
  final locale = _deviceLocale();
  return DateFormat.yMMMd(_intlLocale(locale)).format(date.toLocal());
}

/// Data e horário da região do dispositivo.
String formatDeviceDateTime(DateTime moment) {
  final local = moment.toLocal();
  return '${formatDeviceDate(local)} ${formatDeviceTime(local)}';
}

/// Somente o horário da região do dispositivo.
String formatDeviceTime(DateTime time) {
  final locale = _deviceLocale();
  return DateFormat.Hm(_intlLocale(locale)).format(time.toLocal());
}
