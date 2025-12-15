import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:sizer/sizer.dart';

import '../../controllers/auth_controller.dart';
import '../../../core/constants/app_routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final AuthController controller;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    controller = Get.find<AuthController>();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isTablet = SizerUtil.deviceType == DeviceType.tablet;
    final double logoSize = isTablet ? 180.0 : 120.0;
    final double maxWidth = isTablet ? 500.0 : 380.0;
    final double horizontalPadding = isTablet ? 48.0 : 20.0;
    final double verticalPadding = isTablet ? 48.0 : 24.0;
    final double formPadding = isTablet ? 24.0 : 14.0;
    final double spacing = isTablet ? 32.0 : 28.0;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                children: <Widget>[
                  Image.asset(
                    'assets/logo.png',
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.contain,
                    errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                      return Container(
                        width: logoSize,
                        height: logoSize,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.business,
                          size: logoSize * 0.5,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      );
                    },
                  ),
                  SizedBox(height: spacing),
                  Container(
                    padding: EdgeInsets.all(formPadding),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                   
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: <Widget>[
                          _buildInputField(
                            context,
                            label: 'Email',
                            hint: 'Your email or phone',
                            icon: Symbols.email,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (String? value) =>
                                (value == null || value.isEmpty)
                                ? 'Email is required'
                                : null,
                          ),
                          SizedBox(height: isTablet ? 20.0 : 12.0),
                          _buildInputField(
                            context,
                            label: 'Password',
                            hint: '••••••••',
                            icon: Symbols.lock,
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            suffix: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Symbols.visibility_off
                                    : Symbols.visibility,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            validator: (String? value) =>
                                (value == null || value.isEmpty)
                                ? 'Password is required'
                                : null,
                          ),
                          SizedBox(height: isTablet ? 24.0 : 16.0),
                          Obx(
                            () => SizedBox(
                              width: double.infinity,
                              height: isTablet ? 56.0 : 44.0,
                              child: FilledButton(
                                onPressed: controller.isLoading.value
                                    ? null
                                    : _onSubmit,
                                child: controller.isLoading.value
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text('Sign in', style: TextStyle(fontSize: isTablet ? 16.0 : 13.0)),
                              ),
                            ),
                          ),
                          SizedBox(height: isTablet ? 16.0 : 10.0),
                          Obx(
                            () => controller.errorMessage.value == null
                                ? const SizedBox.shrink()
                                : Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      controller.errorMessage.value!,
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                          ),
                          SizedBox(height: isTablet ? 20.0 : 16.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                'Don\'t have an account? ',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: isTablet ? 16.0 : 14.0,
                                ),
                              ),
                              TextButton(
                                onPressed: () => Get.toNamed(AppRoutes.register),
                                child: Text(
                                  'Register',
                                  style: TextStyle(
                                    fontSize: isTablet ? 16.0 : 14.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    BuildContext context, {
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color surfaceColor = Theme.of(context).colorScheme.surface;
    final bool isTablet = SizerUtil.deviceType == DeviceType.tablet;
    final double labelFontSize = isTablet ? 14.0 : 10.sp;
    final double inputFontSize = isTablet ? 16.0 : 12.sp;
    final double iconSize = isTablet ? 24.0 : 18.0;
    final double verticalPadding = isTablet ? 18.0 : 1.4.h;
    final double horizontalPadding = isTablet ? 16.0 : 3.5.w;
    final double borderRadius = isTablet ? 14.0 : 10.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
            fontSize: labelFontSize,
          ),
        ),
        SizedBox(height: isTablet ? 8.0 : 0.6.h),
        Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            validator: validator,
            style: TextStyle(fontSize: inputFontSize),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: iconSize, color: primaryColor),
              suffixIcon: suffix,
              hintText: hint,
              hintStyle: TextStyle(fontSize: inputFontSize, color: Colors.grey[400]),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                vertical: verticalPadding,
                horizontal: horizontalPadding,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    controller.login(_emailController.text, _passwordController.text);
  }
}
