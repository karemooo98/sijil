import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../core/constants/app_routes.dart';
import '../../core/storage/app_preferences.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/usecases/fetch_profile_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/restore_session_usecase.dart';

class AuthController extends GetxController {
  AuthController({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.fetchProfileUseCase,
    required this.restoreSessionUseCase,
    required this.appPreferences,
  });

  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final FetchProfileUseCase fetchProfileUseCase;
  final RestoreSessionUseCase restoreSessionUseCase;
  final AppPreferences appPreferences;

  final Rx<AuthSession?> session = Rx<AuthSession?>(null);
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();

  bool get isAuthenticated => session.value != null;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) => initSession());
  }

  Future<void> initSession() async {
    try {
    // Ensure preferences are loaded; if the platform channel fails, the
    // AppPreferences class will fall back to in-memory storage.
    if (!appPreferences.hasSeenOnboarding) {
      _goTo(AppRoutes.onboarding);
      return;
    }

      isLoading.value = true;
      errorMessage.value = null;
      
      final AuthSession? restored = await restoreSessionUseCase();
      session.value = restored;
      
      if (restored != null) {
        try {
        await fetchProfile();
        } catch (_) {
          // Ignore profile fetch errors, continue with navigation
        }
        _goTo(AppRoutes.dashboard);
      } else {
        _goTo(AppRoutes.login);
      }
    } catch (error) {
      // Clear any error message and navigate to login
      errorMessage.value = null;
      _goTo(AppRoutes.login);
    } finally {
      isLoading.value = false;
    }
  }

  void _goTo(String route) {
    Future.microtask(() => Get.offAllNamed(route));
  }

  Future<void> login(String email, String password) async {
    try {
      errorMessage.value = null;
      isLoading.value = true;
      final AuthSession newSession = await loginUseCase(
        LoginParams(email: email.trim(), password: password.trim()),
      );
      session.value = newSession;
      Get.offAllNamed(AppRoutes.dashboard);
    } catch (error) {
      errorMessage.value = error.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
    String? employeeNumber,
  }) async {
    try {
      errorMessage.value = null;
      isLoading.value = true;
      final AuthSession newSession = await registerUseCase(
        name: name.trim(),
        email: email.trim(),
        password: password.trim(),
        phoneNumber: phoneNumber?.trim(),
        employeeNumber: employeeNumber?.trim(),
      );
      session.value = newSession;
      Get.offAllNamed(AppRoutes.dashboard);
    } catch (error) {
      errorMessage.value = error.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchProfile() async {
    try {
      final updatedUser = await fetchProfileUseCase();
      if (session.value != null) {
        session.value = AuthSession(
          token: session.value!.token,
          user: updatedUser,
        );
      }
    } catch (_) {
      // ignore profile fetch errors silently
    }
  }

  Future<void> logout() async {
    await logoutUseCase();
    session.value = null;
    Get.offAllNamed(AppRoutes.login);
  }
}
