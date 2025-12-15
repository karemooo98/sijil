import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../../data/datasources/remote_api_service.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/request_repository_impl.dart';
import '../../data/repositories/daily_report_repository_impl.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../data/repositories/overtime_repository_impl.dart';
import '../../data/repositories/report_repository_impl.dart';
import '../../data/repositories/shift_repository_impl.dart';
import '../../data/repositories/standalone_task_repository_impl.dart';
import '../../data/repositories/team_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/daily_report_repository.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/repositories/overtime_repository.dart';
import '../../domain/repositories/report_repository.dart';
import '../../domain/repositories/request_repository.dart';
import '../../domain/repositories/shift_repository.dart';
import '../../domain/repositories/standalone_task_repository.dart';
import '../../domain/repositories/team_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/usecases/approve_request_usecase.dart';
import '../../domain/usecases/approve_standalone_task_usecase.dart';
import '../../domain/usecases/create_request_usecase.dart';
import '../../domain/usecases/create_standalone_task_usecase.dart';
import '../../domain/usecases/create_user_usecase.dart';
import '../../domain/usecases/delete_daily_report_usecase.dart';
import '../../domain/usecases/delete_user_usecase.dart';
import '../../domain/usecases/fetch_profile_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/usecases/upload_profile_picture_usecase.dart';
import '../../domain/usecases/upload_id_document_usecase.dart';
import '../../domain/usecases/upload_residential_id_usecase.dart';
import '../../domain/usecases/get_all_requests_usecase.dart';
import '../../domain/usecases/get_all_standalone_tasks_usecase.dart';
import '../../domain/usecases/get_all_users_usecase.dart';
import '../../domain/usecases/get_all_users_summary_usecase.dart';
import '../../domain/usecases/get_attendance_by_date_usecase.dart';
import '../../domain/usecases/get_attendance_summary_usecase.dart';
import '../../domain/usecases/get_my_attendance_usecase.dart';
import '../../domain/usecases/get_my_attendance_history_usecase.dart';
import '../../domain/usecases/update_attendance_usecase.dart';
import '../../domain/usecases/get_my_requests_usecase.dart';
import '../../domain/usecases/get_my_shift_usecase.dart';
import '../../domain/usecases/get_my_standalone_tasks_usecase.dart';
import '../../domain/usecases/get_my_summary_usecase.dart';
import '../../domain/usecases/get_my_full_summary_usecase.dart';
import '../../domain/usecases/get_online_status_usecase.dart';
import '../../domain/usecases/online_check_in_usecase.dart';
import '../../domain/usecases/online_check_out_usecase.dart';
import '../../domain/usecases/get_request_by_id_usecase.dart';
import '../../domain/usecases/get_user_by_id_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/update_user_usecase.dart';
import '../../domain/usecases/add_team_member_usecase.dart';
import '../../domain/usecases/assign_users_to_shift_usecase.dart';
import '../../domain/usecases/create_daily_report_usecase.dart';
import '../../domain/usecases/create_shift_usecase.dart';
import '../../domain/usecases/create_team_task_usecase.dart';
import '../../domain/usecases/create_team_usecase.dart';
import '../../domain/usecases/delete_shift_usecase.dart';
import '../../domain/usecases/delete_team_usecase.dart';
import '../../domain/usecases/get_all_daily_reports_usecase.dart';
import '../../domain/usecases/get_all_overtime_usecase.dart';
import '../../domain/usecases/get_all_shifts_usecase.dart';
import '../../domain/usecases/get_all_users_summary_report_usecase.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/get_user_report_usecase.dart';
import '../../domain/usecases/mark_all_notifications_read_usecase.dart';
import '../../domain/usecases/mark_notification_read_usecase.dart';
import '../../domain/usecases/send_notification_usecase.dart';
import '../../domain/usecases/get_all_teams_usecase.dart';
import '../../domain/usecases/get_my_daily_reports_usecase.dart';
import '../../domain/usecases/get_my_overtime_usecase.dart';
import '../../domain/usecases/get_shift_by_id_usecase.dart';
import '../../domain/usecases/get_team_by_id_usecase.dart';
import '../../domain/usecases/remove_user_from_shift_usecase.dart';
import '../../domain/usecases/update_daily_report_usecase.dart';
import '../../domain/usecases/update_shift_usecase.dart';
import '../../domain/usecases/remove_team_member_usecase.dart';
import '../../domain/usecases/restore_session_usecase.dart';
import '../../domain/usecases/update_task_status_usecase.dart';
import '../controllers/attendance_controller.dart';
import '../controllers/auth_controller.dart';
import '../../core/storage/app_preferences.dart';
import '../controllers/request_controller.dart';
import '../controllers/self_attendance_controller.dart';
import '../controllers/daily_report_controller.dart';
import '../controllers/notification_controller.dart';
import '../controllers/overtime_controller.dart';
import '../controllers/report_controller.dart';
import '../controllers/shift_controller.dart';
import '../controllers/standalone_task_controller.dart';
import '../controllers/team_controller.dart';
import '../controllers/user_controller.dart';
import '../controllers/profile_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<TokenStorage>(
      TokenStorage(const FlutterSecureStorage()),
      permanent: true,
    );
    Get.put<ApiClient>(ApiClient(Get.find<TokenStorage>()), permanent: true);
    Get.put<RemoteApiService>(
      RemoteApiService(Get.find<ApiClient>()),
      permanent: true,
    );

    Get.put<AuthRepository>(
      AuthRepositoryImpl(
        Get.find<RemoteApiService>(),
        Get.find<TokenStorage>(),
      ),
      permanent: true,
    );
    Get.put<AttendanceRepository>(
      AttendanceRepositoryImpl(Get.find<RemoteApiService>()),
      permanent: true,
    );
    Get.put<RequestRepository>(
      RequestRepositoryImpl(Get.find<RemoteApiService>()),
      permanent: true,
    );
    Get.put<TeamRepository>(
      TeamRepositoryImpl(Get.find<RemoteApiService>()),
      permanent: true,
    );
    Get.put<ShiftRepository>(
      ShiftRepositoryImpl(Get.find<RemoteApiService>()),
      permanent: true,
    );
    Get.put<OvertimeRepository>(
      OvertimeRepositoryImpl(Get.find<RemoteApiService>()),
      permanent: true,
    );
    Get.put<DailyReportRepository>(
      DailyReportRepositoryImpl(Get.find<RemoteApiService>()),
      permanent: true,
    );
    Get.put<NotificationRepository>(
      NotificationRepositoryImpl(Get.find<RemoteApiService>()),
      permanent: true,
    );
    Get.put<ReportRepository>(
      ReportRepositoryImpl(Get.find<RemoteApiService>()),
      permanent: true,
    );
    Get.put<UserRepository>(
      UserRepositoryImpl(Get.find<RemoteApiService>()),
      permanent: true,
    );
    Get.put<StandaloneTaskRepository>(
      StandaloneTaskRepositoryImpl(Get.find<RemoteApiService>()),
      permanent: true,
    );

    Get.put(LoginUseCase(Get.find<AuthRepository>()), permanent: true);
    Get.put(RegisterUseCase(Get.find<AuthRepository>()), permanent: true);
    Get.put(LogoutUseCase(Get.find<AuthRepository>()), permanent: true);
    Get.put(FetchProfileUseCase(Get.find<AuthRepository>()), permanent: true);
    Get.put(UpdateProfileUseCase(Get.find<AuthRepository>()), permanent: true);
    Get.put(UploadProfilePictureUseCase(Get.find<AuthRepository>()), permanent: true);
    Get.put(UploadIdDocumentUseCase(Get.find<AuthRepository>()), permanent: true);
    Get.put(UploadResidentialIdUseCase(Get.find<AuthRepository>()), permanent: true);
    Get.put(RestoreSessionUseCase(Get.find<AuthRepository>()), permanent: true);
    Get.put(
      GetAttendanceByDateUseCase(Get.find<AttendanceRepository>()),
      permanent: true,
    );
    Get.put(
      GetAttendanceSummaryUseCase(Get.find<AttendanceRepository>()),
      permanent: true,
    );
    Get.put(
      GetMyAttendanceUseCase(Get.find<AttendanceRepository>()),
      permanent: true,
    );
    Get.put(
      GetAllUsersSummaryUseCase(Get.find<AttendanceRepository>()),
      permanent: true,
    );
    Get.put(
      UpdateAttendanceUseCase(Get.find<AttendanceRepository>()),
      permanent: true,
    );
    Get.put(
      GetOnlineStatusUseCase(Get.find<AttendanceRepository>()),
      permanent: true,
    );
    Get.put(
      OnlineCheckInUseCase(Get.find<AttendanceRepository>()),
      permanent: true,
    );
    Get.put(
      OnlineCheckOutUseCase(Get.find<AttendanceRepository>()),
      permanent: true,
    );
    Get.put(
      GetMySummaryUseCase(Get.find<AttendanceRepository>()),
      permanent: true,
    );
    Get.put(
      GetMyFullSummaryUseCase(Get.find<AttendanceRepository>()),
      permanent: true,
    );
    Get.put(
      GetMyFullSummaryUseCase(Get.find<AttendanceRepository>()),
      permanent: true,
    );
    Get.put(
      GetMyAttendanceHistoryUseCase(Get.find<AttendanceRepository>()),
      permanent: true,
    );
    Get.put(
      GetMyRequestsUseCase(Get.find<RequestRepository>()),
      permanent: true,
    );
    Get.put(
      GetAllRequestsUseCase(Get.find<RequestRepository>()),
      permanent: true,
    );
    Get.put(
      CreateRequestUseCase(Get.find<RequestRepository>()),
      permanent: true,
    );
    Get.put(
      ApproveRequestUseCase(Get.find<RequestRepository>()),
      permanent: true,
    );
    Get.put(GetAllTeamsUseCase(Get.find<TeamRepository>()), permanent: true);
    Get.put(GetTeamByIdUseCase(Get.find<TeamRepository>()), permanent: true);
    Get.put(CreateTeamUseCase(Get.find<TeamRepository>()), permanent: true);
    Get.put(DeleteTeamUseCase(Get.find<TeamRepository>()), permanent: true);
    Get.put(AddTeamMemberUseCase(Get.find<TeamRepository>()), permanent: true);
    Get.put(
      RemoveTeamMemberUseCase(Get.find<TeamRepository>()),
      permanent: true,
    );
    Get.put(CreateTeamTaskUseCase(Get.find<TeamRepository>()), permanent: true);
    Get.put(
      UpdateTaskStatusUseCase(Get.find<TeamRepository>()),
      permanent: true,
    );
    Get.put(GetAllShiftsUseCase(Get.find<ShiftRepository>()), permanent: true);
    Get.put(GetShiftByIdUseCase(Get.find<ShiftRepository>()), permanent: true);
    Get.put(CreateShiftUseCase(Get.find<ShiftRepository>()), permanent: true);
    Get.put(UpdateShiftUseCase(Get.find<ShiftRepository>()), permanent: true);
    Get.put(DeleteShiftUseCase(Get.find<ShiftRepository>()), permanent: true);
    Get.put(
      AssignUsersToShiftUseCase(Get.find<ShiftRepository>()),
      permanent: true,
    );
    Get.put(
      RemoveUserFromShiftUseCase(Get.find<ShiftRepository>()),
      permanent: true,
    );
    Get.put(
      GetMyOvertimeUseCase(Get.find<OvertimeRepository>()),
      permanent: true,
    );
    Get.put(
      GetAllOvertimeUseCase(Get.find<OvertimeRepository>()),
      permanent: true,
    );
    Get.put(
      GetMyDailyReportsUseCase(Get.find<DailyReportRepository>()),
      permanent: true,
    );
    Get.put(
      GetAllDailyReportsUseCase(Get.find<DailyReportRepository>()),
      permanent: true,
    );
    Get.put(
      CreateDailyReportUseCase(Get.find<DailyReportRepository>()),
      permanent: true,
    );
    Get.put(
      UpdateDailyReportUseCase(Get.find<DailyReportRepository>()),
      permanent: true,
    );
    Get.put(
      GetNotificationsUseCase(Get.find<NotificationRepository>()),
      permanent: true,
    );
    Get.put(
      MarkNotificationReadUseCase(Get.find<NotificationRepository>()),
      permanent: true,
    );
    Get.put(
      MarkAllNotificationsReadUseCase(Get.find<NotificationRepository>()),
      permanent: true,
    );
    Get.put(
      SendNotificationUseCase(Get.find<NotificationRepository>()),
      permanent: true,
    );
    Get.put(
      GetAllUsersSummaryReportUseCase(Get.find<ReportRepository>()),
      permanent: true,
    );
    Get.put(
      GetUserReportUseCase(Get.find<ReportRepository>()),
      permanent: true,
    );
    Get.put(GetAllUsersUseCase(Get.find<UserRepository>()), permanent: true);
    Get.put(GetUserByIdUseCase(Get.find<UserRepository>()), permanent: true);
    Get.put(CreateUserUseCase(Get.find<UserRepository>()), permanent: true);
    Get.put(UpdateUserUseCase(Get.find<UserRepository>()), permanent: true);
    Get.put(DeleteUserUseCase(Get.find<UserRepository>()), permanent: true);
    Get.put(
      DeleteDailyReportUseCase(Get.find<DailyReportRepository>()),
      permanent: true,
    );
    Get.put(
      GetRequestByIdUseCase(Get.find<RequestRepository>()),
      permanent: true,
    );
    Get.put(
      CreateStandaloneTaskUseCase(Get.find<StandaloneTaskRepository>()),
      permanent: true,
    );
    Get.put(
      GetMyStandaloneTasksUseCase(Get.find<StandaloneTaskRepository>()),
      permanent: true,
    );
    Get.put(
      GetAllStandaloneTasksUseCase(Get.find<StandaloneTaskRepository>()),
      permanent: true,
    );
    Get.put(
      ApproveStandaloneTaskUseCase(Get.find<StandaloneTaskRepository>()),
      permanent: true,
    );
    Get.put(GetMyShiftUseCase(Get.find<ShiftRepository>()), permanent: true);

    Get.put(
      AuthController(
        loginUseCase: Get.find(),
        registerUseCase: Get.find<RegisterUseCase>(),
        logoutUseCase: Get.find(),
        fetchProfileUseCase: Get.find(),
        restoreSessionUseCase: Get.find(),
        appPreferences: Get.find<AppPreferences>(),
      ),
      permanent: true,
    );
    Get.put(
      AttendanceController(
        getAttendanceByDateUseCase: Get.find(),
        getAttendanceSummaryUseCase: Get.find(),
        getMyAttendanceUseCase: Get.find(),
        getAllUsersSummaryUseCase: Get.find(),
        updateAttendanceUseCase: Get.find(),
      ),
      permanent: true,
    );
    Get.put(
      SelfAttendanceController(
        getOnlineStatusUseCase: Get.find(),
        getMySummaryUseCase: Get.find(),
        getMyFullSummaryUseCase: Get.find(),
        getMyAttendanceHistoryUseCase: Get.find(),
        onlineCheckInUseCase: Get.find(),
        onlineCheckOutUseCase: Get.find(),
      ),
      permanent: true,
    );
    Get.put(
      RequestController(
        getMyRequestsUseCase: Get.find(),
        getAllRequestsUseCase: Get.find(),
        createRequestUseCase: Get.find(),
        approveRequestUseCase: Get.find(),
        getRequestByIdUseCase: Get.find(),
      ),
      permanent: true,
    );
    Get.put(
      TeamController(
        getAllTeamsUseCase: Get.find(),
        getTeamByIdUseCase: Get.find(),
        createTeamUseCase: Get.find(),
        deleteTeamUseCase: Get.find(),
        addTeamMemberUseCase: Get.find(),
        removeTeamMemberUseCase: Get.find(),
        createTeamTaskUseCase: Get.find(),
        updateTaskStatusUseCase: Get.find(),
      ),
      permanent: true,
    );
    Get.put(
      ShiftController(
        getAllShiftsUseCase: Get.find(),
        getShiftByIdUseCase: Get.find(),
        getMyShiftUseCase: Get.find(),
        createShiftUseCase: Get.find(),
        updateShiftUseCase: Get.find(),
        deleteShiftUseCase: Get.find(),
        assignUsersToShiftUseCase: Get.find(),
        removeUserFromShiftUseCase: Get.find(),
      ),
      permanent: true,
    );
    Get.put(
      OvertimeController(
        getMyOvertimeUseCase: Get.find(),
        getAllOvertimeUseCase: Get.find(),
      ),
      permanent: true,
    );
    Get.put(
      DailyReportController(
        getMyDailyReportsUseCase: Get.find(),
        getAllDailyReportsUseCase: Get.find(),
        createDailyReportUseCase: Get.find(),
        updateDailyReportUseCase: Get.find(),
        deleteDailyReportUseCase: Get.find(),
      ),
      permanent: true,
    );
    Get.put(
      ReportController(
        getAllUsersSummaryReportUseCase: Get.find(),
        getUserReportUseCase: Get.find(),
      ),
      permanent: true,
    );
    Get.put(
      UserController(
        getAllUsersUseCase: Get.find(),
        getUserByIdUseCase: Get.find(),
        createUserUseCase: Get.find(),
        updateUserUseCase: Get.find(),
        deleteUserUseCase: Get.find(),
      ),
      permanent: true,
    );
    Get.put(
      StandaloneTaskController(
        createTaskUseCase: Get.find(),
        getMyTasksUseCase: Get.find(),
        getAllTasksUseCase: Get.find(),
        approveTaskUseCase: Get.find(),
      ),
      permanent: true,
    );
    Get.put(
      ProfileController(
        fetchProfileUseCase: Get.find(),
        updateProfileUseCase: Get.find(),
        uploadProfilePictureUseCase: Get.find(),
        uploadIdDocumentUseCase: Get.find(),
        uploadResidentialIdUseCase: Get.find(),
      ),
      permanent: true,
    );
    Get.put(
      NotificationController(
        getNotificationsUseCase: Get.find(),
        markNotificationReadUseCase: Get.find(),
        markAllNotificationsReadUseCase: Get.find(),
        sendNotificationUseCase: Get.find(),
      ),
      permanent: true,
    );
  }
}
