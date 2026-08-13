import 'package:lacos_app/features/agenda/application/agenda_day.dart';

class AgendaNavigationRequest {
  const AgendaNavigationRequest({
    required this.day,
    required this.requestId,
  });

  final AgendaDay day;
  final int requestId;
}
