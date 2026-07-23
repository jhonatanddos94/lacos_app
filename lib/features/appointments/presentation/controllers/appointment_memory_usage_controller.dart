import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppointmentMemoryUsageState {
  const AppointmentMemoryUsageState({this.usedMemoryIds = const {}});

  final Set<String> usedMemoryIds;

  AppointmentMemoryUsageState copyWith({Set<String>? usedMemoryIds}) {
    return AppointmentMemoryUsageState(
      usedMemoryIds: usedMemoryIds ?? this.usedMemoryIds,
    );
  }
}

class AppointmentMemoryUsageController
    extends StateNotifier<AppointmentMemoryUsageState> {
  AppointmentMemoryUsageController()
    : super(const AppointmentMemoryUsageState());

  void markUsed(String memoryId) {
    final normalizedId = memoryId.trim();
    if (normalizedId.isEmpty || state.usedMemoryIds.contains(normalizedId)) {
      return;
    }

    state = state.copyWith(
      usedMemoryIds: {...state.usedMemoryIds, normalizedId},
    );
  }

  void unmarkUsed(String memoryId) {
    final normalizedId = memoryId.trim();
    if (normalizedId.isEmpty || !state.usedMemoryIds.contains(normalizedId)) {
      return;
    }

    final updatedIds = {...state.usedMemoryIds}..remove(normalizedId);
    state = state.copyWith(usedMemoryIds: updatedIds);
  }

  void toggleUsed(String memoryId) {
    final normalizedId = memoryId.trim();
    if (normalizedId.isEmpty) {
      return;
    }

    if (state.usedMemoryIds.contains(normalizedId)) {
      unmarkUsed(normalizedId);
      return;
    }

    markUsed(normalizedId);
  }

  void clear() {
    if (state.usedMemoryIds.isEmpty) {
      return;
    }

    state = const AppointmentMemoryUsageState();
  }
}
