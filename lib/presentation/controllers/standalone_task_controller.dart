import 'package:get/get.dart';

import '../../domain/entities/standalone_task.dart';
import '../../domain/usecases/approve_standalone_task_usecase.dart';
import '../../domain/usecases/create_standalone_task_usecase.dart';
import '../../domain/usecases/get_all_standalone_tasks_usecase.dart';
import '../../domain/usecases/get_my_standalone_tasks_usecase.dart';
import 'auth_controller.dart';

class StandaloneTaskController extends GetxController {
  StandaloneTaskController({
    required CreateStandaloneTaskUseCase createTaskUseCase,
    required GetMyStandaloneTasksUseCase getMyTasksUseCase,
    required GetAllStandaloneTasksUseCase getAllTasksUseCase,
    required ApproveStandaloneTaskUseCase approveTaskUseCase,
  })  : _createTaskUseCase = createTaskUseCase,
        _getMyTasksUseCase = getMyTasksUseCase,
        _getAllTasksUseCase = getAllTasksUseCase,
        _approveTaskUseCase = approveTaskUseCase;

  final CreateStandaloneTaskUseCase _createTaskUseCase;
  final GetMyStandaloneTasksUseCase _getMyTasksUseCase;
  final GetAllStandaloneTasksUseCase _getAllTasksUseCase;
  final ApproveStandaloneTaskUseCase _approveTaskUseCase;

  final RxList<StandaloneTask> myTasks = <StandaloneTask>[].obs;
  final RxList<StandaloneTask> allTasks = <StandaloneTask>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isCreating = false.obs;
  final RxBool isApproving = false.obs;
  String? selectedStatusFilter;

  @override
  void onInit() {
    super.onInit();
    // Only load tasks if user is authenticated
    final AuthController authController = Get.find<AuthController>();
    if (authController.isAuthenticated) {
      loadMyTasks();
    }
  }

  Future<void> loadMyTasks() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final List<StandaloneTask> result = await _getMyTasksUseCase();
      myTasks.value = result;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadAllTasks({String? status}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      selectedStatusFilter = status;
      final List<StandaloneTask> result = await _getAllTasksUseCase(status: status);
      allTasks.value = result;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createTask({
    required String title,
    required String date,
    required double reportedHours,
    required String description,
  }) async {
    try {
      isCreating.value = true;
      errorMessage.value = '';
      await _createTaskUseCase(
        title: title,
        date: date,
        reportedHours: reportedHours,
        description: description,
      );
      // Refresh tasks list to get the latest data from server
      await loadMyTasks();
      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isCreating.value = false;
    }
  }

  Future<bool> approveTask({
    required int taskId,
    required String status,
    double? approvedHours,
  }) async {
    try {
      isApproving.value = true;
      errorMessage.value = '';
      final StandaloneTask task = await _approveTaskUseCase(
        taskId: taskId,
        status: status,
        approvedHours: approvedHours,
      );
      final int index = allTasks.indexWhere((StandaloneTask t) => t.id == taskId);
      if (index != -1) {
        allTasks[index] = task;
      }
      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isApproving.value = false;
    }
  }
}

