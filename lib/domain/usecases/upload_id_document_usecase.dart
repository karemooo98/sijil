import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class UploadIdDocumentUseCase {
  UploadIdDocumentUseCase(this._repository);

  final AuthRepository _repository;

  Future<User> call(String documentPath, String type) => 
      _repository.uploadIdDocument(documentPath, type);
}

