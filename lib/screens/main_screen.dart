import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/common/floating_nav_bar.dart';
import '../providers/post_provider.dart';
import '../providers/notification_provider.dart';
import 'home/home_screen.dart';
import 'post/create_post_screen.dart';
import 'notification/notification_screen.dart';
import 'profile/profile_screen.dart';
import 'profile/other_profile_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;
  final GlobalKey<ProfileScreenState> _profileKey = GlobalKey();
  final GlobalKey<NotificationScreenState> _notificationKey = GlobalKey();
  String? _viewingOtherUserId; // Track if viewing another user's profile

  @override
  void initState() {
    super.initState();
    // Load notification count when MainScreen is initialized (after login)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).loadUnreadCount();
    });
  }

  void _handleNavigation(int index) {
    // Jika tap di navbar yang sama, refresh data
    if (index == _currentIndex && _viewingOtherUserId == null) {
      if (index == 0) {
        // Refresh home
        ref.read(postsProvider.notifier).loadPosts();
      } else if (index == 2) {
        // Refresh notifications
        _notificationKey.currentState?.refreshData();
      } else if (index == 3) {
        // Refresh profile
        _profileKey.currentState?.refreshData();
      }
    } else {
      // When switching to notification tab, mark as read
      if (index == 2) {
        ref.read(notificationProvider.notifier).markAllAsRead();
      }

      setState(() {
        _currentIndex = index;
        _viewingOtherUserId = null; // Clear other user view when switching tabs
      });
    }
  }

  void _viewOtherProfile(String userId) {
    setState(() {
      _viewingOtherUserId = userId;
    });
  }

  void _closeOtherProfile() {
    setState(() {
      _viewingOtherUserId = null;
    });
  }

  void _goToOwnProfile() {
    setState(() {
      _currentIndex = 3; // Profile is now at index 3
      _viewingOtherUserId = null;
    });
  }

  void _goToHome() {
    setState(() {
      _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationProvider);

    // List of screens for navigation (now includes notification)
    final List<Widget> screens = [
      HomeScreenContent(
        onViewOtherProfile: _viewOtherProfile,
        onViewOwnProfile: _goToOwnProfile,
      ),
      CreatePostScreen(onPostSuccess: _goToHome),
      NotificationScreen(
        key: _notificationKey,
        onViewOtherProfile: _viewOtherProfile,
        onGoToProfile: _goToOwnProfile,
        showAppBar: false, // No app bar since it's embedded
      ),
      ProfileScreen(key: _profileKey),
    ];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _viewingOtherUserId != null
          ? OtherProfileScreen(
              userId: _viewingOtherUserId!,
              onBack: _closeOtherProfile,
              onViewOtherProfile: _viewOtherProfile,
            )
          : IndexedStack(index: _currentIndex, children: screens),
      floatingActionButton: FloatingNavBar(
        currentIndex: _viewingOtherUserId != null ? -1 : _currentIndex,
        onTap: _handleNavigation,
        notificationCount: notificationState.unreadCount,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
