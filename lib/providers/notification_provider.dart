import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

final notificationServiceProvider = Provider((ref) => NotificationService());

// State class for notifications
class NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _service;

  NotificationNotifier(this._service) : super(NotificationState()) {
    _init();
  }

  Future<void> _init() async {
    await loadUnreadCount();
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final notifications = await _service.getNotifications();
      state = state.copyWith(notifications: notifications, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadUnreadCount() async {
    try {
      final count = await _service.getUnreadCount();
      state = state.copyWith(unreadCount: count);
    } catch (e) {
      // Ignore errors for unread count
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _service.markAllAsRead();
      // Update local state
      final updatedNotifications = state.notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      );
    } catch (e) {
      // Handle error
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _service.markAsRead(notificationId);
      // Update local state
      final updatedNotifications = state.notifications.map((n) {
        if (n.id == notificationId) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();

      final newUnreadCount = updatedNotifications
          .where((n) => !n.isRead)
          .length;
      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
      );
    } catch (e) {
      // Handle error
    }
  }

  // Called when user creates a follow/like/comment
  Future<void> createNotification({
    required String userId,
    required String actorId,
    required String type,
    String? postId,
    String? commentId,
  }) async {
    try {
      await _service.createNotification(
        userId: userId,
        actorId: actorId,
        type: type,
        postId: postId,
        commentId: commentId,
      );
    } catch (e) {
      // Ignore notification creation errors
    }
  }

  // Called when user unfollows/unlikes
  Future<void> deleteNotification({
    required String actorId,
    required String type,
    String? postId,
    String? commentId,
  }) async {
    try {
      await _service.deleteNotification(
        actorId: actorId,
        type: type,
        postId: postId,
        commentId: commentId,
      );
    } catch (e) {
      // Ignore notification deletion errors
    }
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
      final service = ref.watch(notificationServiceProvider);
      return NotificationNotifier(service);
    });
