import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/notification.dart' as domain;
import '../../controllers/auth_controller.dart';
import '../../controllers/notification_controller.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final NotificationController controller = Get.find<NotificationController>();
    final AuthController authController = Get.find<AuthController>();
    final String? userRole = authController.session.value?.user?.role;
    final bool canSend = userRole == 'admin' || userRole == 'manager';

    // Fetch data every time we enter the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadNotifications();
    });

    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          Obx(
            () => controller.unreadCount.value > 0
                ? IconButton(
                    icon: const Icon(Icons.done_all),
                    tooltip: 'Mark all as read',
                    onPressed: controller.isMarkingAsRead.value
                        ? null
                        : () => controller.markAllAsRead(),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      floatingActionButton: canSend
          ? FloatingActionButton.extended(
              onPressed: () => _showSendNotificationDialog(context, controller),
              icon: const Icon(Icons.send),
              label: const Text('Send'),
            )
          : null,
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
                    onPressed: controller.loadNotifications,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (controller.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'re all caught up!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: controller.loadNotifications,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: controller.notifications.length,
              itemBuilder: (BuildContext context, int index) {
                final domain.Notification notification = controller.notifications[index];
                return _buildNotificationCard(context, notification, controller);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    domain.Notification notification,
    NotificationController controller,
  ) {
    final Color typeColor = _getTypeColor(notification.type);
    final IconData typeIcon = _getTypeIcon(notification.type);
    final DateFormat dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    DateTime? createdAt;
    try {
      createdAt = DateTime.parse(notification.createdAt);
    } catch (e) {
      // Ignore parse errors
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: notification.isRead ? null : Theme.of(context).colorScheme.surfaceVariant,
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            controller.markAsRead(notification.id);
          }
          _showNotificationDetails(context, notification);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(typeIcon, color: typeColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            notification.title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                                ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[700],
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (createdAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        dateFormat.format(createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'task_assigned':
        return Colors.blue;
      case 'request_approved':
      case 'day_off_approved':
      case 'leave_approved':
        return Colors.green;
      case 'request_rejected':
        return Colors.red;
      case 'overtime_added':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'task_assigned':
        return Icons.assignment;
      case 'request_approved':
      case 'day_off_approved':
      case 'leave_approved':
        return Icons.check_circle;
      case 'request_rejected':
        return Icons.cancel;
      case 'overtime_added':
        return Icons.access_time;
      default:
        return Icons.notifications;
    }
  }

  Future<void> _showNotificationDetails(
    BuildContext context,
    domain.Notification notification,
  ) async {
    final DateFormat dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    DateTime? createdAt;
    try {
      createdAt = DateTime.parse(notification.createdAt);
    } catch (e) {
      // Ignore parse errors
    }

    await showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Row(
          children: <Widget>[
            Icon(_getTypeIcon(notification.type), color: _getTypeColor(notification.type)),
            const SizedBox(width: 8),
            Expanded(child: Text(notification.title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(notification.message),
              if (createdAt != null) ...[
                const SizedBox(height: 16),
                Text(
                  createdAt != null ? dateFormat.format(createdAt) : notification.createdAt,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSendNotificationDialog(
    BuildContext context,
    NotificationController controller,
  ) async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController messageController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final bool? result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Send Notification',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title *'),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: messageController,
                decoration: const InputDecoration(labelText: 'Message *'),
                maxLines: 4,
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Message is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Obx(
                () => FilledButton(
                  onPressed: controller.isSending.value
                      ? null
                      : () async {
                          if (formKey.currentState?.validate() == true) {
                            final bool success = await controller.sendNotification(
                              title: titleController.text,
                              message: messageController.text,
                              sendToAll: true, // For now, send to all. Can be enhanced later
                            );
                            if (context.mounted) {
                              Navigator.of(context).pop(success);
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Notification sent successfully')),
                                );
                              }
                            }
                          }
                        },
                  child: controller.isSending.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send to All'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );

    if (result == true) {
      titleController.dispose();
      messageController.dispose();
    }
  }
}

