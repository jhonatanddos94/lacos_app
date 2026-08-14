import 'dart:async';

import 'package:lacos_app/core/external_url/external_url_launcher.dart';

class FakeExternalUrlLauncher implements ExternalUrlLauncher {
  FakeExternalUrlLauncher({this.result = true});

  bool result;
  Object? error;
  Completer<bool>? completer;
  int calls = 0;
  final launchedUris = <Uri>[];

  @override
  Future<bool> launch(Uri uri) async {
    calls++;
    launchedUris.add(uri);
    if (error != null) throw error!;
    if (completer != null) return completer!.future;
    return result;
  }
}
