import 'package:firebase_auth/firebase_auth.dart';

import 'package:lacos_app/features/auth/domain/entities/authenticated_user.dart';
import 'package:lacos_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:lacos_app/features/auth/infrastructure/mappers/firebase_auth_error_mapper.dart';
import 'package:lacos_app/features/auth/infrastructure/mappers/firebase_user_mapper.dart';

/// Implementação de [AuthRepository] com Firebase Authentication.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseUserMapper? mapper,
    FirebaseAuthErrorMapper? errorMapper,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _mapper = mapper ?? const FirebaseUserMapper(),
        _errorMapper = errorMapper ?? const FirebaseAuthErrorMapper();

  final FirebaseAuth _firebaseAuth;
  final FirebaseUserMapper _mapper;
  final FirebaseAuthErrorMapper _errorMapper;

  @override
  Stream<AuthenticatedUser?> get authenticatedUser =>
      _firebaseAuth.authStateChanges().map(_mapper.toDomain);

  @override
  Future<AuthenticatedUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = _mapper.toDomain(credential.user);
      if (user == null) {
        throw StateError(
          'Não foi possível entrar. Tente novamente.',
        );
      }

      return user;
    } on FirebaseAuthException catch (error) {
      throw FormatException(_errorMapper.toMessage(error.code));
    }
  }

  @override
  Future<void> signOut() => _firebaseAuth.signOut();
}
