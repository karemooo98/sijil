import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

import '../../../domain/entities/user.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/user_controller.dart';
import '../../widgets/employee_card.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final UserController controller = Get.find<UserController>();
    final AuthController authController = Get.find<AuthController>();
    final String? userRole = authController.session.value?.user?.role;
    final bool isAdmin = userRole == 'admin';

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Access denied. Admin only.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (String? role) {
              controller.loadAllUsers(role: role == 'all' ? null : role);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem(value: 'all', child: Text('All Users')),
              const PopupMenuItem(value: 'admin', child: Text('Admins')),
              const PopupMenuItem(value: 'manager', child: Text('Managers')),
              const PopupMenuItem(value: 'employee', child: Text('Employees')),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateUserDialog(context, controller),
        icon: const Icon(Icons.person_add),
        label: const Text('New User'),
      ),
      body: Obx(
        () {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage.value.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    controller.errorMessage.value,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => controller.loadAllUsers(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (controller.users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No users found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => controller.loadAllUsers(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.users.length,
              itemBuilder: (BuildContext context, int index) {
                final User user = controller.users[index];
                return _buildUserCard(context, user, controller);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, User user, UserController controller) {
    final Color roleColor = _getRoleColor(user.role);

    return EmployeeCard(
      userName: user.name,
      employeeNumber: user.employeeNumber?.toString(),
      userId: user.id,
      photo: user.photo,
      avatarBackgroundColor: roleColor.withValues(alpha: 0.2),
      avatarTextColor: roleColor,
      backgroundColor: Colors.grey.shade100,
      onTap: () => _showEditUserDialog(context, user, controller),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
          SizedBox(height: 0.5.h),
          Text(
            user.email,
            style: TextStyle(fontSize: 1.4.h, color: Colors.grey[600]),
          ),
          SizedBox(height: 0.5.h),
          Wrap(
            spacing: 1.0.w,
            runSpacing: 0.5.h,
              children: <Widget>[
                Container(
                padding: EdgeInsets.symmetric(horizontal: 1.0.w, vertical: 0.4.h),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(1.2.h),
                  ),
                  child: Text(
                    user.role.toUpperCase(),
                    style: TextStyle(
                      color: roleColor,
                    fontSize: 1.2.h,
                      fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!user.isActive)
                  Container(
                  padding: EdgeInsets.symmetric(horizontal: 1.0.w, vertical: 0.4.h),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(1.2.h),
                    ),
                  child: Text(
                      'INACTIVE',
                      style: TextStyle(
                        color: Colors.red,
                      fontSize: 1.2.h,
                        fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (String action) {
            if (action == 'edit') {
              _showEditUserDialog(context, user, controller);
            } else if (action == 'delete') {
              _confirmDeleteUser(context, user, controller);
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.purple;
      case 'manager':
        return Colors.blue;
      case 'employee':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showCreateUserDialog(BuildContext context, UserController controller) async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController employeeNumberController = TextEditingController();
    String selectedRole = 'employee';
    bool isActive = true;

    final bool? result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Form(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Create New User',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name *'),
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email *'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!value.contains('@')) {
                      return 'Invalid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password *'),
                  obscureText: true,
                  validator: (String? value) {
                    if (value == null || value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: employeeNumberController,
                  decoration: const InputDecoration(labelText: 'Employee Number (optional)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(labelText: 'Role *'),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'manager', child: Text('Manager')),
                    DropdownMenuItem(value: 'employee', child: Text('Employee')),
                  ],
                  onChanged: (String? value) {
                    setState(() => selectedRole = value ?? 'employee');
                  },
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Active'),
                  value: isActive,
                  onChanged: (bool? value) {
                    setState(() => isActive = value ?? true);
                  },
                ),
                const SizedBox(height: 24),
                Obx(
                  () => FilledButton(
                    onPressed: controller.isCreating.value
                        ? null
                        : () async {
                            if (nameController.text.isNotEmpty &&
                                emailController.text.isNotEmpty &&
                                passwordController.text.isNotEmpty) {
                              final bool success = await controller.createUser(
                                name: nameController.text,
                                email: emailController.text,
                                password: passwordController.text,
                                role: selectedRole,
                                employeeNumber: employeeNumberController.text.isNotEmpty
                                    ? int.tryParse(employeeNumberController.text)
                                    : null,
                                isActive: isActive,
                              );
                              if (context.mounted) {
                                Navigator.of(context).pop(success);
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('User created successfully')),
                                  );
                                }
                              }
                            }
                          },
                    child: controller.isCreating.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create User'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true) {
      nameController.dispose();
      emailController.dispose();
      passwordController.dispose();
      employeeNumberController.dispose();
    }
  }

  Future<void> _showEditUserDialog(
    BuildContext context,
    User user,
    UserController controller,
  ) async {
    final TextEditingController nameController = TextEditingController(text: user.name);
    final TextEditingController emailController = TextEditingController(text: user.email);
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController employeeNumberController = TextEditingController(
      text: user.employeeNumber ?? '',
    );
    String selectedRole = user.role;
    bool isActive = user.isActive;

    final bool? result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Form(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Edit User',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name *'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email *'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password (leave empty to keep current)'),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: employeeNumberController,
                  decoration: const InputDecoration(labelText: 'Employee Number'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(labelText: 'Role *'),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'manager', child: Text('Manager')),
                    DropdownMenuItem(value: 'employee', child: Text('Employee')),
                  ],
                  onChanged: (String? value) {
                    setState(() => selectedRole = value ?? user.role);
                  },
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Active'),
                  value: isActive,
                  onChanged: (bool? value) {
                    setState(() => isActive = value ?? true);
                  },
                ),
                const SizedBox(height: 24),
                Obx(
                  () => FilledButton(
                    onPressed: controller.isUpdating.value
                        ? null
                        : () async {
                            final bool success = await controller.updateUser(
                              userId: user.id,
                              name: nameController.text,
                              email: emailController.text,
                              password: passwordController.text.isNotEmpty
                                  ? passwordController.text
                                  : null,
                              role: selectedRole,
                              employeeNumber: employeeNumberController.text.isNotEmpty
                                  ? int.tryParse(employeeNumberController.text)
                                  : null,
                              isActive: isActive,
                            );
                            if (context.mounted) {
                              Navigator.of(context).pop(success);
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('User updated successfully')),
                                );
                              }
                            }
                          },
                    child: controller.isUpdating.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Update User'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true) {
      nameController.dispose();
      emailController.dispose();
      passwordController.dispose();
      employeeNumberController.dispose();
    }
  }

  Future<void> _confirmDeleteUser(
    BuildContext context,
    User user,
    UserController controller,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to deactivate "${user.name}"? This will set is_active=false.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final bool success = await controller.deleteUser(user.id);
      if (context.mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deactivated successfully')),
        );
      }
    }
  }
}

