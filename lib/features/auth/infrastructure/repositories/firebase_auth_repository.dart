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
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _mapper = mapper ?? const FirebaseUserMapper(),
       _errorMapper = errorMapper ?? const FirebaseAuthErrorMapper();

  final FirebaseAuth _firebaseAuth;
  final FirebaseUserMapper _mapper;
  final FirebaseAuthErrorMapper _errorMapper;

  @override
  Stream<AuthenticatedUser?> get authenticatedUser =>
      _firebaseAuth.authStateChanges().map(_mapper.toDomain);

  @override
  AuthenticatedUser? get currentUser =>
      _mapper.toDomain(_firebaseAuth.currentUser);

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
        throw StateError('Não foi possível entrar. Tente novamente.');
      }

      return user;
    } on FirebaseAuthException catch (error) {
      throw FormatException(_errorMapper.toMessage(error.code));
    }
  }

  @override
  Future<AuthenticatedUser> createAccount({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = _mapper.toDomain(credential.user);
      if (user == null) {
        throw StateError('Não foi possível criar sua conta. Tente novamente.');
      }

      return user;
    } on FirebaseAuthException catch (error) {
      throw FormatException(_errorMapper.toMessage(error.code));
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        throw StateError('Não encontramos uma sessão ativa. Entre novamente.');
      }
      await currentUser.sendEmailVerification();
    } on FirebaseAuthException catch (error) {
      throw FormatException(_errorMapper.toMessage(error.code));
    }
  }

  @override
  Future<AuthenticatedUser?> reloadUser() async {
    try {
      await _firebaseAuth.currentUser?.reload();
      return _mapper.toDomain(_firebaseAuth.currentUser);
    } on FirebaseAuthException catch (error) {
      throw FormatException(_errorMapper.toMessage(error.code));
    }
  }

  @override
  Future<void> deleteCurrentUser() async {
    try {
      await _firebaseAuth.currentUser?.delete();
    } on FirebaseAuthException catch (error) {
      throw FormatException(_errorMapper.toMessage(error.code));
    }
  }

  @override
  Future<void> signOut() => _firebaseAuth.signOut();
}
