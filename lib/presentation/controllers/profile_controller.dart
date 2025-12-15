import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/fetch_profile_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/usecases/upload_profile_picture_usecase.dart';
import '../../domain/usecases/upload_id_document_usecase.dart';
import '../../domain/usecases/upload_residential_id_usecase.dart';
import 'auth_controller.dart';

class ProfileController extends GetxController {
  ProfileController({
    required this.fetchProfileUseCase,
    required this.updateProfileUseCase,
    required this.uploadProfilePictureUseCase,
    required this.uploadIdDocumentUseCase,
    required this.uploadResidentialIdUseCase,
  });

  final FetchProfileUseCase fetchProfileUseCase;
  final UpdateProfileUseCase updateProfileUseCase;
  final UploadProfilePictureUseCase uploadProfilePictureUseCase;
  final UploadIdDocumentUseCase uploadIdDocumentUseCase;
  final UploadResidentialIdUseCase uploadResidentialIdUseCase;

  final Rx<User?> profile = Rx<User?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isUpdating = false.obs;
  final RxBool isUploadingImage = false.obs;
  final RxBool isUploadingDocument = false.obs;
  final RxnString errorMessage = RxnString();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final User user = await fetchProfileUseCase();
      print('📥 Profile loaded: ${user.name}');
      print('📸 Profile photo: ${user.photo}');
      print('📸 Profile photo type: ${user.photo.runtimeType}');
      profile.value = user;
    } catch (e) {
      print('❌ Error loading profile: $e');
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? email,
    String? password,
    String? phoneNumber,
    String? accountNumber,
    String? walletNumber,
    List<String>? weekendDays,
  }) async {
    try {
      isUpdating.value = true;
      errorMessage.value = '';
      final User updatedUser = await updateProfileUseCase(
        name: name,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
        accountNumber: accountNumber,
        walletNumber: walletNumber,
        weekendDays: weekendDays,
      );
      profile.value = updatedUser;

      // Update auth session
      final AuthController authController = Get.find<AuthController>();
      if (authController.session.value != null) {
        authController.session.value = AuthSession(
          token: authController.session.value!.token,
          user: updatedUser,
        );
      }

      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  Future<void> pickAndUploadImage() async {
    try {
      isUploadingImage.value = true;
      errorMessage.value = '';
      
      print('📸 Starting image picker...');
      
      // Show dialog to choose source
      final ImageSource? source = await Get.dialog<ImageSource>(
        AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Get.back(result: ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Get.back(result: ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source == null) {
        print('❌ No source selected');
        isUploadingImage.value = false;
        return;
      }

      print('📸 Picking image from: ${source == ImageSource.gallery ? "Gallery" : "Camera"}');
      
      // Pick image from gallery or camera
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      ).catchError((dynamic error) {
        print('❌ Error picking image: $error');
        throw error;
      });

      if (image == null) {
        print('❌ No image selected');
        isUploadingImage.value = false;
        return;
      }

      print('✅ Image selected: ${image.path}');
      print('📤 Starting upload via dedicated endpoint...');

      // Upload the image using the dedicated endpoint
      // This will automatically fetch the updated profile
      final User updatedUser = await uploadProfilePictureUseCase(image.path);
      
      print('✅ Upload successful!');
      print('📝 Updated user from API: ${updatedUser.name}');
      print('📸 Photo URL from API: ${updatedUser.photo}');
      
      // Update profile
      profile.value = updatedUser;

      // Update auth session
      final AuthController authController = Get.find<AuthController>();
      if (authController.session.value != null) {
        authController.session.value = AuthSession(
          token: authController.session.value!.token,
          user: updatedUser,
        );
        print('✅ Auth session updated with photo: ${authController.session.value?.user.photo}');
      }

      Get.snackbar(
        'Success',
        'Profile picture updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } on PlatformException catch (e) {
      print('❌ PlatformException uploading image:');
      print('Error code: ${e.code}');
      print('Error message: ${e.message}');
      print('Error details: ${e.details}');
      
      String errorMsg = 'Failed to access image picker';
      if (e.code == 'photo_access_denied' || e.code == 'camera_access_denied') {
        errorMsg = 'Please grant permission to access photos/camera in settings';
      } else if (e.code == 'channel-error') {
        errorMsg = 'Image picker error. Please try again or restart the app.';
      } else {
        errorMsg = e.message ?? 'Unknown error occurred';
      }
      
      errorMessage.value = errorMsg;
      
      Get.snackbar(
        'Error',
        errorMsg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } catch (e, stackTrace) {
      print('❌ ERROR uploading image:');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: $stackTrace');
      
      String errorMsg = e.toString();
      if (e.toString().contains('Exception:')) {
        errorMsg = e.toString().replaceAll('Exception: ', '');
      }
      
      errorMessage.value = errorMsg;
      
      Get.snackbar(
        'Error',
        'Failed to upload image: $errorMsg',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isUploadingImage.value = false;
    }
  }

  Future<void> uploadIdDocument(String type) async {
    try {
      isUploadingDocument.value = true;
      errorMessage.value = '';
      
      print('📸 Starting ID document picker...');
      print('Document type: $type');
      
      // Show dialog to choose source
      final ImageSource? source = await Get.dialog<ImageSource>(
        AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Get.back(result: ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Get.back(result: ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source == null) {
        print('❌ No source selected');
        isUploadingDocument.value = false;
        return;
      }

      print('📸 Picking ID document image from: ${source == ImageSource.gallery ? "Gallery" : "Camera"}');
      
      // Pick image from gallery or camera
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      ).catchError((dynamic error) {
        print('❌ Error picking image: $error');
        throw error;
      });

      if (image == null) {
        print('❌ No image selected');
        isUploadingDocument.value = false;
        return;
      }

      print('✅ Image selected: ${image.path}');
      print('📤 Starting ID document upload...');

      // Upload the document
      final User updatedUser = await uploadIdDocumentUseCase(image.path, type);
      
      print('✅ Upload successful!');
      print('📝 Updated user from API: ${updatedUser.name}');
      
      // Update profile
      profile.value = updatedUser;

      // Update auth session
      final AuthController authController = Get.find<AuthController>();
      if (authController.session.value != null) {
        authController.session.value = AuthSession(
          token: authController.session.value!.token,
          user: updatedUser,
        );
      }

      Get.snackbar(
        'Success',
        'ID document uploaded successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } on PlatformException catch (e) {
      print('❌ PlatformException uploading ID document:');
      print('Error code: ${e.code}');
      print('Error message: ${e.message}');
      print('Error details: ${e.details}');
      
      String errorMsg = 'Failed to access image picker';
      if (e.code == 'photo_access_denied' || e.code == 'camera_access_denied') {
        errorMsg = 'Please grant permission to access photos/camera in settings';
      } else if (e.code == 'channel-error') {
        errorMsg = 'Image picker error. Please try again or restart the app.';
      } else {
        errorMsg = e.message ?? 'Unknown error occurred';
      }
      
      errorMessage.value = errorMsg;
      
      Get.snackbar(
        'Error',
        errorMsg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } catch (e, stackTrace) {
      print('❌ ERROR uploading ID document:');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: $stackTrace');
      
      String errorMsg = e.toString();
      if (e.toString().contains('Exception:')) {
        errorMsg = e.toString().replaceAll('Exception: ', '');
      }
      
      errorMessage.value = errorMsg;
      
      Get.snackbar(
        'Error',
        'Failed to upload document: $errorMsg',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isUploadingDocument.value = false;
    }
  }

  Future<void> uploadResidentialId(String type) async {
    try {
      isUploadingDocument.value = true;
      errorMessage.value = '';
      
      print('📸 Starting residential ID picker...');
      print('Document type: $type');
      
      // Show dialog to choose source
      final ImageSource? source = await Get.dialog<ImageSource>(
        AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Get.back(result: ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Get.back(result: ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source == null) {
        print('❌ No source selected');
        isUploadingDocument.value = false;
        return;
      }

      print('📸 Picking residential ID image from: ${source == ImageSource.gallery ? "Gallery" : "Camera"}');
      
      // Pick image from gallery or camera
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      ).catchError((dynamic error) {
        print('❌ Error picking image: $error');
        throw error;
      });

      if (image == null) {
        print('❌ No image selected');
        isUploadingDocument.value = false;
        return;
      }

      print('✅ Image selected: ${image.path}');
      print('📤 Starting residential ID upload...');

      // Upload the document
      final User updatedUser = await uploadResidentialIdUseCase.call(image.path, type);
      
      print('✅ Upload successful!');
      print('📝 Updated user from API: ${updatedUser.name}');
      
      // Update profile
      profile.value = updatedUser;

      // Update auth session
      final AuthController authController = Get.find<AuthController>();
      if (authController.session.value != null) {
        authController.session.value = AuthSession(
          token: authController.session.value!.token,
          user: updatedUser,
        );
      }

      Get.snackbar(
        'Success',
        'Residential ID uploaded successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } on PlatformException catch (e) {
      print('❌ PlatformException uploading residential ID:');
      print('Error code: ${e.code}');
      print('Error message: ${e.message}');
      print('Error details: ${e.details}');
      
      String errorMsg = 'Failed to access image picker';
      if (e.code == 'photo_access_denied' || e.code == 'camera_access_denied') {
        errorMsg = 'Please grant permission to access photos/camera in settings';
      } else if (e.code == 'channel-error') {
        errorMsg = 'Image picker error. Please try again or restart the app.';
      } else {
        errorMsg = e.message ?? 'Unknown error occurred';
      }
      
      errorMessage.value = errorMsg;
      
      Get.snackbar(
        'Error',
        errorMsg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } catch (e, stackTrace) {
      print('❌ ERROR uploading residential ID:');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: $stackTrace');
      
      String errorMsg = e.toString();
      if (e.toString().contains('Exception:')) {
        errorMsg = e.toString().replaceAll('Exception: ', '');
      }
      
      errorMessage.value = errorMsg;
      
      Get.snackbar(
        'Error',
        'Failed to upload document: $errorMsg',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isUploadingDocument.value = false;
    }
  }
}
