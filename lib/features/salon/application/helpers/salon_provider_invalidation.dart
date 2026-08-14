import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/workspace/application/providers/workspace_providers.dart';

void invalidateSalonSources(WidgetRef ref) {
  ref.invalidate(workspaceProvider);
}
