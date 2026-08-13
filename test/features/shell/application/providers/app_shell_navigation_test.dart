import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/agenda/application/agenda_day.dart';
import 'package:lacos_app/features/agenda/application/providers/calendar_today_providers.dart';
import 'package:lacos_app/features/shell/application/models/app_shell_tab.dart';
import 'package:lacos_app/features/shell/application/providers/app_shell_providers.dart';

import '../../../../helpers/home_test_fixtures.dart';

void main() {
  test('openAgendaOn seleciona tab Agenda e emite request com dia', () {
    final container = ProviderContainer(
      overrides: [
        calendarTodayProvider.overrideWithValue(AgendaDay.from(homeTestNow)),
      ],
    );
    addTearDown(container.dispose);

    const targetDay = AgendaDay(year: 2026, month: 8, day: 15);

    container.read(appShellTabProvider.notifier).openAgendaOn(targetDay);

    expect(container.read(appShellTabProvider), AppShellTab.agenda);
    expect(container.read(agendaNavigationRequestProvider)?.day, targetDay);
    expect(container.read(agendaNavigationRequestProvider)?.requestId, 1);
  });

  test('openAgendaToday delega para o dia civil atual', () {
    final today = AgendaDay.from(homeTestNow);
    final container = ProviderContainer(
      overrides: [
        calendarTodayProvider.overrideWithValue(today),
      ],
    );
    addTearDown(container.dispose);

    container.read(appShellTabProvider.notifier).openAgendaToday();

    expect(container.read(agendaNavigationRequestProvider)?.day, today);
  });

  test('requests repetidos para o mesmo dia incrementam requestId', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const targetDay = AgendaDay(year: 2026, month: 8, day: 15);
    final notifier = container.read(appShellTabProvider.notifier);

    notifier.openAgendaOn(targetDay);
    notifier.openAgendaOn(targetDay);

    expect(container.read(agendaNavigationRequestProvider)?.requestId, 2);
  });
}
