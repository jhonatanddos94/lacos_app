import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/router/route_paths.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/clients/presentation/widgets/client_card.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_empty_state.dart';

class ClientsListSection extends StatelessWidget {
  const ClientsListSection({
    required this.clients,
    required this.bottomPadding,
    super.key,
  });

  final List<Client> clients;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: bottomPadding),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.clientsListTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.graphite,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppStrings.clientsSortByName),
                  SizedBox(width: AppSpacing.xxxs),
                  Icon(Icons.keyboard_arrow_down_rounded),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        if (clients.isEmpty)
          const HomeEmptyState(
            icon: Icons.groups_2_outlined,
            title: AppStrings.emptyClientsTitle,
            message: AppStrings.emptyClientsMessage,
          )
        else ...[
          for (final client in clients) ...[
            ClientCard(
              client: client,
              onTap: () => context.push(
                RoutePaths.clientDetailsPath(client.id),
                extra: client,
              ),
            ),
            if (client != clients.last)
              const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ],
    );
  }
}
