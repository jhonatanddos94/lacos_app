import 'package:lacos_app/features/services/domain/entities/service.dart';
import 'package:lacos_app/features/services/domain/repositories/service_repository.dart';

Service buildTestService({
  String id = 'service-1',
  String name = 'Corte feminino',
  int? durationMinutes = 60,
  double? price = 80,
  bool isActive = true,
  String? category,
  String? description,
}) {
  final now = DateTime(2026, 8, 13, 10);
  return Service(
    id: id,
    name: name,
    category: category,
    durationMinutes: durationMinutes,
    price: price,
    description: description,
    isActive: isActive,
    createdAt: now,
    updatedAt: now,
  );
}

class FakeServiceRepository implements ServiceRepository {
  FakeServiceRepository({List<Service> seed = const [], this.findAllError})
    : items = List<Service>.of(seed);

  final List<Service> items;
  Object? findAllError;
  int findAllCallCount = 0;
  int _nextId = 1;

  @override
  Future<List<Service>> findAll() async {
    findAllCallCount++;
    final error = findAllError;
    if (error != null) {
      throw error;
    }

    final active = items.where((service) => service.isActive).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return List<Service>.unmodifiable(active);
  }

  @override
  Future<Service> create({
    required String name,
    required int durationMinutes,
    String? category,
    double? price,
    String? description,
  }) async {
    final now = DateTime(2026, 8, 13, 10);
    final service = Service(
      id: 'created-${_nextId++}',
      name: name,
      category: category,
      durationMinutes: durationMinutes,
      price: price,
      description: description,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
    items.add(service);
    return service;
  }

  @override
  Future<Service> update(Service service) async {
    final index = items.indexWhere((item) => item.id == service.id);
    if (index < 0) {
      throw StateError('Serviço não encontrado.');
    }

    final updated = Service(
      id: service.id,
      name: service.name,
      category: service.category,
      durationMinutes: service.durationMinutes,
      price: service.price,
      description: service.description,
      isActive: service.isActive,
      createdAt: service.createdAt,
      updatedAt: DateTime(2026, 8, 13, 11),
    );
    items[index] = updated;
    return updated;
  }

  @override
  Future<void> delete(String serviceId) async {
    final index = items.indexWhere((item) => item.id == serviceId);
    if (index < 0) {
      throw StateError('Serviço não encontrado.');
    }

    final current = items[index];
    items[index] = Service(
      id: current.id,
      name: current.name,
      category: current.category,
      durationMinutes: current.durationMinutes,
      price: current.price,
      description: current.description,
      isActive: false,
      createdAt: current.createdAt,
      updatedAt: DateTime(2026, 8, 13, 11),
    );
  }
}
