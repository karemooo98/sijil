import 'package:get/get.dart';

import '../../domain/entities/daily_report.dart';
import '../../domain/usecases/create_daily_report_usecase.dart';
import '../../domain/usecases/delete_daily_report_usecase.dart';
import '../../domain/usecases/get_all_daily_reports_usecase.dart';
import '../../domain/usecases/get_my_daily_reports_usecase.dart';
import '../../domain/usecases/update_daily_report_usecase.dart';
import 'auth_controller.dart';

class DailyReportController extends GetxController {
  DailyReportController({
    required GetMyDailyReportsUseCase getMyDailyReportsUseCase,
    required GetAllDailyReportsUseCase getAllDailyReportsUseCase,
    required CreateDailyReportUseCase createDailyReportUseCase,
    required UpdateDailyReportUseCase updateDailyReportUseCase,
    required DeleteDailyReportUseCase deleteDailyReportUseCase,
  })  : _getMyDailyReportsUseCase = getMyDailyReportsUseCase,
        _getAllDailyReportsUseCase = getAllDailyReportsUseCase,
        _createDailyReportUseCase = createDailyReportUseCase,
        _updateDailyReportUseCase = updateDailyReportUseCase,
        _deleteDailyReportUseCase = deleteDailyReportUseCase;

  final GetMyDailyReportsUseCase _getMyDailyReportsUseCase;
  final GetAllDailyReportsUseCase _getAllDailyReportsUseCase;
  final CreateDailyReportUseCase _createDailyReportUseCase;
  final UpdateDailyReportUseCase _updateDailyReportUseCase;
  final DeleteDailyReportUseCase _deleteDailyReportUseCase;

  final RxList<DailyReport> myReports = <DailyReport>[].obs;
  final RxList<DailyReport> allReports = <DailyReport>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isCreating = false.obs;
  final RxBool isUpdating = false.obs;
  final RxBool isDeleting = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Only load reports if user is authenticated
    final AuthController authController = Get.find<AuthController>();
    if (authController.isAuthenticated) {
      loadMyReports();
    }
  }

  Future<void> loadMyReports({String? date}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final List<DailyReport> result = await _getMyDailyReportsUseCase(date: date);
      myReports.value = result;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadAllReports({
    int? userId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final List<DailyReport> result = await _getAllDailyReportsUseCase(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );
      allReports.value = result;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createReport({
    required String date,
    required String description,
    required double hoursWorked,
    String? achievements,
    String? challenges,
    String? notes,
  }) async {
    try {
      isCreating.value = true;
      // Don't set errorMessage here - we'll show it in a snackbar instead
      await _createDailyReportUseCase(
        date: date,
        description: description,
        hoursWorked: hoursWorked,
        achievements: achievements,
        challenges: challenges,
        notes: notes,
      );
      // Refresh reports list to get the latest data from server
      await loadMyReports();
      return true;
    } catch (e) {
      // Re-throw the error so the UI can catch it and show in snackbar
      // Don't set errorMessage to avoid replacing the reports list
      rethrow;
    } finally {
      isCreating.value = false;
    }
  }

  Future<bool> updateReport({
    required int reportId,
    String? description,
    double? hoursWorked,
    String? achievements,
    String? challenges,
    String? notes,
  }) async {
    try {
      isUpdating.value = true;
      errorMessage.value = '';
      final DailyReport report = await _updateDailyReportUseCase(
        reportId: reportId,
        description: description,
        hoursWorked: hoursWorked,
        achievements: achievements,
        challenges: challenges,
        notes: notes,
      );
      final int index = myReports.indexWhere((DailyReport r) => r.id == reportId);
      if (index != -1) {
        myReports[index] = report;
      }
      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  Future<bool> deleteReport(int reportId) async {
    try {
      isDeleting.value = true;
      errorMessage.value = '';
      await _deleteDailyReportUseCase(reportId);
      myReports.removeWhere((DailyReport r) => r.id == reportId);
      allReports.removeWhere((DailyReport r) => r.id == reportId);
      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isDeleting.value = false;
    }
  }
}

