import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

bool get isAdsPlatformSupported {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS;
}
