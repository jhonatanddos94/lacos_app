import 'package:flutter/services.dart';

import 'package:lacos_app/core/formatters/client_form_formatters.dart';

String formatBrazilianPriceInput(String value) {
  final digits = digitsOnly(value);
  return const BrazilianPriceInputFormatter()
      .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: digits))
      .text;
}

double? parseBrazilianPrice(String value) {
  final digits = digitsOnly(value);
  if (digits.isEmpty) {
    return null;
  }

  return int.parse(digits) / 100;
}

class BrazilianPriceInputFormatter extends TextInputFormatter {
  const BrazilianPriceInputFormatter();

  static const _maxDigits = 9;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = digitsOnly(newValue.text);
    final limitedDigits = digits.length > _maxDigits
        ? digits.substring(0, _maxDigits)
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

    final normalized = digits.padLeft(3, '0');
    final cents = normalized.substring(normalized.length - 2);
    final integerPart = normalized.substring(0, normalized.length - 2);
    final formattedInteger = _addThousandsSeparator(
      integerPart.replaceFirst(RegExp(r'^0+(?=\d)'), ''),
    );

    return 'R\$ $formattedInteger,$cents';
  }

  String _addThousandsSeparator(String value) {
    if (value.isEmpty) {
      return '0';
    }

    final buffer = StringBuffer();
    for (var index = 0; index < value.length; index++) {
      if (index > 0 && (value.length - index) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(value[index]);
    }

    return buffer.toString();
  }
}
