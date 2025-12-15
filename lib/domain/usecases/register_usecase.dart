import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  RegisterUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthSession> call({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
    String? employeeNumber,
  }) =>
      _repository.register(
        name: name,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
        employeeNumber: employeeNumber,
      );
}

