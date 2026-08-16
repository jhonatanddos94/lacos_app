import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/formatters/client_form_formatters.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/clients/domain/enums/client_list_filter.dart';

class ClientListEmptyCopy {
  const ClientListEmptyCopy({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;
}

class ClientListQueryService {
  const ClientListQueryService._();

  static List<Client> apply({
    required List<Client> clients,
    required ClientListFilter filter,
    required String query,
  }) {
    final filtered = _applyFilter(clients, filter);
    return _applySearch(filtered, query);
  }

  static ClientListEmptyCopy emptyCopy({
    required ClientListFilter filter,
    required bool hasSearchQuery,
  }) {
    if (hasSearchQuery && filter == ClientListFilter.favorites) {
      return const ClientListEmptyCopy(
        title: AppStrings.emptyFavoritesSearchTitle,
        message: AppStrings.emptyFavoritesSearchMessage,
        icon: Icons.search_rounded,
      );
    }

    if (hasSearchQuery) {
      return const ClientListEmptyCopy(
        title: AppStrings.emptyClientsSearchTitle,
        message: AppStrings.emptyClientsSearchMessage,
        icon: Icons.search_rounded,
      );
    }

    if (filter == ClientListFilter.favorites) {
      return const ClientListEmptyCopy(
        title: AppStrings.emptyFavoritesTitle,
        message: AppStrings.emptyFavoritesMessage,
        icon: Icons.favorite_border_rounded,
      );
    }

    return const ClientListEmptyCopy(
      title: AppStrings.emptyAllClientsTitle,
      message: AppStrings.emptyAllClientsMessage,
      icon: Icons.groups_2_outlined,
    );
  }

  static List<Client> _applyFilter(
    List<Client> clients,
    ClientListFilter filter,
  ) {
    return switch (filter) {
      ClientListFilter.all => List<Client>.unmodifiable(clients),
      ClientListFilter.favorites => List<Client>.unmodifiable(
        clients.where((client) => client.isFavorite),
      ),
    };
  }

  static List<Client> _applySearch(List<Client> clients, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return List<Client>.unmodifiable(clients);
    }

    final queryDigits = digitsOnly(normalizedQuery);

    return List<Client>.unmodifiable(
      clients.where((client) {
        final name = client.name.toLowerCase();
        final phone = client.phone.toLowerCase();
        final phoneDigits = digitsOnly(client.phone);
        final instagram = client.instagram?.toLowerCase() ?? '';

        return name.contains(normalizedQuery) ||
            phone.contains(normalizedQuery) ||
            instagram.contains(normalizedQuery) ||
            (queryDigits.isNotEmpty && phoneDigits.contains(queryDigits));
      }),
    );
  }
}
