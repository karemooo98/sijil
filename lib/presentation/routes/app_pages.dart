import 'package:get/get.dart';

import '../../core/constants/app_routes.dart';
import '../views/attendance/attendance_page.dart';
import '../views/auth/login_page.dart';
import '../views/auth/register_page.dart';
import '../views/auth/splash_page.dart';
import '../views/dashboard/dashboard_page.dart';
import '../views/requests/requests_page.dart';
import '../views/daily_reports/daily_reports_page.dart';
import '../views/notifications/notifications_page.dart';
import '../views/overtime/overtime_page.dart';
import '../views/reports/reports_page.dart';
import '../views/standalone_tasks/standalone_tasks_page.dart';
import '../views/users/users_page.dart';
import '../views/shifts/shift_detail_page.dart';
import '../views/shifts/shifts_page.dart';
import '../views/teams/team_detail_page.dart';
import '../views/teams/teams_page.dart';
import '../views/profile/profile_page.dart';
import '../views/profile/edit_profile_page.dart';
import '../controllers/profile_controller.dart';
import '../views/attendance_management/attendance_management_page.dart';
import '../views/onboarding/onboarding_page.dart';

class AppPages {
  AppPages._();

  static final List<GetPage<dynamic>> pages = <GetPage<dynamic>>[
    GetPage<SplashPage>(name: AppRoutes.splash, page: () => const SplashPage()),
    GetPage<OnboardingPage>(
      name: AppRoutes.onboarding,
      page: () => const OnboardingPage(),
    ),
    GetPage<LoginPage>(name: AppRoutes.login, page: () => LoginPage()),
    GetPage<RegisterPage>(
      name: AppRoutes.register,
      page: () => const RegisterPage(),
    ),
    GetPage<DashboardPage>(
      name: AppRoutes.dashboard,
      page: () => const DashboardPage(),
    ),
    GetPage<AttendancePage>(
      name: AppRoutes.attendance,
      page: () => const AttendancePage(),
    ),
    GetPage<RequestsPage>(
      name: AppRoutes.requests,
      page: () => const RequestsPage(),
    ),
    GetPage<TeamsPage>(name: AppRoutes.teams, page: () => const TeamsPage()),
    GetPage<TeamDetailPage>(
      name: AppRoutes.teamDetail,
      page: () => const TeamDetailPage(),
    ),
    GetPage<ShiftsPage>(name: AppRoutes.shifts, page: () => const ShiftsPage()),
    GetPage<ShiftDetailPage>(
      name: AppRoutes.shiftDetail,
      page: () => const ShiftDetailPage(),
    ),
    GetPage<OvertimePage>(
      name: AppRoutes.overtime,
      page: () => const OvertimePage(),
    ),
    GetPage<DailyReportsPage>(
      name: AppRoutes.dailyReports,
      page: () => const DailyReportsPage(),
    ),
    GetPage<NotificationsPage>(
      name: AppRoutes.notifications,
      page: () => const NotificationsPage(),
    ),
    GetPage<ReportsPage>(
      name: AppRoutes.reports,
      page: () => const ReportsPage(),
    ),
    GetPage<UsersPage>(name: AppRoutes.users, page: () => const UsersPage()),
    GetPage<StandaloneTasksPage>(
      name: AppRoutes.standaloneTasks,
      page: () => const StandaloneTasksPage(),
    ),
    GetPage<ProfilePage>(
      name: AppRoutes.profile,
      page: () => const ProfilePage(),
    ),
    GetPage<EditProfilePage>(
      name: AppRoutes.editProfile,
      page: () {
        final ProfileController controller = Get.find<ProfileController>();
        final user = controller.profile.value;
        if (user == null) {
          Get.back();
          return const ProfilePage();
        }
        return EditProfilePage(user: user);
      },
    ),
    GetPage<AttendanceManagementPage>(
      name: AppRoutes.attendanceManagement,
      page: () => const AttendanceManagementPage(),
    ),
  ];
}
