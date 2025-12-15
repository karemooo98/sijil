import '../entities/auth_session.dart';
import '../entities/user.dart';

abstract interface class AuthRepository {
  Future<AuthSession> login({required String email, required String password});
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
    String? employeeNumber,
  });

  Future<void> logout();

  Future<User> fetchProfile();
  Future<User> updateProfile({
    String? name,
    String? email,
    String? password,
    String? phoneNumber,
    String? accountNumber,
    String? walletNumber,
    List<String>? weekendDays,
  });
  
  Future<User> uploadProfilePicture(String profilePicturePath);
  Future<User> uploadIdDocument(String documentPath, String type);
  Future<User> uploadResidentialId(String documentPath, String type);

  Future<AuthSession?> restoreSession();
}
