abstract final class AppRegex {
  static const String numbersOnly = r'^\d+$';
  static const String nonDigits = r'\D';
  static const String instagram = r'^[A-Za-z0-9._]+$';
  static const String email = r'^[^\s@]+@[^\s@]+\.[^\s@]+$';
  static const String phone = r'^\d{10,11}$';
  static const String whitespace = r'\s+';
  static const String leadingAtSigns = r'^@+';
}
