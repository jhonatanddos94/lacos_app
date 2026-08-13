import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/features/services/application/providers/service_providers.dart';

void invalidateServicesProvider(WidgetRef ref) {
  ref.invalidate(servicesProvider);
}
