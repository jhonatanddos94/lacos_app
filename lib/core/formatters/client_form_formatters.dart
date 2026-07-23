import 'package:flutter/services.dart';

import 'package:lacos_app/core/config/app_date_formats.dart';
import 'package:lacos_app/core/config/app_field_limits.dart';
import 'package:lacos_app/core/config/app_regex.dart';

const _firstValidDay = 1;
const _lastPossibleDay = 31;
const _firstValidMonth = 1;
const _lastValidMonth = 12;
const _firstValidYear = 1;
const _dayEndIndex = 2;
const _monthEndIndex = 4;

String digitsOnly(String value) {
  return value.replaceAll(RegExp(AppRegex.nonDigits), '');
}

String formatBrazilianPhone(String phone) {
  final digits = digitsOnly(phone);
  return const BrazilianPhoneInputFormatter()
      .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: digits))
      .text;
}

String formatBrazilianDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}

String normalizeInstagram(String value) {
  return value
      .trim()
      .replaceAll(RegExp(AppRegex.whitespace), '')
      .replaceFirst(RegExp(AppRegex.leadingAtSigns), '');
}

DateTime? parseBrazilianDate(String value) {
  final input = value.trim();
  if (input.length != AppDateFormats.birthDateHint.length) {
    return null;
  }

  final parts = input.split('/');
  if (parts.length != 3) {
    return null;
  }

  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) {
    return null;
  }

  if (day < _firstValidDay || day > _lastPossibleDay) {
    return null;
  }

  if (month < _firstValidMonth || month > _lastValidMonth) {
    return null;
  }

  if (year < _firstValidYear) {
    return null;
  }

  final date = DateTime(year, month, day);
  if (date.day != day || date.month != month || date.year != year) {
    return null;
  }

  final today = DateTime.now();
  final todayOnly = DateTime(today.year, today.month, today.day);
  if (date.isAfter(todayOnly)) {
    return null;
  }

  return date;
}

class BrazilianPhoneInputFormatter extends TextInputFormatter {
  const BrazilianPhoneInputFormatter();

  static const maxDigits = AppFieldLimits.clientPhone;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = digitsOnly(newValue.text);
    final limitedDigits = digits.length > maxDigits
        ? digits.substring(0, maxDigits)
        : digits;
    final formatted = _format(limitedDigits);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _format(String digits) {
    if (digits.isEmpty) {
      return '';
    }

    if (digits.length <= _dayEndIndex) {
      return '($digits';
    }

    final areaCode = digits.substring(0, _dayEndIndex);
    final phone = digits.substring(_dayEndIndex);

    if (phone.length <= 4) {
      return '($areaCode) $phone';
    }

    final prefixLength = phone.length == 9 ? 5 : 4;
    final prefix = phone.substring(0, prefixLength);
    final suffix = phone.substring(prefixLength);

    return suffix.isEmpty
        ? '($areaCode) $prefix'
        : '($areaCode) $prefix-$suffix';
  }
}

class BirthDateInputFormatter extends TextInputFormatter {
  const BirthDateInputFormatter();

  static const maxDigits = AppDateFormats.birthDateDigitsLength;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = digitsOnly(newValue.text);
    final limitedDigits = digits.length > maxDigits
        ? digits.substring(0, maxDigits)
        : digits;
    if (!_isValidPartialDate(limitedDigits)) {
      return oldValue;
    }

    final formatted = _format(limitedDigits);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  bool _isValidPartialDate(String digits) {
    if (digits.isEmpty) {
      return true;
    }

    if (digits.length == 1) {
      final firstDayDigit = int.tryParse(digits[0]);
      return firstDayDigit != null && firstDayDigit <= 3;
    }

    if (digits.length >= _dayEndIndex) {
      final day = int.tryParse(digits.substring(0, _dayEndIndex));
      if (day == null || day < _firstValidDay || day > _lastPossibleDay) {
        return false;
      }
    }

    if (digits.length >= _dayEndIndex + 1) {
      final firstMonthDigit = int.tryParse(digits[_dayEndIndex]);
      if (firstMonthDigit == null || firstMonthDigit > 1) {
        return false;
      }
    }

    if (digits.length >= _monthEndIndex) {
      final month = int.tryParse(
        digits.substring(_dayEndIndex, _monthEndIndex),
      );
      if (month == null ||
          month < _firstValidMonth ||
          month > _lastValidMonth) {
        return false;
      }
    }

    if (digits.length == maxDigits) {
      final year = int.tryParse(digits.substring(_monthEndIndex, maxDigits));
      if (year == null || year > DateTime.now().year) {
        return false;
      }

      return parseBrazilianDate(_format(digits)) != null;
    }

    return true;
  }

  String _format(String digits) {
    if (digits.length <= _dayEndIndex) {
      return digits;
    }

    if (digits.length <= _monthEndIndex) {
      return '${digits.substring(0, _dayEndIndex)}/'
          '${digits.substring(_dayEndIndex)}';
    }

    return '${digits.substring(0, _dayEndIndex)}/'
        '${digits.substring(_dayEndIndex, _monthEndIndex)}/'
        '${digits.substring(_monthEndIndex)}';
  }
}

typedef BrazilianDateInputFormatter = BirthDateInputFormatter;

class InstagramInputFormatter extends TextInputFormatter {
  const InstagramInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final normalized = normalizeInstagram(newValue.text);
    final limitedValue = normalized.length > AppFieldLimits.clientInstagram
        ? normalized.substring(0, AppFieldLimits.clientInstagram)
        : normalized;

    return TextEditingValue(
      text: limitedValue,
      selection: TextSelection.collapsed(offset: limitedValue.length),
    );
  }
}
