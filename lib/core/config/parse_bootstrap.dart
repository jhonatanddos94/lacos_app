import 'package:flutter/foundation.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:lacos_app/core/config/app_environment.dart';

Future<void> initializeParse() async {
  await Parse().initialize(
    AppEnvironment.parseApplicationId,
    AppEnvironment.parseServerUrl,
    clientKey: AppEnvironment.parseClientKey,
    autoSendSessionId: true,
    debug: kDebugMode,
  );
}
