import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/attendance_record.dart';
import '../../../domain/entities/attendance_summary.dart';
import '../../../domain/entities/shift.dart';
import '../../../domain/entities/user_request.dart';
import '../../controllers/attendance_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/daily_report_controller.dart';
import '../../controllers/request_controller.dart';
import '../../controllers/self_attendance_controller.dart';
import '../../controllers/shift_controller.dart';
import '../../widgets/employee_card.dart';

enum DashboardTab { present, onLeave }

enum StatFilter { none, present, absent, missingCheckout, leftEarly }

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final AuthController authController;
  late final AttendanceController attendanceController;
  late final RequestController requestController;
  late final SelfAttendanceController selfAttendanceController;
  late final ShiftController shiftController;

  DashboardTab _activeTab = DashboardTab.present;
  StatFilter _selectedStatFilter = StatFilter.none;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  Set<int> _usersOnLeave = <int>{};
  DateTime? _cachedLeaveDate;
  bool _isSearchExpanded = false;
  bool _viewAsEmployee = false; // Toggle for admin to view as employee

  @override
  void initState() {
    super.initState();
    authController = Get.find<AuthController>();
    attendanceController = Get.find<AttendanceController>();
    requestController = Get.find<RequestController>();
    selfAttendanceController = Get.find<SelfAttendanceController>();
    shiftController = Get.find<ShiftController>();
    _searchController.addListener(() {
      setState(() {}); // Trigger rebuild when search text changes
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
      final user = authController.session.value?.user;
      final bool isAdmin = user?.isAdmin ?? false;

      // Default: show admin view for admins, employee view for employees
      if (isAdmin && selfAttendanceController.isEmployee) {
        // Admin who can also be employee - default to admin view
        _viewAsEmployee = false;
        _loadUsersOnLeave();
        // Also load reports in case admin switches to employee view
        final DailyReportController reportController = Get.find<DailyReportController>();
        reportController.loadMyReports();
      } else if (selfAttendanceController.isEmployee) {
        // Regular employee
        selfAttendanceController.refreshAll();
        shiftController.loadMyShift();
        // Load daily reports for checkout check
        final DailyReportController reportController = Get.find<DailyReportController>();
        reportController.loadMyReports();
      } else if (isAdmin) {
        // Admin only (not employee)
        _loadUsersOnLeave();
      }
    });
  }

  Future<void> _loadUsersOnLeave() async {
    final DateTime selectedDate = attendanceController.selectedDate.value;
    if (_cachedLeaveDate != null &&
        _cachedLeaveDate!.isAtSameMomentAs(selectedDate)) {
      return; // Already cached for this date
    }

    _cachedLeaveDate = selectedDate;
    _usersOnLeave = await _getUsersOnLeaveForDate(selectedDate);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await attendanceController.refreshForDate(DateTime.now());
    await attendanceController.loadMyRecentAttendance();
    await requestController.loadMyRequests();
    await requestController.loadPendingApprovals();
    final user = authController.session.value?.user;
    final bool isAdmin = user?.isAdmin ?? false;
    // Only load admin data if viewing as admin (not as employee)
    if (isAdmin && !_viewAsEmployee) {
      await _loadUsersOnLeave();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: _buildDrawer(context),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _bootstrap();
            final user = authController.session.value?.user;
            final bool isAdmin = user?.isAdmin ?? false;

            if (_viewAsEmployee && selfAttendanceController.isEmployee) {
              await selfAttendanceController.refreshAll();
            } else if (isAdmin) {
              await _loadUsersOnLeave();
            }
          },
          child: Obx(
            () => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: <Widget>[
                _buildTopBar(context),
                const SizedBox(height: 16),
                // Show employee view or admin view based on toggle
                if (_viewAsEmployee &&
                    selfAttendanceController.isEmployee) ...<Widget>[
                  // Employee Dashboard
                  _buildOnlineAttendanceCard(context),
                  const SizedBox(height: 16),
                  _buildMyShiftCard(context),
                  const SizedBox(height: 16),
                  _buildMySummaryCard(context),
                ] else if (authController.session.value?.user.isAdmin ??
                    false) ...<Widget>[
                  // Admin Dashboard
                  _buildDonutCard(context),
                  const SizedBox(height: 16),
                  _buildStatsRow(context),
                  if (_selectedStatFilter != StatFilter.none) ...[
                    const SizedBox(height: 12),
                    _buildFilterIndicator(context),
                  ],
                  const SizedBox(height: 24),
                  _buildTabs(context),
                  const SizedBox(height: 16),
                  _buildAttendanceList(context),
                ] else if (selfAttendanceController.isEmployee) ...<Widget>[
                  // Regular Employee Dashboard
                  _buildOnlineAttendanceCard(context),
                  const SizedBox(height: 16),
                  _buildMyShiftCard(context),
                  const SizedBox(height: 16),
                  _buildMySummaryCard(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final bool showAdminToolbar =
        (authController.session.value?.user.isAdmin ?? false) &&
        !_viewAsEmployee;
    return Row(
      children: <Widget>[
        IconButton(
          icon: const Icon(Symbols.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        const Spacer(),
        if (showAdminToolbar) _buildSearchAndDate(context),
      ],
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            // Header with greeting and name
            Obx(() {
              final user = authController.session.value?.user;
              
              return Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    primaryColor.withOpacity(0.12),
                    primaryColor.withOpacity(0.04),
                  ],
                ),
              ),
              child: Row(
                children: <Widget>[
                    _buildDrawerAvatar(context, user?.photo, primaryColor),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Hello',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.name.split(' ').first ?? 'there',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: primaryColor,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
            }),
            // Menu Items
            Expanded(
              child: Obx(() {
                final user = authController.session.value?.user;
                final bool isAdmin = user?.role == 'admin';
                final bool isManager = user?.role == 'manager';
                final bool isAdminOrManager = isAdmin || isManager;
                
                return ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: <Widget>[
                  _drawerItem(
                    context,
                    icon: Symbols.home,
                    label: 'Dashboard',
                    onTap: _closeDrawer,
                    isActive: true,
                  ),
                  // Toggle for admin to switch between admin and employee view
                  if (isAdmin && selfAttendanceController.isEmployee)
                    SwitchListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                      title: Text(
                        'View as Employee',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        _viewAsEmployee
                            ? 'Employee Dashboard'
                            : 'Admin Dashboard',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                      value: _viewAsEmployee,
                      onChanged: (bool value) {
                        setState(() {
                          _viewAsEmployee = value;
                        });
                        _closeDrawer();
                        if (value) {
                          // Load employee data when switching to employee view
                          selfAttendanceController.refreshAll();
                          shiftController.loadMyShift();
                        } else {
                          // Load admin data when switching to admin view
                          _loadUsersOnLeave();
                        }
                      },
                      activeColor: primaryColor,
                    ),
                  if (isAdminOrManager) ...[
                    _drawerItem(
                      context,
                      icon: Symbols.groups,
                      label: 'Teams',
                      onTap: () {
                        _closeDrawer();
                        Get.toNamed('/teams');
                      },
                    ),
                    _drawerItem(
                      context,
                      icon: Symbols.access_time,
                      label: 'Shifts',
                      onTap: () {
                        _closeDrawer();
                        Get.toNamed('/shifts');
                      },
                    ),
                    _drawerItem(
                      context,
                      icon: Symbols.fact_check,
                      label: 'Attendance',
                      onTap: () {
                        _closeDrawer();
                        Get.toNamed('/attendance-management');
                      },
                    ),
                  ],
                  _drawerItem(
                    context,
                    icon: Symbols.timer,
                    label: 'Overtime',
                    onTap: () {
                      _closeDrawer();
                      Get.toNamed('/overtime');
                    },
                  ),
                  _drawerItem(
                    context,
                    icon: Symbols.description,
                    label: 'Daily Reports',
                    onTap: () {
                      _closeDrawer();
                      Get.toNamed('/daily-reports');
                    },
                  ),
                  _drawerItem(
                    context,
                    icon: Symbols.task_alt,
                    label: 'Tasks',
                    onTap: () {
                      _closeDrawer();
                      Get.toNamed('/standalone-tasks');
                    },
                  ),
                  _drawerItem(
                    context,
                    icon: Symbols.notifications,
                    label: 'Notifications',
                    onTap: () {
                      _closeDrawer();
                      Get.toNamed('/notifications');
                    },
                  ),
                  _drawerItem(
                    context,
                    icon: Symbols.description,
                    label: 'Requests',
                    onTap: () {
                      _closeDrawer();
                      Get.toNamed('/requests');
                    },
                  ),
                  _drawerItem(
                    context,
                    icon: Symbols.person,
                    label: 'Profile',
                    onTap: () {
                      _closeDrawer();
                      Get.toNamed('/profile');
                    },
                  ),
                  if (isAdmin) ...[
                    _drawerItem(
                      context,
                      icon: Symbols.people,
                      label: 'Users',
                      onTap: () {
                        _closeDrawer();
                        Get.toNamed('/users');
                      },
                    ),
                    _drawerItem(
                      context,
                      icon: Symbols.bar_chart,
                      label: 'Reports',
                      onTap: () {
                        _closeDrawer();
                        Get.toNamed('/reports');
                      },
                    ),
                  ],
                  _drawerItem(
                    context,
                    icon: Symbols.logout,
                    label: 'Logout',
                    onTap: () {
                      _closeDrawer();
                      authController.logout();
                    },
                    isLogout: true,
                  ),
                ],
              );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    bool isLogout = false,
  }) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      decoration: BoxDecoration(
        color: isActive ? primaryColor.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          color: isLogout
              ? Colors.red[600]
              : isActive
              ? primaryColor
              : Colors.grey[700],
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isLogout
                ? Colors.red[600]
                : isActive
                ? primaryColor
                : Colors.grey[800],
            fontWeight: isActive || isLogout
                ? FontWeight.w600
                : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        minVerticalPadding: 0,
      ),
    );
  }

  void _closeDrawer() => _scaffoldKey.currentState?.closeDrawer();

  Widget _buildDrawerAvatar(BuildContext context, String? photo, Color primaryColor) {
    if (photo != null && photo.trim().isNotEmpty && photo.trim() != 'null') {
      String imageUrl = photo.trim();
      
      // If photo is a relative URL, prepend base URL
      if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
        if (!imageUrl.startsWith('/')) {
          imageUrl = '/$imageUrl';
        }
        imageUrl = '${AppConfig.baseUrl}$imageUrl';
      }
      
      return ClipOval(
        child: Image.network(
          imageUrl,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
            return CircleAvatar(
              radius: 24,
              backgroundColor: primaryColor.withOpacity(0.15),
              child: Icon(Symbols.person, color: primaryColor, size: 28),
            );
          },
          loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return CircleAvatar(
              radius: 24,
              backgroundColor: primaryColor.withOpacity(0.15),
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            );
          },
        ),
      );
    }
    
    return CircleAvatar(
      radius: 24,
      backgroundColor: primaryColor.withOpacity(0.15),
      child: Icon(Symbols.person, color: primaryColor, size: 28),
    );
  }

  Widget _buildSearchAndDate(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: _isSearchExpanded ? 200 : 40,
          child: _isSearchExpanded
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Symbols.search, size: 18),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          _isSearchExpanded = false;
                          _searchController.clear();
                        });
                      },
                    ),
                    hintText: 'Search',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  style: const TextStyle(fontSize: 14),
                  onSubmitted: (_) {
                    // Keep search field open after submission
                  },
                  onTapOutside: (_) {
                    // Collapse if search is empty when tapping outside
                    if (_searchController.text.trim().isEmpty) {
                      setState(() {
                        _isSearchExpanded = false;
                      });
                    }
                  },
                )
              : IconButton(
                  icon: Icon(Symbols.search, size: 20),
                  onPressed: () {
                    setState(() {
                      _isSearchExpanded = true;
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(Symbols.calendar_today, size: 20),
          onPressed: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: attendanceController.selectedDate.value,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 30)),
            );
            if (picked != null) {
              await attendanceController.refreshForDate(picked);
              // Reload leave requests for the new date
              if (!selfAttendanceController.isEmployee) {
                _cachedLeaveDate = null; // Reset cache
                await _loadUsersOnLeave();
              }
            }
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildDonutCard(BuildContext context) {
    final _DailySummaryMetrics? metrics = _getDailySummaryMetrics();
    if (metrics == null) {
      if (attendanceController.isSummaryLoading.value ||
          attendanceController.isAttendanceLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      return _emptyState('No attendance summary available.');
    }
    final double presentPercent = metrics.totalUsers == 0
        ? 0
        : metrics.present / metrics.totalUsers;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 200,
            width: 200,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                // Background circle with subtle gradient
                Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        Colors.grey.shade100,
                        Colors.grey.shade200,
                      ],
                    ),
                  ),
                ),
                // Progress indicator with gradient
                SizedBox(
                  height: 200,
                  width: 200,
                  child: CustomPaint(
                    painter: _GradientCircularProgressPainter(
                      progress: presentPercent,
                      strokeWidth: 20,
                      backgroundColor: Colors.grey.shade200,
                      gradientColors: const <Color>[
                        AppTheme.primaryDark,
                        AppTheme.primaryColor,
                        AppTheme.primaryLight,
                      ],
                    ),
                  ),
                ),
                // Inner content with white background and subtle shadow
                Container(
                  height: 160,
                  width: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ShaderMask(
                        shaderCallback: (Rect bounds) => const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[
                            AppTheme.primaryDark,
                            AppTheme.primaryColor,
                            AppTheme.primaryLight,
                          ],
                        ).createShader(bounds),
                        child: Text(
                          '${(presentPercent * 100).toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 36,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final _DailySummaryMetrics? metrics = _getDailySummaryMetrics();
    if (metrics == null) {
      if (attendanceController.isSummaryLoading.value ||
          attendanceController.isAttendanceLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      return _emptyState('No attendance summary available.');
    }

    final TextStyle? titleStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);
    final TextStyle? subtitleStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 2.2.h, horizontal: 1.5.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2.2.h),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _buildStatCard(
                  context,
                  value: '${metrics.present}',
                  label: 'Present',
                  filter: StatFilter.present,
                  titleStyle: titleStyle,
                  subtitleStyle: subtitleStyle,
                ),
              ),
              Expanded(
                child: _buildStatCard(
                  context,
                  value: '${metrics.absent}',
                  label: 'Absent',
                  filter: StatFilter.absent,
                  titleStyle: titleStyle,
                  subtitleStyle: subtitleStyle,
                ),
              ),
              Expanded(
                child: _buildStatCard(
                  context,
                  value: '${metrics.missingCheckout}',
                  label: 'Missing',
                  filter: StatFilter.missingCheckout,
                  titleStyle: titleStyle,
                  subtitleStyle: subtitleStyle,
                ),
              ),
              Expanded(
                child: _buildStatCard(
                  context,
                  value: '${metrics.leftEarly}',
                  label: 'Left early',
                  filter: StatFilter.leftEarly,
                  titleStyle: titleStyle,
                  subtitleStyle: subtitleStyle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String value,
    required String label,
    required StatFilter filter,
    required TextStyle? titleStyle,
    required TextStyle? subtitleStyle,
  }) {
    final bool isSelected = _selectedStatFilter == filter;
    final bool isPresent = filter == StatFilter.present;
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final TextStyle baseTitleStyle =
        titleStyle ??
        Theme.of(context).textTheme.titleMedium ??
        const TextStyle();
    final TextStyle baseSubtitleStyle =
        subtitleStyle ??
        Theme.of(context).textTheme.bodySmall ??
        const TextStyle();
    // Increase font size for admin summary numbers
    final double titleFontSize = (baseTitleStyle.fontSize ?? 20) * (1.0.h / 10) * 1.4;
    final double subtitleFontSize = (baseSubtitleStyle.fontSize ?? 12) * (1.0.h / 10);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedStatFilter == filter) {
            // Deselect if clicking the same filter
            _selectedStatFilter = StatFilter.none;
          } else {
            _selectedStatFilter = filter;
          }
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.0.h, horizontal: 0.5.w),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(1.5.h),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: titleFontSize * (isPresent ? 1.0 : 1.2),
              child: Center(
                child: Text(
                  value,
                  style: baseTitleStyle.copyWith(
                    color: isSelected ? primaryColor : null,
                    fontSize: isPresent
                        ? (titleFontSize * 0.85)
                        : titleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            SizedBox(height: 1.0.h),
            Flexible(
              child: Text(
              label,
              style: baseSubtitleStyle.copyWith(
                color: isSelected ? primaryColor : null,
                fontWeight: isSelected ? FontWeight.w600 : null,
                fontSize: isPresent
                    ? (subtitleFontSize * 0.9)
                    : subtitleFontSize,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterIndicator(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    String filterLabel = '';
    switch (_selectedStatFilter) {
      case StatFilter.present:
        filterLabel = 'Present';
        break;
      case StatFilter.absent:
        filterLabel = 'Absent';
        break;
      case StatFilter.missingCheckout:
        filterLabel = 'Missing Checkout';
        break;
      case StatFilter.leftEarly:
        filterLabel = 'Left Early';
        break;
      case StatFilter.none:
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(Symbols.filter_list, size: 18, color: primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing: $filterLabel',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedStatFilter = StatFilter.none;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Symbols.close, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    // Hide tabs when a stat filter is selected
    if (_selectedStatFilter != StatFilter.none) {
      return const SizedBox.shrink();
    }

    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: DashboardTab.values.map((DashboardTab tab) {
          final bool isActive = tab == _activeTab;
          final String label = tab == DashboardTab.present
              ? 'Present'
              : 'On Leave';
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isActive ? primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isActive ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<Set<int>> _getUsersOnLeaveForDate(DateTime date) async {
    final String dateStr = DateFormat('yyyy-MM-dd').format(date);
    final Set<int> userIdsOnLeave = <int>{};

    // Get all requests and filter for approved leave requests
    try {
      final List<UserRequest> allRequests = await requestController
          .getAllRequestsUseCase();
      for (final UserRequest request in allRequests) {
        // Check if it's an approved leave request
        final String requestType = request.type.toLowerCase();
        if (request.status == 'approved' &&
            (requestType.contains('leave') ||
                requestType.contains('day_off') ||
                requestType == 'leave')) {
          // Check if the date falls within the request date range
          bool isDateInRange = false;

          if (request.date != null && request.date!.isNotEmpty) {
            // Single day leave
            final String requestDate = request.date!.split(
              ' ',
            )[0]; // Get date part only
            if (requestDate == dateStr) {
              isDateInRange = true;
            }
          } else if (request.startDate != null && request.endDate != null) {
            // Date range leave
            final DateTime? start = DateTime.tryParse(
              request.startDate!.split(' ')[0],
            );
            final DateTime? end = DateTime.tryParse(
              request.endDate!.split(' ')[0],
            );
            if (start != null && end != null) {
              final DateTime checkDate = DateTime(
                date.year,
                date.month,
                date.day,
              );
              final DateTime startDateOnly = DateTime(
                start.year,
                start.month,
                start.day,
              );
              final DateTime endDateOnly = DateTime(
                end.year,
                end.month,
                end.day,
              );
              if (checkDate.isAtSameMomentAs(startDateOnly) ||
                  checkDate.isAtSameMomentAs(endDateOnly) ||
                  (checkDate.isAfter(startDateOnly) &&
                      checkDate.isBefore(endDateOnly))) {
                isDateInRange = true;
              }
            }
          }

          if (isDateInRange && request.userId != null) {
            userIdsOnLeave.add(request.userId!);
          }
        }
      }
    } catch (e) {
      // If there's an error, return empty set
    }

    return userIdsOnLeave;
  }

  Widget _buildAttendanceList(BuildContext context) {
    final List<AttendanceRecord> records =
        attendanceController.attendanceByDate;
    if (records.isEmpty) {
      if (attendanceController.isAttendanceLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      return _emptyState('No attendance records for this date.');
    }

    Iterable<AttendanceRecord> filtered = records;

    // Apply search filter if there's a search query
    final String searchQuery = _searchController.text.toLowerCase().trim();
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((AttendanceRecord record) {
        final String userName = record.userName.toLowerCase();
        final String employeeNumber = (record.userEmployeeNumber ?? '')
            .toLowerCase();
        final String email = (record.userEmail ?? '').toLowerCase();
        return userName.contains(searchQuery) ||
            employeeNumber.contains(searchQuery) ||
            email.contains(searchQuery);
      });
    }

    // Apply stat filter if selected
    if (_selectedStatFilter != StatFilter.none) {
      switch (_selectedStatFilter) {
        case StatFilter.present:
          filtered = filtered.where(
            (AttendanceRecord record) => record.status == 'present',
          );
          break;
        case StatFilter.absent:
          filtered = filtered.where((AttendanceRecord record) {
            // Absent: never checked in (no firstCheckIn)
            final bool neverCheckedIn =
                record.firstCheckIn == null || record.firstCheckIn!.isEmpty;
            return neverCheckedIn;
          });
          break;
        case StatFilter.missingCheckout:
          filtered = filtered.where((AttendanceRecord record) {
            // Missing checkout: has checked in but hasn't checked out
            final bool hasCheckedIn =
                record.firstCheckIn != null && record.firstCheckIn!.isNotEmpty;
            final bool hasNotCheckedOut =
                record.lastCheckOut == null || record.lastCheckOut!.isEmpty;
            return hasCheckedIn && hasNotCheckedOut;
          });
          break;
        case StatFilter.leftEarly:
          filtered = filtered.where(
            (AttendanceRecord record) =>
                record.status == 'present' &&
                record.lastCheckOut != null &&
                (record.missingHours ?? 0) > 0.1,
          );
          break;
        case StatFilter.none:
          break;
      }
    } else {
      // Apply tab filter if no stat filter is selected
      filtered = _activeTab == DashboardTab.present
          ? filtered.where(
              (AttendanceRecord record) => record.status == 'present',
            )
          : filtered.where((AttendanceRecord record) {
              // On Leave: user has an approved leave request for this date
              return _usersOnLeave.contains(record.userId);
            });
    }

    if (filtered.isEmpty) {
      String message = 'No data for this filter.';
      if (_selectedStatFilter != StatFilter.none) {
        switch (_selectedStatFilter) {
          case StatFilter.present:
            message = 'No present employees for this date.';
            break;
          case StatFilter.absent:
            message = 'No absent employees for this date.';
            break;
          case StatFilter.missingCheckout:
            message = 'No employees with missing checkout for this date.';
            break;
          case StatFilter.leftEarly:
            message = 'No employees who left early for this date.';
            break;
          case StatFilter.none:
            message = 'No data for this tab yet.';
            break;
        }
      }
      return _emptyState(message);
    }

    return Column(
      children: filtered
          .map((AttendanceRecord record) => _buildEmployeeCard(context, record))
          .toList(),
    );
  }

  Widget _emptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Symbols.info),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }

  Widget _buildOnlineAttendanceCard(BuildContext context) {
    if (!selfAttendanceController.isEmployee) {
      return const SizedBox.shrink();
    }
    return Obx(() {
      if (selfAttendanceController.isStatusLoading.value) {
        return _buildLoadingCard('Syncing attendance status...');
      }
      final status = selfAttendanceController.onlineStatus.value;
      if (status == null) {
        return _emptyState('Online attendance status unavailable.');
      }

      // Check for pending requests - observe requestController.myRequests
      final DateTime now = DateTime.now();
      final String date = DateFormat('yyyy-MM-dd').format(now);
      final pendingRequests = requestController.myRequests.where((request) {
        return request.type == 'attendance_correction' &&
            request.date == date &&
            request.isPending;
      }).toList();
      final hasPendingRequest = pendingRequests.isNotEmpty;

      final bool canCheckIn = status.canCheckIn ?? false;
      final bool canCheckOut = status.canCheckOut ?? false;
      final bool hasCheckedIn = status.checkInTime != null && status.checkInTime!.isNotEmpty;
      final bool hasCheckedOut = status.checkOutTime != null && status.checkOutTime!.isNotEmpty;
      final bool isProcessing =
          selfAttendanceController.isCheckInProcessing.value ||
          selfAttendanceController.isCheckOutProcessing.value;
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Today\'s attendance',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      status.currentIraqTime ?? '--',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Check-in',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        _formatTime(status.checkInTime),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Check-out',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        _formatTime(status.checkOutTime),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Worked',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        _formatDuration(status.totalHours),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (hasPendingRequest) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You have a pending request. Waiting for admin approval.',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton(
                    onPressed: (isProcessing || !canCheckIn || hasCheckedIn)
                        ? null
                        : selfAttendanceController.checkIn,
                    child: isProcessing && !hasCheckedIn
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Check in'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: (isProcessing || !canCheckOut || hasCheckedOut)
                        ? null
                        : selfAttendanceController.checkOut,
                    child: isProcessing && hasCheckedIn && !hasCheckedOut
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Check out'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMySummaryCard(BuildContext context) {
    if (!selfAttendanceController.isEmployee) {
      return const SizedBox.shrink();
    }
    return Obx(() {
      if (selfAttendanceController.isSummaryLoading.value) {
        return _buildLoadingCard('Loading your summary...');
      }
      final fullSummary = selfAttendanceController.fullMySummary.value;
      if (fullSummary == null) {
        return _emptyState('Summary unavailable.');
      }

      // Calculate totals
      final double totalWorkedHours = fullSummary.attendance.fold<double>(
        0,
        (sum, record) => sum + (record.workedHours ?? 0),
      );
      final double totalMissingHours = fullSummary.attendance.fold<double>(
        0,
        (sum, record) => sum + (record.missingHours ?? 0),
      );
      
      // Get overtime from statistics first, fallback to calculating from attendance records
      final Map<String, dynamic>? stats = fullSummary.statistics;
      double totalOvertimeHours = 0;
      int totalOvertimeIQD = 0;
      
      if (stats != null) {
        // Get from statistics if available
        final dynamic overtimeHoursValue = stats['total_overtime_hours'];
        if (overtimeHoursValue != null) {
          if (overtimeHoursValue is num) {
            totalOvertimeHours = overtimeHoursValue.toDouble();
          } else if (overtimeHoursValue is String) {
            totalOvertimeHours = double.tryParse(overtimeHoursValue) ?? 0;
          }
        }
        
        final dynamic overtimeAmountValue = stats['total_overtime_amount_iqd'];
        if (overtimeAmountValue != null) {
          if (overtimeAmountValue is num) {
            totalOvertimeIQD = overtimeAmountValue.toInt();
          } else if (overtimeAmountValue is String) {
            totalOvertimeIQD = int.tryParse(overtimeAmountValue) ?? 0;
          }
        }
      }
      
      // Fallback: calculate from attendance records if statistics not available or doesn't have overtime
      if (totalOvertimeHours == 0) {
        totalOvertimeHours = fullSummary.attendance.fold<double>(
          0,
          (sum, record) => sum + (record.overtimeHours ?? 0),
        );
      }
      
      // Also try to get from overtime list if statistics doesn't have amount
      if (totalOvertimeIQD == 0 && fullSummary.overtime != null) {
        totalOvertimeIQD = fullSummary.overtime!.fold<int>(
          0,
          (sum, ot) {
            final dynamic amount = ot['amount_iqd'];
            if (amount == null) return sum;
            if (amount is num) return sum + amount.toInt();
            if (amount is String) return sum + (int.tryParse(amount) ?? 0);
            return sum;
          },
        );
      }
      
      // Final fallback: calculate amount from attendance records if still 0
      if (totalOvertimeIQD == 0) {
        totalOvertimeIQD = fullSummary.attendance.fold<int>(
          0,
          (sum, record) => sum + (record.overtimeAmountIqd ?? 0),
        );
      }
      final double totalTaskHours =
          fullSummary.tasks?.fold<double>(
            0,
            (sum, task) =>
                sum + ((task['reported_hours'] as num?)?.toDouble() ?? 0),
          ) ??
          0;
      final int taskCount = fullSummary.tasks?.length ?? 0;
      final int presentDays = fullSummary.attendance
          .where((record) => record.status == 'present')
          .length;
      final int missingCheckouts = fullSummary.attendance
          .where(
            (record) =>
                record.status == 'present' && record.lastCheckOut == null,
          )
          .length;
      final int daysOff = fullSummary.absentDays.length;
      final Color accentColor = Theme.of(context).colorScheme.primary;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final DateTime now = DateTime.now();
                    final DateTime firstDate = now.subtract(
                      const Duration(days: 365),
                    );
                    final DateTime lastDate = now;

                    // Determine initial dates
                    DateTime? initialStart;
                    DateTime? initialEnd;

                    if (selfAttendanceController.summaryFromDate != null &&
                        selfAttendanceController.summaryToDate != null) {
                      initialStart = selfAttendanceController.summaryFromDate!;
                      initialEnd = selfAttendanceController.summaryToDate!;
                    } else {
                      initialStart = now.subtract(const Duration(days: 30));
                      initialEnd = now;
                    }

                    // Clamp the initial dates to ensure they're within valid range
                    final DateTime clampedStart =
                        initialStart.isBefore(firstDate)
                        ? firstDate
                        : initialStart.isAfter(lastDate)
                        ? lastDate
                        : initialStart;

                    final DateTime clampedEnd = initialEnd.isBefore(firstDate)
                        ? firstDate
                        : initialEnd.isAfter(lastDate)
                        ? lastDate
                        : initialEnd;

                    // Ensure end is not before start
                    final DateTime finalEnd = clampedEnd.isBefore(clampedStart)
                        ? clampedStart
                        : clampedEnd;

                    final DateTimeRange? picked = await showDateRangePicker(
                      context: context,
                      firstDate: firstDate,
                      lastDate: lastDate,
                      initialDateRange: DateTimeRange(
                        start: clampedStart,
                        end: finalEnd,
                      ),
                    );
                    if (picked != null) {
                      selfAttendanceController.summaryFromDate = picked.start;
                      selfAttendanceController.summaryToDate = picked.end;
                      selfAttendanceController.loadSummaryWithDates(
                        picked.start,
                        picked.end,
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Symbols.calendar_today,
                          size: 14,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Select Period',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Key Metrics Grid
            Row(
              children: <Widget>[
                Expanded(
                  child: _buildSimpleMetricCard(
                    context,
                    icon: Symbols.access_time,
                    label: 'Worked Hours',
                    value: '${totalWorkedHours.toStringAsFixed(1)}',
                    unit: 'h',
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSimpleMetricCard(
                    context,
                    icon: Symbols.check_circle,
                    label: 'Days Present',
                    value: presentDays.toString(),
                    unit: 'days',
                    color: accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: _buildSimpleMetricCard(
                    context,
                    icon: Symbols.trending_up,
                    label: 'Overtime',
                    value: '${totalOvertimeHours.toStringAsFixed(1)}',
                    unit: 'h',
                    subtitle: '$totalOvertimeIQD IQD',
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSimpleMetricCard(
                    context,
                    icon: Symbols.task_alt,
                    label: 'Tasks',
                    value: taskCount.toString(),
                    unit: 'tasks',
                    subtitle: '${totalTaskHours.toStringAsFixed(1)}h',
                    color: accentColor,
                  ),
                ),
              ],
            ),
            if (totalMissingHours > 0 ||
                daysOff > 0 ||
                missingCheckouts > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(Symbols.info, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          if (totalMissingHours > 0)
                            Text(
                              'Missing: ${totalMissingHours.toStringAsFixed(1)}h',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[900],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          if (daysOff > 0)
                            Text(
                              'Days Off: $daysOff',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[900],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          if (missingCheckouts > 0)
                            Text(
                              'Missing Checkouts: $missingCheckouts',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[900],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Recent Attendance Section
            if (fullSummary.attendance.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Attendance History (${fullSummary.attendance.length} days)',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...fullSummary.attendance.map((record) {
                final Color statusColor = record.status == 'present'
                    ? Colors.green[100]!
                    : record.status == 'Didn\'t Check Out'
                    ? Colors.orange[100]!
                    : Colors.grey[100]!;
                final Color statusTextColor = record.status == 'present'
                    ? Colors.green[800]!
                    : record.status == 'Didn\'t Check Out'
                    ? Colors.orange[800]!
                    : Colors.grey[800]!;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              DateFormat(
                                'MMM d, yyyy',
                              ).format(DateTime.parse(record.date)),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              record.dayName,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              if (record.workedHours != null)
                                Text(
                                  '${record.workedHours!.toStringAsFixed(1)}h',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              if (record.overtimeHours != null &&
                                  record.overtimeHours! > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '+${record.overtimeHours!.toStringAsFixed(1)}h OT',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange[900],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              record.status ?? '-',
                              style: TextStyle(
                                fontSize: 11,
                                color: statusTextColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildSimpleMetricCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    String? subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: 11,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color.withOpacity(0.8),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMyShiftCard(BuildContext context) {
    return Obx(() {
      final Shift? shift = shiftController.myShift.value;
      if (shift == null) {
        return const SizedBox.shrink();
      }

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    Symbols.access_time,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'My Shift',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(shift.name, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Start Time',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          shift.startTime,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'End Time',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          shift.endTime,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (shift.gracePeriodMinutes != null &&
                  shift.gracePeriodMinutes! > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Grace Period: ${shift.gracePeriodMinutes} minutes',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildLoadingCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: <Widget>[
          const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(BuildContext context, AttendanceRecord record) {
    final Map<String, dynamic> badge = _statusBadge(record);
    final String idLabel = record.userEmployeeNumber?.isNotEmpty == true
        ? record.userEmployeeNumber!
        : record.userId.toString();
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    return EmployeeCard(
      userName: record.userName,
      employeeNumber: record.userEmployeeNumber,
      userId: record.userId,
      photo: record.userPhoto,
      avatarBackgroundColor: primaryColor.withOpacity(0.12),
      avatarTextColor: primaryColor,
      subtitle: Wrap(
        spacing: 1.0.w,
        runSpacing: 0.5.h,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    _subInfo(Symbols.login, _formatTime(record.firstCheckIn)),
                    _subInfo(Symbols.logout, _formatTime(record.lastCheckOut)),
                    _subInfo(
                      Symbols.timer,
                      _formatDuration(record.workedHours),
                    ),
                  ],
                ),
      trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
          SizedBox(height: 0.8.h),
              Text(
                '${record.workedHours?.toStringAsFixed(1) ?? '0'}h',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 1.8.h,
                ),
              ),
          SizedBox(height: 0.5.h),
              Text(
                badge['label'] as String,
                style: TextStyle(
                  color: badge['textColor'] as Color,
                  fontWeight: FontWeight.w600,
              fontSize: 1.4.h,
                ),
          ),
        ],
      ),
    );
  }

  Widget _subInfo(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
      ],
    );
  }

  Map<String, dynamic> _statusBadge(AttendanceRecord record) {
    String label = 'Present';
    Color background = Colors.green.shade100;
    Color textColor = Colors.green.shade800;

    if (record.lastCheckOut == null) {
      label = 'In Progress';
      background = Colors.blue.shade100;
      textColor = Colors.blue.shade800;
    } else if ((record.missingHours ?? 0) > 0.1) {
      label = 'Late';
      background = Colors.orange.shade100;
      textColor = Colors.orange.shade800;
    } else if ((record.status ?? '') != 'present') {
      label = record.status?.toUpperCase() ?? 'Status';
      background = Colors.grey.shade200;
      textColor = Colors.grey.shade800;
    } else {
      label = 'On Time';
      background = Colors.green.shade100;
      textColor = Colors.green.shade800;
    }

    return <String, dynamic>{
      'label': label,
      'color': background,
      'textColor': textColor,
    };
  }

  String _formatTime(String? value) {
    if (value == null || value.isEmpty) return '--';

    // Try to parse as full datetime string (e.g., "2025-11-17 08:30:00")
    DateTime? dateTime = DateTime.tryParse(value);

    // If parsing fails, try to parse as time-only string (e.g., "08:30" or "14:30")
    if (dateTime == null) {
      final RegExp timePattern = RegExp(r'^(\d{1,2}):(\d{2})$');
      final Match? match = timePattern.firstMatch(value.trim());
      if (match != null) {
        final int hour = int.parse(match.group(1)!);
        final int minute = int.parse(match.group(2)!);
        // Create a DateTime with today's date for formatting purposes
        dateTime = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          hour,
          minute,
        );
      }
    }

    // If still can't parse, return original value
    if (dateTime == null) return value;

    // Format as 12-hour time with AM/PM
    return DateFormat('hh:mm a').format(dateTime);
  }

  String _formatDuration(double? hours) {
    final double totalHours = hours ?? 0;
    final Duration duration = Duration(minutes: (totalHours * 60).round());
    final int h = duration.inHours;
    final int m = duration.inMinutes.remainder(60);
    return '${h}h ${m}m';
  }

  _DailySummaryMetrics? _getDailySummaryMetrics() {
    final List<AttendanceRecord> records = List<AttendanceRecord>.from(
      attendanceController.attendanceByDate,
    );
    if (records.isNotEmpty) {
      return _calculateMetricsFromRecords(records);
    }

    final AttendanceSummary? summary = attendanceController.summary.value;
    if (summary == null) {
      return null;
    }

    return _DailySummaryMetrics(
      totalUsers: summary.totalUsers,
      present: summary.present,
      absent: summary.absent,
      missingCheckout: summary.missingCheckout,
      leftEarly: summary.leftEarly,
    );
  }

  _DailySummaryMetrics _calculateMetricsFromRecords(
    List<AttendanceRecord> records,
  ) {
    int present = 0;
    int absent = 0;
    int missingCheckout = 0;
    int leftEarly = 0;

    for (final AttendanceRecord record in records) {
      final String status = (record.status ?? '').toLowerCase();
      final bool hasCheckIn =
          record.firstCheckIn != null && record.firstCheckIn!.isNotEmpty;
      final bool hasCheckOut =
          record.lastCheckOut != null && record.lastCheckOut!.isNotEmpty;
      final double missingHours = record.missingHours ?? 0;

      if (status == 'present') {
        present++;
      }

      if (!hasCheckIn) {
        absent++;
      }

      if (hasCheckIn && !hasCheckOut) {
        missingCheckout++;
      }

      if (status == 'present' && hasCheckOut && missingHours > 0.1) {
        leftEarly++;
      }
    }

    return _DailySummaryMetrics(
      totalUsers: records.length,
      present: present,
      absent: absent,
      missingCheckout: missingCheckout,
      leftEarly: leftEarly,
    );
  }
}

class _DailySummaryMetrics {
  const _DailySummaryMetrics({
    required this.totalUsers,
    required this.present,
    required this.absent,
    required this.missingCheckout,
    required this.leftEarly,
  });

  final int totalUsers;
  final int present;
  final int absent;
  final int missingCheckout;
  final int leftEarly;
}

class _GradientCircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final List<Color> gradientColors;

  _GradientCircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = (size.width - strokeWidth) / 2;

    // Draw background circle
    final Paint backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(centerX, centerY), radius, backgroundPaint);

    // Draw progress arc with gradient
    if (progress > 0) {
      final Rect rect = Rect.fromCircle(
        center: Offset(centerX, centerY),
        radius: radius,
      );

      // Create a sweep gradient that follows the arc
      final Paint progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          colors: gradientColors,
          stops: const <double>[0.0, 0.5, 1.0],
        ).createShader(rect);

      // Save canvas state
      canvas.save();
      // Rotate to start from top
      canvas.translate(centerX, centerY);
      canvas.rotate(-90 * (3.14159 / 180));
      canvas.translate(-centerX, -centerY);

      canvas.drawArc(
        rect,
        0, // Start from 0 after rotation
        2 * 3.14159 * progress, // Progress angle
        false,
        progressPaint,
      );

      // Restore canvas state
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_GradientCircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.gradientColors != gradientColors;
  }
}
