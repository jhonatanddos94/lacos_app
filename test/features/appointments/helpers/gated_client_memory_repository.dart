import 'dart:async';

import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/domain/repositories/client_memory_repository.dart';

class GatedClientMemoryRepository implements ClientMemoryRepository {
  GatedClientMemoryRepository({
    this.findCompleter,
    this.touchCompleter,
    this.memories = const [],
    this.touchError,
    this.findError,
  });

  Completer<List<ClientMemory>>? findCompleter;
  Completer<void>? touchCompleter;
  List<ClientMemory> memories;
  Object? touchError;
  Object? findError;
  var findByClientCalls = 0;
  var touchCalls = 0;
  List<String> lastTouchedIds = const [];

  @override
  Future<List<ClientMemory>> findByClient({
    required String clientId,
    bool includeArchived = false,
  }) async {
    findByClientCalls++;
    final error = findError;
    if (error != null) {
      throw error;
    }

    final pending = findCompleter;
    if (pending != null) {
      return pending.future;
    }

    return memories;
  }

  @override
  Future<void> touchMentioned({required List<String> memoryIds}) async {
    touchCalls++;
    lastTouchedIds = List<String>.from(memoryIds);
    final error = touchError;
    if (error != null) {
      throw error;
    }

    final pending = touchCompleter;
    if (pending != null) {
      return pending.future;
    }
  }

  @override
  Future<void> markMentioned(String memoryId) async {}

  @override
  Future<ClientMemory> create(ClientMemory memory) {
    throw UnimplementedError();
  }

  @override
  Future<ClientMemory> update(ClientMemory memory) {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String memoryId) {
    throw UnimplementedError();
  }

  @override
  Future<ClientMemory> setPinned({
    required String memoryId,
    required bool isPinned,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ClientMemory> archive(String memoryId) {
    throw UnimplementedError();
  }

  @override
  Future<ClientMemory> restore(String memoryId) {
    throw UnimplementedError();
  }
}

ClientMemory gatedMemory({required String id, required String content}) {
  final stamp = DateTime(2026, 8, 13, 9);
  return ClientMemory(
    id: id,
    clientId: 'client-1',
    salonId: 'salon-1',
    ownerId: 'owner-1',
    content: content,
    isActive: true,
    createdAt: stamp,
    updatedAt: stamp,
  );
}
