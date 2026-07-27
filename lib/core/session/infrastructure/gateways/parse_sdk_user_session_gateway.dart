import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:lacos_app/core/session/domain/exceptions/parse_object_not_found_exception.dart';
import 'package:lacos_app/core/session/domain/gateways/parse_user_session_gateway.dart';
import 'package:lacos_app/core/session/infrastructure/mappers/parse_session_error_mapper.dart';

/// Adapter Parse SDK para [ParseUserSessionGateway].
class ParseSdkUserSessionGateway implements ParseUserSessionGateway {
  ParseSdkUserSessionGateway({ParseSessionErrorMapper? errorMapper})
    : _errorMapper = errorMapper ?? const ParseSessionErrorMapper();

  final ParseSessionErrorMapper _errorMapper;

  @override
  Future<ParseUserSnapshot?> currentUser() async {
    final user = await ParseUser.currentUser();
    if (user is! ParseUser) return null;
    return _toSnapshot(user);
  }

  @override
  Future<void> login({
    required String username,
    required String password,
  }) async {
    final response = await ParseUser(username, password, null).login();
    if (response.success) {
      return;
    }

    if (response.error?.code == ParseError.objectNotFound) {
      throw const ParseObjectNotFoundException();
    }

    throw FormatException(_errorMapper.toMessage(response.error));
  }

  @override
  Future<void> signUp({
    required String username,
    required String password,
    required String email,
  }) async {
    final response = await ParseUser(username, password, email).signUp();
    if (!response.success) {
      throw FormatException(_errorMapper.toMessage(response.error));
    }
  }

  @override
  Future<ParseUserSnapshot> becomeWithSessionToken(String sessionToken) async {
    final response = await ParseUser.getCurrentUserFromServer(sessionToken);
    if (response == null || !response.success) {
      throw FormatException(_errorMapper.toMessage(response?.error));
    }

    final user = await ParseUser.currentUser();
    if (user is! ParseUser || user.objectId == null || user.objectId!.isEmpty) {
      throw const FormatException(
        'Não foi possível preparar sua sessão. Tente novamente.',
      );
    }

    return _toSnapshot(user);
  }

  @override
  Future<void> logout() async {
    final currentUser = await ParseUser.currentUser();
    if (currentUser is! ParseUser) {
      return;
    }

    final response = await currentUser.logout();
    if (!response.success) {
      throw FormatException(_errorMapper.toMessage(response.error));
    }
  }

  @override
  Future<bool> userExistsByUsername(String username) async {
    final query = QueryBuilder<ParseUser>(ParseUser.forQuery())
      ..whereEqualTo(ParseUser.keyUsername, username);

    final response = await query.query<ParseUser>();
    if (!response.success) {
      throw FormatException(_errorMapper.toMessage(response.error));
    }

    return response.results?.isNotEmpty ?? false;
  }

  @override
  Future<void> clearLocalSession() async {
    try {
      final currentUser = await ParseUser.currentUser();
      if (currentUser is ParseUser) {
        await currentUser.logout();
      }
    } on Object {
      // Melhor esforço: não repropagar — limpeza parcial de estado.
    }
  }

  ParseUserSnapshot _toSnapshot(ParseUser user) {
    final objectId = user.objectId;
    if (objectId == null || objectId.isEmpty) {
      throw const FormatException(
        'Não foi possível preparar sua sessão. Tente novamente.',
      );
    }

    final firebaseUidValue = user.get<String>('firebaseUid');

    return ParseUserSnapshot(
      objectId: objectId,
      username: user.username ?? '',
      sessionTokenPresent:
          user.sessionToken != null && user.sessionToken!.isNotEmpty,
      firebaseUid: firebaseUidValue,
    );
  }
}
