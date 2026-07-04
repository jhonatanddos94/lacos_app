import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/features/clients/domain/entities/client_preview_data.dart';

final clientsDashboardProvider = Provider<ClientsDashboardData>((ref) {
  return const ClientsDashboardData(
    shortcuts: [
      ClientShortcutPreview(
        title: 'Hoje',
        subtitle: 'Próximos atendimentos',
        type: ClientShortcutType.today,
      ),
      ClientShortcutPreview(
        title: 'Aniversariantes',
        subtitle: 'Esta semana',
        type: ClientShortcutType.birthdays,
      ),
      ClientShortcutPreview(
        title: 'Reconectar',
        subtitle: 'Há mais tempo sem vir',
        type: ClientShortcutType.reconnect,
      ),
    ],
    clients: [
      ClientPreview(
        name: 'Ana Paula Silva',
        phone: '(67) 99999-9999',
        sinceLabel: 'Cliente desde 2023',
        memoryLabel: 'Prefere café sem açúcar',
        lastAppointmentDate: '04 Jul',
        lastAppointmentService: 'Corte + Escova',
        isFavorite: true,
        isActive: true,
      ),
      ClientPreview(
        name: 'Marina Santos',
        phone: '(67) 98888-8888',
        sinceLabel: 'Cliente desde 2024',
        memoryLabel: 'Tem uma Golden chamada Luna',
        lastAppointmentDate: '28 Jun',
        lastAppointmentService: 'Mechas',
        isFavorite: false,
        isActive: true,
      ),
      ClientPreview(
        name: 'Juliana Mendes',
        phone: '(67) 97777-7777',
        sinceLabel: 'Cliente desde 2023',
        memoryLabel: 'Vai viajar para Gramado',
        lastAppointmentDate: '18 Jun',
        lastAppointmentService: 'Coloração',
        isFavorite: true,
        isActive: true,
      ),
      ClientPreview(
        name: 'Carla Oliveira',
        phone: '(67) 96666-6666',
        sinceLabel: 'Cliente desde 2024',
        memoryLabel: 'Gosta de produtos veganos',
        lastAppointmentDate: '10 Jun',
        lastAppointmentService: 'Escova',
        isFavorite: false,
        isActive: true,
      ),
      ClientPreview(
        name: 'Beatriz Lima',
        phone: '(67) 95555-5555',
        sinceLabel: 'Cliente desde 2023',
        memoryLabel: 'Aniversário: 12 de Agosto',
        lastAppointmentDate: '05 Jun',
        lastAppointmentService: 'Corte',
        isFavorite: false,
        isActive: false,
      ),
    ],
  );
});
