import 'package:get/get.dart';

import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/mark_all_notifications_read_usecase.dart';
import '../../domain/usecases/mark_notification_read_usecase.dart';
import '../../domain/usecases/send_notification_usecase.dart';
import 'auth_controller.dart';

class NotificationController extends GetxController {
  NotificationController({
    required GetNotificationsUseCase getNotificationsUseCase,
    required MarkNotificationReadUseCase markNotificationReadUseCase,
    required MarkAllNotificationsReadUseCase markAllNotificationsReadUseCase,
    required SendNotificationUseCase sendNotificationUseCase,
  })  : _getNotificationsUseCase = getNotificationsUseCase,
        _markNotificationReadUseCase = markNotificationReadUseCase,
        _markAllNotificationsReadUseCase = markAllNotificationsReadUseCase,
        _sendNotificationUseCase = sendNotificationUseCase;

  final GetNotificationsUseCase _getNotificationsUseCase;
  final MarkNotificationReadUseCase _markNotificationReadUseCase;
  final MarkAllNotificationsReadUseCase _markAllNotificationsReadUseCase;
  final SendNotificationUseCase _sendNotificationUseCase;

  final RxList<Notification> notifications = <Notification>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isMarkingAsRead = false.obs;
  final RxBool isSending = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Only load notifications if user is authenticated
    final AuthController authController = Get.find<AuthController>();
    if (authController.isAuthenticated) {
      loadNotifications();
    }
  }

  Future<void> loadNotifications() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final NotificationListResponse result = await _getNotificationsUseCase();
      notifications.value = result.notifications;
      unreadCount.value = result.unreadCount;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      isMarkingAsRead.value = true;
      errorMessage.value = '';
      final Notification updated = await _markNotificationReadUseCase(notificationId);
      final int index = notifications.indexWhere((Notification n) => n.id == notificationId);
      if (index != -1) {
        notifications[index] = updated;
        if (unreadCount.value > 0) {
          unreadCount.value--;
        }
      }
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isMarkingAsRead.value = false;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      isMarkingAsRead.value = true;
      errorMessage.value = '';
      await _markAllNotificationsReadUseCase();
      // Update all notifications to read
      notifications.value = notifications.map((Notification n) {
        if (!n.isRead) {
          return Notification(
            id: n.id,
            userId: n.userId,
            type: n.type,
            title: n.title,
            message: n.message,
            relatedId: n.relatedId,
            isRead: true,
            createdAt: n.createdAt,
            updatedAt: n.updatedAt,
          );
        }
        return n;
      }).toList();
      unreadCount.value = 0;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isMarkingAsRead.value = false;
    }
  }

  Future<bool> sendNotification({
    required String title,
    required String message,
    String? type,
    int? userId,
    List<int>? userIds,
    bool? sendToAll,
  }) async {
    try {
      isSending.value = true;
      errorMessage.value = '';
      final int sentCount = await _sendNotificationUseCase(
        title: title,
        message: message,
        type: type,
        userId: userId,
        userIds: userIds,
        sendToAll: sendToAll,
      );
      return sentCount > 0;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isSending.value = false;
    }
  }
}

