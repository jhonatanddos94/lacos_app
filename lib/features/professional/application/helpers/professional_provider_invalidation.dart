import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/workspace/application/providers/workspace_providers.dart';
import 'package:lacos_app/features/professional/application/providers/professional_providers.dart';

void invalidateProfessionalSources(WidgetRef ref) {
  ref.invalidate(workspaceProvider);
  ref.invalidate(professionalsProvider);
}
