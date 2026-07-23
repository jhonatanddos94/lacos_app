String formatServiceDuration(int minutes) {
  if (minutes <= 0) {
    return '';
  }

  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;

  if (hours == 0) {
    return '${remainingMinutes}min';
  }

  if (remainingMinutes == 0) {
    return '${hours}h';
  }

  return '${hours}h ${remainingMinutes}min';
}

String formatServicePrice(double price) {
  final normalized = price.toStringAsFixed(2).replaceAll('.', ',');
  final parts = normalized.split(',');
  final integerPart = _addThousandsSeparator(parts.first);
  final decimalPart = parts.length > 1 ? parts.last : '00';

  return 'R\$ $integerPart,$decimalPart';
}

String formatServiceDetails({int? durationMinutes, double? price}) {
  final parts = <String>[];

  if (durationMinutes != null && durationMinutes > 0) {
    parts.add(formatServiceDuration(durationMinutes));
  }

  if (price != null) {
    parts.add(formatServicePrice(price));
  }

  return parts.join(' • ');
}

String _addThousandsSeparator(String value) {
  final buffer = StringBuffer();
  for (var index = 0; index < value.length; index++) {
    if (index > 0 && (value.length - index) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(value[index]);
  }

  return buffer.toString();
}
