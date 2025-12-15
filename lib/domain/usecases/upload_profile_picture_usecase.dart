import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class UploadProfilePictureUseCase {
  UploadProfilePictureUseCase(this._repository);

  final AuthRepository _repository;

  Future<User> call(String profilePicturePath) => 
      _repository.uploadProfilePicture(profilePicturePath);
}

