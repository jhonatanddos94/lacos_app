import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:lacos_app/core/session/domain/repositories/session_repository.dart';
import 'package:lacos_app/core/session/infrastructure/mappers/parse_session_error_mapper.dart';
import 'package:lacos_app/features/auth/domain/entities/authenticated_user.dart';
import 'package:lacos_app/features/auth/domain/repositories/auth_repository.dart';

/// Sincroniza o usuário autenticado no Firebase com a sessão Parse.
class ParseSessionRepository implements SessionRepository {
  ParseSessionRepository(
    AuthRepository authRepository, {
    ParseSessionErrorMapper? errorMapper,
  }) : _authRepository = authRepository,
       _errorMapper = errorMapper ?? const ParseSessionErrorMapper();

  final AuthRepository _authRepository;
  final ParseSessionErrorMapper _errorMapper;

  @override
  Future<void> syncAuthenticatedUser() async {
    try {
      final firebaseUser = _authRepository.currentUser;
      if (firebaseUser == null) {
        throw StateError('Não encontramos uma sessão ativa. Entre novamente.');
      }

      await _loginOrCreateParseUser(firebaseUser);
      await _ensureCurrentParseUser(firebaseUser.id);
    } on StateError {
      rethrow;
    } on FormatException {
      rethrow;
    } on Object {
      throw const FormatException(
        'Não foi possível preparar sua sessão. Tente novamente.',
      );
    }
  }

  Future<void> _loginOrCreateParseUser(AuthenticatedUser firebaseUser) async {
    final username = firebaseUser.id;
    final password = _buildParsePassword(username);
    final loginResponse = await ParseUser(username, password, null).login();

    if (loginResponse.success) {
      return;
    }

    final error = loginResponse.error;
    if (error?.code != ParseError.objectNotFound) {
      throw FormatException(_errorMapper.toMessage(error));
    }

    final userExists = await _parseUserExists(username);
    if (userExists) {
      throw const FormatException(
        'Não foi possível preparar sua sessão. Tente novamente.',
      );
    }

    await _createParseUser(firebaseUser, password);
  }

  Future<bool> _parseUserExists(String username) async {
    final query = QueryBuilder<ParseUser>(ParseUser.forQuery())
      ..whereEqualTo(ParseUser.keyUsername, username);

    final response = await query.query<ParseUser>();
    if (!response.success) {
      throw FormatException(_errorMapper.toMessage(response.error));
    }

    return response.results?.isNotEmpty ?? false;
  }

  Future<void> _createParseUser(
    AuthenticatedUser firebaseUser,
    String password,
  ) async {
    final parseUser = ParseUser(firebaseUser.id, password, firebaseUser.email);
    final response = await parseUser.signUp();

    if (!response.success) {
      throw FormatException(_errorMapper.toMessage(response.error));
    }
  }

  Future<void> _ensureCurrentParseUser(String firebaseUid) async {
    final currentParseUser = await ParseUser.currentUser();
    if (_isSameParseUser(currentParseUser, firebaseUid)) {
      return;
    }

    throw const FormatException(
      'Não foi possível preparar sua sessão. Tente novamente.',
    );
  }

  bool _isSameParseUser(Object? parseUser, String firebaseUid) {
    return parseUser is ParseUser && parseUser.username == firebaseUid;
  }

  String _buildParsePassword(String uid) {
    // TODO: substituir por Cloud Code/Auth Adapter ou token customizado.
    return 'lacos_parse_session_v1_$uid';
  }
}
