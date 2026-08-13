import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/features/agenda/application/agenda_day.dart';
import 'package:lacos_app/features/agenda/application/providers/calendar_today_providers.dart';
import 'package:lacos_app/features/shell/application/models/app_shell_tab.dart';
import 'package:lacos_app/features/shell/application/models/agenda_navigation_request.dart';

final appShellTabProvider =
    NotifierProvider<AppShellTabController, AppShellTab>(
      AppShellTabController.new,
    );

/// Solicitações externas para abrir a Agenda em um dia específico.
final agendaNavigationRequestProvider =
    NotifierProvider<AgendaNavigationRequestNotifier, AgendaNavigationRequest?>(
      AgendaNavigationRequestNotifier.new,
    );

/// Incrementado quando a Home pede para focar a busca de Clientes.
final clientsFocusSearchRequestProvider =
    NotifierProvider<ClientsFocusSearchRequest, int>(
      ClientsFocusSearchRequest.new,
    );

class AppShellTabController extends Notifier<AppShellTab> {
  @override
  AppShellTab build() => AppShellTab.home;

  void select(AppShellTab tab) {
    state = tab;
  }

  void selectIndex(int index) {
    select(AppShellTab.fromIndex(index));
  }

  void openAgendaOn(AgendaDay day) {
    state = AppShellTab.agenda;
    ref.read(agendaNavigationRequestProvider.notifier).request(day);
  }

  void openAgendaToday() {
    openAgendaOn(ref.read(calendarTodayProvider));
  }

  void openClientsSearch() {
    state = AppShellTab.clients;
    ref.read(clientsFocusSearchRequestProvider.notifier).request();
  }
}

class AgendaNavigationRequestNotifier extends Notifier<AgendaNavigationRequest?> {
  var _nextRequestId = 0;

  @override
  AgendaNavigationRequest? build() => null;

  void request(AgendaDay day) {
    _nextRequestId++;
    state = AgendaNavigationRequest(day: day, requestId: _nextRequestId);
  }
}

class ClientsFocusSearchRequest extends Notifier<int> {
  @override
  int build() => 0;

  void request() {
    state++;
  }
}
