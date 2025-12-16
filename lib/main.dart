import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

import 'core/constants/app_routes.dart';
import 'core/storage/app_preferences.dart';
import 'core/theme/app_theme.dart';
import 'presentation/bindings/app_binding.dart';
import 'presentation/routes/app_pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final AppPreferences appPreferences = await AppPreferences.load();
  Get.put<AppPreferences>(appPreferences, permanent: true);
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder:
          (
            BuildContext context,
            Orientation orientation,
            DeviceType deviceType,
          ) {
            return GetMaterialApp(
              title: 'سجّل | Sijil',
              debugShowCheckedModeBanner: false,
              initialBinding: AppBinding(),
              initialRoute: AppRoutes.splash,
              getPages: AppPages.pages,
              theme: AppTheme.lightTheme,
            );
          },
    );
  }
}
