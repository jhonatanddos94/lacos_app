import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/clients/domain/entities/client_preview_data.dart';
import 'package:lacos_app/features/clients/presentation/widgets/client_card.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_empty_state.dart';

class ClientsListSection extends StatelessWidget {
  const ClientsListSection({required this.clients, super.key});

  final List<ClientPreview> clients;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Todos os clientes',
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
                  Text('Mais recentes'),
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
            title: 'Nenhuma cliente por aqui',
            message: 'Quando você cadastrar clientes, elas aparecerão aqui.',
          )
        else
          Column(
            children: [
              for (final client in clients) ...[
                ClientCard(client: client),
                if (client != clients.last)
                  const SizedBox(height: AppSpacing.xs),
              ],
            ],
          ),
      ],
    );
  }
}
