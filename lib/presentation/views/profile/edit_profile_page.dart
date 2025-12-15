import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../controllers/profile_controller.dart';
import '../../../domain/entities/user.dart';

class EditProfilePage extends StatefulWidget {
  final User user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;
  late final TextEditingController accountController;
  late final TextEditingController walletController;
  late final TextEditingController passwordController;
  late final GlobalKey<FormState> formKey;
  late final Set<String> selectedWeekendDays;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.user.name);
    emailController = TextEditingController(text: widget.user.email);
    phoneController = TextEditingController(text: widget.user.phoneNumber ?? '');
    accountController = TextEditingController(text: widget.user.accountNumber ?? '');
    walletController = TextEditingController(text: widget.user.walletNumber ?? '');
    passwordController = TextEditingController();
    formKey = GlobalKey<FormState>();
    selectedWeekendDays = Set<String>.from(widget.user.weekendDays);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    accountController.dispose();
    walletController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ProfileController controller = Get.find<ProfileController>();
    final List<String> weekDays = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Personal Information Section
              _buildSection(
                context,
                title: 'Personal Information',
                icon: Symbols.person,
                children: <Widget>[
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Name *',
                      prefixIcon: const Icon(Symbols.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (String? value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email *',
                      prefixIcon: const Icon(Symbols.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (String? value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!GetUtils.isEmail(value)) {
                        return 'Invalid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: const Icon(Symbols.phone),
                      helperText: 'Iraqi format: 9647XXXXXXXXX (13 digits)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.phone,
                    maxLength: 13,
                    onChanged: (String value) {
                      // Auto-format: if user enters number starting with 0, replace with 964
                      if (value.isNotEmpty && value.startsWith('0')) {
                        final String newValue = '964${value.substring(1)}';
                        phoneController.value = TextEditingValue(
                          text: newValue,
                          selection: TextSelection.collapsed(offset: newValue.length),
                        );
                      }
                      // Auto-format: if user enters number starting with 7, prepend 964
                      else if (value.isNotEmpty && value.startsWith('7') && !value.startsWith('964')) {
                        final String newValue = '964$value';
                        phoneController.value = TextEditingValue(
                          text: newValue,
                          selection: TextSelection.collapsed(offset: newValue.length),
                        );
                      }
                    },
                    validator: (String? value) {
                      if (value == null || value.trim().isEmpty) {
                        return null; // Phone is optional
                      }
                      final String trimmed = value.trim();
                      // Check if it matches Iraqi format: 9647XXXXXXXXX (13 digits)
                      if (!RegExp(r'^9647\d{9}$').hasMatch(trimmed)) {
                        return 'Phone must be in Iraqi format: 9647XXXXXXXXX (13 digits)';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Financial Information Section
              _buildSection(
                context,
                title: 'Financial Information',
                icon: Symbols.account_balance,
                children: <Widget>[
                  TextFormField(
                    controller: accountController,
                    decoration: InputDecoration(
                      labelText: 'Account Number',
                      prefixIcon: const Icon(Symbols.account_balance),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: walletController,
                    decoration: InputDecoration(
                      labelText: 'Wallet Number',
                      prefixIcon: const Icon(Symbols.wallet),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.text,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Password Section
              _buildSection(
                context,
                title: 'Security',
                icon: Symbols.lock,
                children: <Widget>[
                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: 'New Password (optional)',
                      prefixIcon: const Icon(Symbols.lock),
                      helperText: 'Leave empty to keep current password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    obscureText: true,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Weekend Days Section
              _buildSection(
                context,
                title: 'Weekend Days',
                icon: Symbols.calendar_today,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: weekDays.map((String day) {
                        return CheckboxListTile(
                          dense: true,
                          title: Text(day),
                          value: selectedWeekendDays.contains(day),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedWeekendDays.add(day);
                              } else {
                                selectedWeekendDays.remove(day);
                              }
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Save Button
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.isUpdating.value
                        ? null
                        : () async {
                            if (formKey.currentState?.validate() == true) {
                              // Format phone number if provided
                              String? phoneNumber;
                              if (phoneController.text.trim().isNotEmpty) {
                                String phone = phoneController.text.trim();
                                // Auto-format: if starts with 0, replace with 964
                                if (phone.startsWith('0')) {
                                  phone = '964${phone.substring(1)}';
                                }
                                // Auto-format: if starts with 7 and doesn't start with 964, prepend 964
                                else if (phone.startsWith('7') && !phone.startsWith('964')) {
                                  phone = '964$phone';
                                }
                                phoneNumber = phone;
                              }
                              
                              final bool success = await controller.updateProfile(
                                name: nameController.text,
                                email: emailController.text,
                                password: passwordController.text.isNotEmpty
                                    ? passwordController.text
                                    : null,
                                phoneNumber: phoneNumber,
                                accountNumber: accountController.text.trim().isNotEmpty
                                    ? accountController.text.trim()
                                    : null,
                                walletNumber: walletController.text.trim().isNotEmpty
                                    ? walletController.text.trim()
                                    : null,
                                weekendDays: selectedWeekendDays.toList(),
                              );
                              if (mounted) {
                                if (success) {
                                  // Reload profile to get updated data
                                  await controller.loadProfile();
                                  Get.back();
                                  Get.snackbar(
                                    'Success',
                                    'Profile updated successfully',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.green,
                                    colorText: Colors.white,
                                  );
                                } else {
                                  Get.snackbar(
                                    'Error',
                                    controller.errorMessage.value ?? 'Failed to update profile',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.red,
                                    colorText: Colors.white,
                                  );
                                }
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: controller.isUpdating.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}

