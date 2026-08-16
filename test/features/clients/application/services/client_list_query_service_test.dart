import 'package:flutter_test/flutter_test.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/clients/application/services/client_list_query_service.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/clients/domain/enums/client_list_filter.dart';

void main() {
  group('ClientListQueryService', () {
    final now = DateTime(2026, 8, 14);
    final ana = Client(
      id: '1',
      name: 'Ana Souza',
      phone: '11988887777',
      instagram: 'ana.souza',
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
    final maria = Client(
      id: '2',
      name: 'Maria Lima',
      phone: '21999990000',
      isActive: true,
      isFavorite: true,
      createdAt: now,
      updatedAt: now,
    );
    final marina = Client(
      id: '3',
      name: 'Marina Costa',
      phone: '11911112222',
      isActive: true,
      isFavorite: true,
      createdAt: now,
      updatedAt: now,
    );
    final clients = [ana, maria, marina];

    test('Todas preserva a ordem recebida', () {
      final result = ClientListQueryService.apply(
        clients: clients,
        filter: ClientListFilter.all,
        query: '',
      );

      expect(result.map((client) => client.id), ['1', '2', '3']);
    });

    test('Favoritas mostra só isFavorite == true na mesma ordem', () {
      final result = ClientListQueryService.apply(
        clients: clients,
        filter: ClientListFilter.favorites,
        query: '',
      );

      expect(result.map((client) => client.id), ['2', '3']);
    });

    test('busca filtra sobre o conjunto já filtrado', () {
      final result = ClientListQueryService.apply(
        clients: clients,
        filter: ClientListFilter.favorites,
        query: 'Mar',
      );

      expect(result.map((client) => client.name), ['Maria Lima', 'Marina Costa']);
    });

    test('busca por telefone e Instagram continua local', () {
      expect(
        ClientListQueryService.apply(
          clients: clients,
          filter: ClientListFilter.all,
          query: '98888',
        ).single.name,
        'Ana Souza',
      );
      expect(
        ClientListQueryService.apply(
          clients: clients,
          filter: ClientListFilter.all,
          query: 'ana.souza',
        ).single.name,
        'Ana Souza',
      );
    });

    test('empty states são distintos', () {
      expect(
        ClientListQueryService.emptyCopy(
          filter: ClientListFilter.all,
          hasSearchQuery: false,
        ).title,
        AppStrings.emptyAllClientsTitle,
      );
      expect(
        ClientListQueryService.emptyCopy(
          filter: ClientListFilter.favorites,
          hasSearchQuery: false,
        ).title,
        AppStrings.emptyFavoritesTitle,
      );
      expect(
        ClientListQueryService.emptyCopy(
          filter: ClientListFilter.all,
          hasSearchQuery: true,
        ).title,
        AppStrings.emptyClientsSearchTitle,
      );
      expect(
        ClientListQueryService.emptyCopy(
          filter: ClientListFilter.favorites,
          hasSearchQuery: true,
        ).title,
        AppStrings.emptyFavoritesSearchTitle,
      );
    });
  });
}
