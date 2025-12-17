import 'package:get/get.dart';

import '../../domain/entities/overtime_record.dart';
import '../../domain/usecases/get_all_overtime_usecase.dart';
import '../../domain/usecases/get_my_overtime_usecase.dart';
import 'auth_controller.dart';

class OvertimeController extends GetxController {
  OvertimeController({
    required GetMyOvertimeUseCase getMyOvertimeUseCase,
    required GetAllOvertimeUseCase getAllOvertimeUseCase,
  })  : _getMyOvertimeUseCase = getMyOvertimeUseCase,
        _getAllOvertimeUseCase = getAllOvertimeUseCase;

  final GetMyOvertimeUseCase _getMyOvertimeUseCase;
  final GetAllOvertimeUseCase _getAllOvertimeUseCase;

  final RxList<OvertimeRecord> myOvertime = <OvertimeRecord>[].obs;
  final RxList<OvertimeRecord> allOvertime = <OvertimeRecord>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Only load overtime if user is authenticated
    final AuthController authController = Get.find<AuthController>();
    if (authController.isAuthenticated) {
      loadMyOvertime();
    }
  }

  Future<void> loadMyOvertime() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final List<OvertimeRecord> result = await _getMyOvertimeUseCase();
      myOvertime.value = result;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadAllOvertime() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final List<OvertimeRecord> result = await _getAllOvertimeUseCase();
      allOvertime.value = result;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }
}

