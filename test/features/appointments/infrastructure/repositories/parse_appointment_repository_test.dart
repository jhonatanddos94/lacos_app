import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lacos_app/features/appointments/domain/enums/appointment_canceled_by.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/domain/exceptions/appointment_exceptions.dart';
import 'package:lacos_app/features/appointments/infrastructure/errors/parse_appointment_error_mapper.dart';
import 'package:lacos_app/features/appointments/infrastructure/repositories/parse_appointment_repository.dart';
import 'package:lacos_app/features/salon/domain/entities/salon.dart';
import 'package:lacos_app/features/salon/domain/repositories/salon_repository.dart';

const _serverUrl = 'https://test.example.com';
const _currentSalonId = 'salon-current';
const _otherSalonId = 'salon-other';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _RecordingParseClient parseClient;
  late _FakeSalonRepository salonRepository;
  late ParseAppointmentRepository repository;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await Parse().initialize(
      'test-app-id',
      _serverUrl,
      clientKey: 'test-client-key',
      appName: 'lacos_app_test',
      appPackageName: 'com.lacos.app.test',
      appVersion: '1.0.0',
      fileDirectory: '/tmp/lacos_app_test',
      clientCreator: ({required sendSessionId, securityContext}) {
        return _ParseClientScope.instance.client ?? _RecordingParseClient();
      },
    );
  });

  setUp(() {
    parseClient = _RecordingParseClient();
    _ParseClientScope.instance.client = parseClient;
    salonRepository = _FakeSalonRepository(salon: _currentSalon());
    repository = ParseAppointmentRepository(salonRepository);
  });

  tearDown(() {
    _ParseClientScope.instance.client = null;
  });

  group('ParseAppointmentRepository', () {
    group('_requireCurrentSalon (via métodos públicos)', () {
      test('findById lança StateError quando salão ausente', () async {
        salonRepository.salon = null;

        expect(
          () => repository.findById('appointment-1'),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              'Não encontramos seu salão. Cadastre um salão antes de continuar.',
            ),
          ),
        );
        expect(parseClient.getCallCount, 0);
      });

      test('findNextByClientId lança StateError quando salão ausente', () async {
        salonRepository.salon = null;

        expect(
          () => repository.findNextByClientId(
            'client-1',
            now: DateTime(2026, 7, 15, 12),
          ),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              'Não encontramos seu salão. Cadastre um salão antes de continuar.',
            ),
          ),
        );
        expect(parseClient.getCallCount, 0);
      });
    });

    group('findById', () {
      test('retorna appointment quando fetch e salão coincidem', () async {
        parseClient.handler = (request) async {
          if (request.method == 'GET' &&
              request.path.contains('/classes/Appointment/appointment-1')) {
            return _successResponse(
              _appointmentPayload(
                id: 'appointment-1',
                salonId: _currentSalonId,
              ),
            );
          }
          throw StateError(
            'Requisição inesperada: ${request.method} ${request.path}',
          );
        };

        final appointment = await repository.findById('appointment-1');

        expect(appointment.id, 'appointment-1');
        expect(appointment.salonId, _currentSalonId);
        expect(parseClient.getCallCount, 1);
      });

      test(
        'lança AppointmentNotFoundException quando appointment pertence a outro salão',
        () async {
          parseClient.handler = (request) async {
            if (request.method == 'GET' &&
                request.path.contains('/classes/Appointment/appointment-1')) {
              return _successResponse(
                _appointmentPayload(
                  id: 'appointment-1',
                  salonId: _otherSalonId,
                ),
              );
            }
            throw StateError(
              'Requisição inesperada: ${request.method} ${request.path}',
            );
          };

          expect(
            () => repository.findById('appointment-1'),
            throwsA(isA<AppointmentNotFoundException>()),
          );
        },
      );

      test('registra falha de rede no fetch como FormatException', () async {
        parseClient.handler = (request) async {
          throw Exception('connection failed');
        };

        expect(
          () => repository.findById('appointment-1'),
          throwsA(isA<FormatException>()),
        );
      });

      test('lança AppointmentNotFoundException para ID vazio', () async {
        expect(
          () => repository.findById(''),
          throwsA(isA<AppointmentNotFoundException>()),
        );
        expect(parseClient.getCallCount, 0);
      });

      test(
        'lança AppointmentNotFoundException para ID somente com espaços',
        () async {
          expect(
            () => repository.findById('   '),
            throwsA(isA<AppointmentNotFoundException>()),
          );
          expect(parseClient.getCallCount, 0);
        },
      );

      test(
        'lança AppointmentNotFoundException para objeto inexistente (Parse 101)',
        () async {
          parseClient.handler = (request) async {
            return _parseErrorResponse(
              code: ParseError.objectNotFound,
              message: 'Object not found.',
              statusCode: 404,
            );
          };

          expect(
            () => repository.findById('missing-appointment'),
            throwsA(isA<AppointmentNotFoundException>()),
          );
        },
      );

      test(
        'lança FormatException para resposta aparentemente bem-sucedida sem hidratação',
        () async {
          parseClient.handler = (request) async {
            return _successResponse(<String, dynamic>{
              'objectId': 'missing-appointment',
            });
          };

          expect(
            () => repository.findById('missing-appointment'),
            throwsA(
              isA<FormatException>().having(
                (error) => error.message,
                'message',
                'Não foi possível carregar o agendamento. Tente novamente.',
              ),
            ),
          );
        },
      );

      test(
        'lança FormatException para payload malformado sem virar not found',
        () async {
          parseClient.handler = (request) async {
            return _successResponse(
              _appointmentPayload(
                id: 'appointment-1',
                salonId: _currentSalonId,
                status: 'invalid-status',
              ),
            );
          };

          expect(
            () => repository.findById('appointment-1'),
            throwsA(isA<FormatException>()),
          );
        },
      );
    });

    group('complete', () {
      test(
        'conclui appointment pendente, preenche completedAt e persiste status',
        () async {
          parseClient.handler = (request) async {
            if (request.method == 'GET' &&
                request.path.contains('/classes/Appointment/appointment-1')) {
              return _successResponse(
                _appointmentPayload(
                  id: 'appointment-1',
                  salonId: _currentSalonId,
                  status: 'confirmed',
                ),
              );
            }

            if (request.method == 'PUT' &&
                request.path.contains('/classes/Appointment/appointment-1')) {
              final body = jsonDecode(request.data!) as Map<String, dynamic>;
              expect(body['status'], 'completed');
              expect(body['completedAt'], isNotNull);

              return _successResponse(
                _appointmentPayload(
                  id: 'appointment-1',
                  salonId: _currentSalonId,
                  status: 'completed',
                  completedAt: DateTime.utc(2026, 7, 15, 18),
                ),
              );
            }

            throw StateError(
              'Requisição inesperada: ${request.method} ${request.path}',
            );
          };

          final appointment = await repository.complete('appointment-1');

          expect(appointment.status, AppointmentStatus.completed);
          expect(appointment.completedAt, isNotNull);
          expect(parseClient.getCallCount, 1);
          expect(parseClient.putCallCount, 1);
        },
      );

      test('é idempotente quando appointment já está concluído', () async {
        final completedAt = DateTime.utc(2026, 7, 10, 16, 30);

        parseClient.handler = (request) async {
          if (request.method == 'GET' &&
              request.path.contains('/classes/Appointment/appointment-1')) {
            return _successResponse(
              _appointmentPayload(
                id: 'appointment-1',
                salonId: _currentSalonId,
                status: 'completed',
                completedAt: completedAt,
              ),
            );
          }

          throw StateError(
            'Requisição inesperada: ${request.method} ${request.path}',
          );
        };

        final appointment = await repository.complete('appointment-1');

        expect(appointment.status, AppointmentStatus.completed);
        expect(appointment.completedAt, completedAt.toLocal());
        expect(parseClient.putCallCount, 0);
        expect(parseClient.postCallCount, 0);
      });

      test(
        'lança AppointmentCannotCompleteException para status inválido',
        () async {
          parseClient.handler = (request) async {
            return _successResponse(
              _appointmentPayload(
                id: 'appointment-1',
                salonId: _currentSalonId,
                status: 'canceled',
              ),
            );
          };

          expect(
            () => repository.complete('appointment-1'),
            throwsA(isA<AppointmentCannotCompleteException>()),
          );
          expect(parseClient.putCallCount, 0);
        },
      );

      test('lança AppointmentNotFoundException para ID vazio', () async {
        expect(
          () => repository.complete(''),
          throwsA(isA<AppointmentNotFoundException>()),
        );
        expect(parseClient.getCallCount, 0);
      });

      test(
        'lança AppointmentNotFoundException para objeto inexistente (Parse 101)',
        () async {
          parseClient.handler = (request) async {
            return _parseErrorResponse(
              code: ParseError.objectNotFound,
              message: 'Object not found.',
              statusCode: 404,
            );
          };

          expect(
            () => repository.complete('missing-appointment'),
            throwsA(isA<AppointmentNotFoundException>()),
          );
        },
      );

      test('registra falha de rede no fetch como FormatException', () async {
        parseClient.handler = (request) async {
          throw Exception('connection failed');
        };

        expect(
          () => repository.complete('appointment-1'),
          throwsA(isA<FormatException>()),
        );
        expect(parseClient.putCallCount, 0);
      });

      test(
        'lança FormatException para resposta aparentemente bem-sucedida sem hidratação',
        () async {
          parseClient.handler = (request) async {
            return _successResponse(<String, dynamic>{
              'objectId': 'missing-appointment',
            });
          };

          expect(
            () => repository.complete('missing-appointment'),
            throwsA(isA<FormatException>()),
          );
          expect(parseClient.putCallCount, 0);
        },
      );

      test(
        'lança AppointmentNotFoundException quando pertence a outro salão',
        () async {
          parseClient.handler = (request) async {
            return _successResponse(
              _appointmentPayload(
                id: 'appointment-1',
                salonId: _otherSalonId,
                status: 'confirmed',
              ),
            );
          };

          expect(
            () => repository.complete('appointment-1'),
            throwsA(isA<AppointmentNotFoundException>()),
          );
          expect(parseClient.putCallCount, 0);
        },
      );
    });

    group('findNextByClientId', () {
      test(
        'retorna null para id vazio sem consultar salão nem Parse',
        () async {
          for (final clientId in ['', '   ']) {
            salonRepository.getCurrentSalonCallCount = 0;
            parseClient.resetCounts();

            final result = await repository.findNextByClientId(
              clientId,
              now: DateTime(2026, 7, 15, 12),
            );

            expect(result, isNull);
            expect(salonRepository.getCurrentSalonCallCount, 0);
            expect(parseClient.getCallCount, 0);
          }
        },
      );

      test('retorna null quando query não encontra resultados', () async {
        parseClient.handler = (request) async {
          return _successResponse(<String, dynamic>{'results': <dynamic>[]});
        };

        final result = await repository.findNextByClientId(
          'client-1',
          now: DateTime(2026, 7, 15, 12),
        );

        expect(result, isNull);
        expect(parseClient.getCallCount, 1);
      });

      test(
        'retorna primeiro appointment e monta query com filtros esperados',
        () async {
          final now = DateTime(2026, 7, 15, 12);

          parseClient.handler = (request) async {
            final uri = Uri.parse(request.path);
            final whereRaw = uri.queryParameters['where'];
            expect(whereRaw, isNotNull);

            final where = jsonDecode(whereRaw!) as Map<String, dynamic>;
            expect(where['salon'], {
              '__type': 'Pointer',
              'className': 'Salon',
              'objectId': _currentSalonId,
            });
            expect(where['client'], {
              '__type': 'Pointer',
              'className': 'Client',
              'objectId': 'client-1',
            });
            expect(where['isActive'], isTrue);
            expect(where['status'], {
              '\$in': ['pending', 'confirmed'],
            });
            expect(where['endAt'], {
              '\$gt': {'__type': 'Date', 'iso': now.toUtc().toIso8601String()},
            });
            expect(uri.queryParameters['limit'], '1');
            expect(uri.queryParameters['order'], 'startAt');

            return _successResponse(<String, dynamic>{
              'results': [
                _appointmentPayload(
                  id: 'next-appointment',
                  salonId: _currentSalonId,
                  clientId: 'client-1',
                  status: 'pending',
                ),
              ],
            });
          };

          final result = await repository.findNextByClientId(
            'client-1',
            now: now,
          );

          expect(result, isNotNull);
          expect(result!.id, 'next-appointment');
          expect(result.clientId, 'client-1');
        },
      );
    });

    group('respostas Parse (query e save)', () {
      test(
        'query com success == false lança FormatException do error mapper',
        () async {
          const errorMapper = ParseAppointmentErrorMapper();

          parseClient.handler = (request) async {
            return _parseErrorResponse(
              code: ParseError.invalidQuery,
              message: 'Invalid query',
              statusCode: 400,
            );
          };

          expect(
            () => repository.findNextByClientId(
              'client-1',
              now: DateTime(2026, 7, 15, 12),
            ),
            throwsA(
              isA<FormatException>().having(
                (error) => error.message,
                'message',
                errorMapper.toMessage(
                  ParseError(
                    code: ParseError.invalidQuery,
                    message: 'Invalid query',
                  ),
                ),
              ),
            ),
          );
        },
      );

      test(
        'save com success == false lança FormatException com forSave: true',
        () async {
          const errorMapper = ParseAppointmentErrorMapper();

          parseClient.handler = (request) async {
            if (request.method == 'GET') {
              return _successResponse(
                _appointmentPayload(
                  id: 'appointment-1',
                  salonId: _currentSalonId,
                  status: 'confirmed',
                ),
              );
            }

            if (request.method == 'PUT') {
              return _parseErrorResponse(
                code: ParseError.internalServerError,
                message: 'Internal server error',
                statusCode: 500,
              );
            }

            throw StateError(
              'Requisição inesperada: ${request.method} ${request.path}',
            );
          };

          expect(
            () => repository.complete('appointment-1'),
            throwsA(
              isA<FormatException>().having(
                (error) => error.message,
                'message',
                errorMapper.toMessage(
                  ParseError(
                    code: ParseError.internalServerError,
                    message: 'Internal server error',
                  ),
                  forSave: true,
                ),
              ),
            ),
          );
        },
      );
    });

    group('cancel', () {
      test('cancela appointment pending com sucesso', () async {
        final beforeCancel = DateTime.now();

        parseClient.handler = (request) async {
          if (request.method == 'GET' &&
              request.path.contains('/classes/Appointment/appointment-1')) {
            return _successResponse(
              _appointmentPayload(
                id: 'appointment-1',
                salonId: _currentSalonId,
                status: 'pending',
              ),
            );
          }

          if (request.method == 'PUT' &&
              request.path.contains('/classes/Appointment/appointment-1')) {
            final body = jsonDecode(request.data!) as Map<String, dynamic>;
            expect(body['status'], 'canceled');
            expect(body['canceledBy'], 'client');
            expect(body['canceledAt'], isNotNull);
            expect(body['cancellationReason'], 'Cliente desistiu');

            return _successResponse(
              _appointmentPayload(
                id: 'appointment-1',
                salonId: _currentSalonId,
                status: 'canceled',
                canceledBy: 'client',
                cancellationReason: 'Cliente desistiu',
                canceledAt: DateTime.now().toUtc(),
              ),
            );
          }

          throw StateError(
            'Requisição inesperada: ${request.method} ${request.path}',
          );
        };

        final appointment = await repository.cancel(
          appointmentId: 'appointment-1',
          canceledBy: AppointmentCanceledBy.client,
          cancellationReason: 'Cliente desistiu',
        );

        final afterCancel = DateTime.now();

        expect(appointment.status, AppointmentStatus.canceled);
        expect(appointment.isActive, isTrue);
        expect(appointment.canceledBy, AppointmentCanceledBy.client);
        expect(appointment.cancellationReason, 'Cliente desistiu');
        expect(appointment.canceledAt, isNotNull);
        expect(
          appointment.canceledAt!.isAfter(
            beforeCancel.subtract(const Duration(seconds: 1)),
          ),
          isTrue,
        );
        expect(
          appointment.canceledAt!.isBefore(
            afterCancel.add(const Duration(seconds: 1)),
          ),
          isTrue,
        );
        expect(parseClient.getCallCount, 1);
        expect(parseClient.putCallCount, 1);
      });

      test('cancela appointment confirmed com sucesso', () async {
        parseClient.handler = (request) async {
          if (request.method == 'GET' &&
              request.path.contains('/classes/Appointment/appointment-1')) {
            return _successResponse(
              _appointmentPayload(
                id: 'appointment-1',
                salonId: _currentSalonId,
                status: 'confirmed',
              ),
            );
          }

          if (request.method == 'PUT' &&
              request.path.contains('/classes/Appointment/appointment-1')) {
            final body = jsonDecode(request.data!) as Map<String, dynamic>;
            expect(body['status'], 'canceled');

            return _successResponse(
              _appointmentPayload(
                id: 'appointment-1',
                salonId: _currentSalonId,
                status: 'canceled',
                canceledBy: 'salon',
                canceledAt: DateTime.now().toUtc(),
              ),
            );
          }

          throw StateError(
            'Requisição inesperada: ${request.method} ${request.path}',
          );
        };

        final appointment = await repository.cancel(
          appointmentId: 'appointment-1',
          canceledBy: AppointmentCanceledBy.salon,
          cancellationReason: 'Cliente confirmou presença',
        );

        expect(appointment.status, AppointmentStatus.canceled);
        expect(parseClient.getCallCount, 1);
        expect(parseClient.putCallCount, 1);
      });

      test(
        'lança AppointmentCannotCancelCompletedException para status completed',
        () async {
          parseClient.handler = (request) async {
            return _successResponse(
              _appointmentPayload(
                id: 'appointment-1',
                salonId: _currentSalonId,
                status: 'completed',
                completedAt: DateTime.utc(2026, 7, 10, 16),
              ),
            );
          };

          expect(
            () => repository.cancel(
              appointmentId: 'appointment-1',
              canceledBy: AppointmentCanceledBy.client,
            ),
            throwsA(isA<AppointmentCannotCancelCompletedException>()),
          );
          expect(parseClient.putCallCount, 0);
        },
      );

      test(
        'lança AppointmentAlreadyCanceledException para status canceled',
        () async {
          parseClient.handler = (request) async {
            return _successResponse(
              _appointmentPayload(
                id: 'appointment-1',
                salonId: _currentSalonId,
                status: 'canceled',
                canceledBy: 'client',
                canceledAt: DateTime.utc(2026, 7, 10, 12),
              ),
            );
          };

          expect(
            () => repository.cancel(
              appointmentId: 'appointment-1',
              canceledBy: AppointmentCanceledBy.salon,
            ),
            throwsA(isA<AppointmentAlreadyCanceledException>()),
          );
          expect(parseClient.putCallCount, 0);
        },
      );

      test(
        'lança AppointmentNotFoundException quando appointment pertence a outro salão',
        () async {
          parseClient.handler = (request) async {
            return _successResponse(
              _appointmentPayload(
                id: 'appointment-1',
                salonId: _otherSalonId,
                status: 'pending',
              ),
            );
          };

          expect(
            () => repository.cancel(
              appointmentId: 'appointment-1',
              canceledBy: AppointmentCanceledBy.client,
            ),
            throwsA(isA<AppointmentNotFoundException>()),
          );
          expect(parseClient.putCallCount, 0);
        },
      );

      test('lança AppointmentNotFoundException para Parse 101', () async {
        parseClient.handler = (request) async {
          return _parseErrorResponse(
            code: ParseError.objectNotFound,
            message: 'Object not found.',
            statusCode: 404,
          );
        };

        expect(
          () => repository.cancel(
            appointmentId: 'missing-appointment',
            canceledBy: AppointmentCanceledBy.client,
          ),
          throwsA(isA<AppointmentNotFoundException>()),
        );
      });

      test('lança FormatException para falha de rede no fetch', () async {
        parseClient.handler = (request) async {
          throw Exception('connection failed');
        };

        expect(
          () => repository.cancel(
            appointmentId: 'appointment-1',
            canceledBy: AppointmentCanceledBy.client,
          ),
          throwsA(isA<FormatException>()),
        );
        expect(parseClient.putCallCount, 0);
      });

      test(
        'lança FormatException para resposta aparentemente bem-sucedida sem hidratação',
        () async {
          parseClient.handler = (request) async {
            return _successResponse(<String, dynamic>{
              'objectId': 'appointment-1',
            });
          };

          expect(
            () => repository.cancel(
              appointmentId: 'appointment-1',
              canceledBy: AppointmentCanceledBy.client,
            ),
            throwsA(isA<FormatException>()),
          );
          expect(parseClient.putCallCount, 0);
        },
      );

      test(
        'lança FormatException quando save retorna success == false',
        () async {
          const errorMapper = ParseAppointmentErrorMapper();

          parseClient.handler = (request) async {
            if (request.method == 'GET') {
              return _successResponse(
                _appointmentPayload(
                  id: 'appointment-1',
                  salonId: _currentSalonId,
                  status: 'pending',
                ),
              );
            }

            if (request.method == 'PUT') {
              return _parseErrorResponse(
                code: ParseError.internalServerError,
                message: 'Internal server error',
                statusCode: 500,
              );
            }

            throw StateError(
              'Requisição inesperada: ${request.method} ${request.path}',
            );
          };

          expect(
            () => repository.cancel(
              appointmentId: 'appointment-1',
              canceledBy: AppointmentCanceledBy.client,
            ),
            throwsA(
              isA<FormatException>().having(
                (error) => error.message,
                'message',
                errorMapper.toMessage(
                  ParseError(
                    code: ParseError.internalServerError,
                    message: 'Internal server error',
                  ),
                  forSave: true,
                ),
              ),
            ),
          );
        },
      );

      test(
        'não mantém motivo anterior quando cancellationReason é null',
        () async {
          parseClient.handler = (request) async {
            if (request.method == 'GET' &&
                request.path.contains('/classes/Appointment/appointment-1')) {
              return _successResponse(
                _appointmentPayload(
                  id: 'appointment-1',
                  salonId: _currentSalonId,
                  status: 'pending',
                  cancellationReason: 'Motivo anterior',
                ),
              );
            }

          if (request.method == 'PUT' &&
              request.path.contains('/classes/Appointment/appointment-1')) {
            final body = jsonDecode(request.data!) as Map<String, dynamic>;
            final reason = body['cancellationReason'];
            expect(
              reason,
              anyOf(isNull, predicate<Map<String, dynamic>>(
                (value) => value['__op'] == 'Delete',
              )),
            );

            return _successResponse(
              _appointmentPayload(
                id: 'appointment-1',
                salonId: _currentSalonId,
                status: 'canceled',
                canceledBy: 'client',
                canceledAt: DateTime.now().toUtc(),
              ),
            );
          }

            throw StateError(
              'Requisição inesperada: ${request.method} ${request.path}',
            );
          };

          final appointment = await repository.cancel(
            appointmentId: 'appointment-1',
            canceledBy: AppointmentCanceledBy.client,
          );

          expect(appointment.cancellationReason, isNull);
        },
      );
    });
  });
}

Salon _currentSalon() {
  return Salon(
    id: _currentSalonId,
    name: 'Salão Teste',
    responsibleName: 'Responsável',
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

Map<String, dynamic> _appointmentPayload({
  required String id,
  required String salonId,
  String clientId = 'client-1',
  String professionalId = 'professional-1',
  String ownerId = 'owner-1',
  String status = 'pending',
  DateTime? completedAt,
  DateTime? canceledAt,
  String? canceledBy,
  String? cancellationReason,
  DateTime? startAt,
  DateTime? endAt,
}) {
  final resolvedStartAt = startAt ?? DateTime.utc(2026, 7, 15, 14);
  final resolvedEndAt = endAt ?? DateTime.utc(2026, 7, 15, 15);

  return {
    'objectId': id,
    'salon': {'__type': 'Pointer', 'className': 'Salon', 'objectId': salonId},
    'client': {
      '__type': 'Pointer',
      'className': 'Client',
      'objectId': clientId,
    },
    'professional': {
      '__type': 'Pointer',
      'className': 'Professional',
      'objectId': professionalId,
    },
    'owner': {'__type': 'Pointer', 'className': '_User', 'objectId': ownerId},
    'startAt': _parseDate(resolvedStartAt),
    'endAt': _parseDate(resolvedEndAt),
    'status': status,
    'isActive': true,
    if (completedAt != null) 'completedAt': _parseDate(completedAt),
    if (canceledAt != null) 'canceledAt': _parseDate(canceledAt),
    '?canceledBy': canceledBy,
    '?cancellationReason': cancellationReason,
    'createdAt': _parseDate(DateTime.utc(2026, 7, 1, 10)),
    'updatedAt': _parseDate(DateTime.utc(2026, 7, 1, 10)),
  };
}

Map<String, dynamic> _parseDate(DateTime value) {
  return {'__type': 'Date', 'iso': value.toUtc().toIso8601String()};
}

ParseNetworkResponse _successResponse(Object payload) {
  return ParseNetworkResponse(statusCode: 200, data: jsonEncode(payload));
}

ParseNetworkResponse _parseErrorResponse({
  required int code,
  required String message,
  required int statusCode,
}) {
  return ParseNetworkResponse(
    statusCode: statusCode,
    data: jsonEncode({'code': code, 'error': message}),
  );
}

class _ParseClientScope {
  static final _ParseClientScope instance = _ParseClientScope._();

  _ParseClientScope._();

  _RecordingParseClient? client;
}

class _FakeSalonRepository implements SalonRepository {
  _FakeSalonRepository({this.salon});

  Salon? salon;
  int getCurrentSalonCallCount = 0;

  @override
  Future<Salon?> getCurrentSalon() async {
    getCurrentSalonCallCount++;
    return salon;
  }

  @override
  Future<Salon> create({
    required String name,
    required String responsibleName,
  }) {
    throw UnimplementedError();
  }
}

class _RecordedRequest {
  const _RecordedRequest({required this.method, required this.path, this.data});

  final String method;
  final String path;
  final String? data;
}

typedef _ParseRequestHandler =
    Future<ParseNetworkResponse> Function(_RecordedRequest request);

class _RecordingParseClient implements ParseClient {
  _ParseRequestHandler? handler;

  int getCallCount = 0;
  int putCallCount = 0;
  int postCallCount = 0;

  @override
  ParseCoreData get data => ParseCoreData();

  void resetCounts() {
    getCallCount = 0;
    putCallCount = 0;
    postCallCount = 0;
  }

  Future<ParseNetworkResponse> _dispatch(
    String method,
    String path, {
    String? data,
  }) async {
    final request = _RecordedRequest(method: method, path: path, data: data);
    final handler = this.handler;
    if (handler == null) {
      throw StateError('Handler Parse não configurado para $method $path');
    }
    return handler(request);
  }

  @override
  Future<ParseNetworkResponse> delete(
    String path, {
    ParseNetworkOptions? options,
  }) {
    throw UnimplementedError('DELETE não usado nestes testes: $path');
  }

  @override
  Future<ParseNetworkResponse> get(
    String path, {
    ParseNetworkOptions? options,
    ProgressCallback? onReceiveProgress,
  }) async {
    getCallCount++;
    return _dispatch('GET', path);
  }

  @override
  Future<ParseNetworkByteResponse> getBytes(
    String path, {
    ParseNetworkOptions? options,
    ProgressCallback? onReceiveProgress,
    dynamic cancelToken,
  }) {
    throw UnimplementedError('getBytes não usado nestes testes: $path');
  }

  @override
  Future<ParseNetworkResponse> post(
    String path, {
    String? data,
    ParseNetworkOptions? options,
  }) async {
    postCallCount++;
    return _dispatch('POST', path, data: data);
  }

  @override
  Future<ParseNetworkResponse> postBytes(
    String path, {
    Stream<List<int>>? data,
    ParseNetworkOptions? options,
    ProgressCallback? onSendProgress,
    dynamic cancelToken,
  }) {
    throw UnimplementedError('postBytes não usado nestes testes: $path');
  }

  @override
  Future<ParseNetworkResponse> put(
    String path, {
    String? data,
    ParseNetworkOptions? options,
  }) async {
    putCallCount++;
    return _dispatch('PUT', path, data: data);
  }
}
