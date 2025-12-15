import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:sizer/sizer.dart';

import '../../controllers/auth_controller.dart';
import '../../../core/constants/app_routes.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final AuthController controller;
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  late final TextEditingController _phoneController;
  late final TextEditingController _employeeNumberController;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    controller = Get.find<AuthController>();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _phoneController = TextEditingController();
    _employeeNumberController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _employeeNumberController.dispose();
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
                  Text(
                    'Create Account',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: spacing * 0.5),
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
                            label: 'Full Name',
                            hint: 'Enter your full name',
                            icon: Symbols.person,
                            controller: _nameController,
                            keyboardType: TextInputType.name,
                            validator: (String? value) =>
                                (value == null || value.trim().isEmpty)
                                ? 'Name is required'
                                : null,
                          ),
                          SizedBox(height: isTablet ? 16.0 : 10.0),
                          _buildInputField(
                            context,
                            label: 'Email',
                            hint: 'your.email@example.com',
                            icon: Symbols.email,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (String? value) {
                              if (value == null || value.isEmpty) {
                                return 'Email is required';
                              }
                              if (!GetUtils.isEmail(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: isTablet ? 16.0 : 10.0),
                          _buildInputField(
                            context,
                            label: 'Phone Number',
                            hint: '9647XXXXXXXXX',
                            icon: Symbols.phone,
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            helperText: 'Iraqi format: 9647XXXXXXXXX',
                          ),
                          SizedBox(height: isTablet ? 16.0 : 10.0),
                          _buildInputField(
                            context,
                            label: 'Employee Number',
                            hint: 'Enter employee number',
                            icon: Symbols.badge,
                            controller: _employeeNumberController,
                            keyboardType: TextInputType.number,
                          ),
                          SizedBox(height: isTablet ? 16.0 : 10.0),
                          _buildInputField(
                            context,
                            label: 'Password',
                            hint: 'Enter your password',
                            icon: Symbols.lock,
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            validator: (String? value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                            suffix: IconButton(
                              icon: Icon(
                                _obscurePassword ? Symbols.visibility_off : Symbols.visibility,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          SizedBox(height: isTablet ? 16.0 : 10.0),
                          _buildInputField(
                            context,
                            label: 'Confirm Password',
                            hint: 'Re-enter your password',
                            icon: Symbols.lock,
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            validator: (String? value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                            suffix: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Symbols.visibility_off : Symbols.visibility,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
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
                          SizedBox(height: isTablet ? 24.0 : 20.0),
                          Obx(
                            () => SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: controller.isLoading.value
                                    ? null
                                    : () async {
                                        if (_formKey.currentState?.validate() == true) {
                                          // Format phone number if provided
                                          String? phoneNumber;
                                          if (_phoneController.text.trim().isNotEmpty) {
                                            String phone = _phoneController.text.trim();
                                            if (phone.startsWith('0')) {
                                              phone = '964${phone.substring(1)}';
                                            } else if (phone.startsWith('7') && !phone.startsWith('964')) {
                                              phone = '964$phone';
                                            }
                                            phoneNumber = phone;
                                          }
                                          
                                          await controller.register(
                                            name: _nameController.text,
                                            email: _emailController.text,
                                            password: _passwordController.text,
                                            phoneNumber: phoneNumber,
                                            employeeNumber: _employeeNumberController.text.trim().isNotEmpty
                                                ? _employeeNumberController.text.trim()
                                                : null,
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: isTablet ? 18.0 : 14.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: controller.isLoading.value
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(
                                        'Register',
                                        style: TextStyle(
                                          fontSize: isTablet ? 18.0 : 16.0,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          SizedBox(height: isTablet ? 20.0 : 16.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                'Already have an account? ',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: isTablet ? 16.0 : 14.0,
                                ),
                              ),
                              TextButton(
                                onPressed: () => Get.offNamed(AppRoutes.login),
                                child: Text(
                                  'Login',
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
    String? helperText,
  }) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final bool isTablet = SizerUtil.deviceType == DeviceType.tablet;
    
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: TextStyle(fontSize: isTablet ? 16.0 : 14.0),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        prefixIcon: Icon(icon, size: isTablet ? 22.0 : 20.0),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? 20.0 : 16.0,
          vertical: isTablet ? 20.0 : 16.0,
        ),
      ),
    );
  }
}

