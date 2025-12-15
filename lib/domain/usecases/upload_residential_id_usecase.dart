import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class UploadResidentialIdUseCase {
  UploadResidentialIdUseCase(this._repository);

  final AuthRepository _repository;

  Future<User> call(String documentPath, String type) => 
      _repository.uploadResidentialId(documentPath, type);
}

