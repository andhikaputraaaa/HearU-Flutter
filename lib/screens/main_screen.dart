import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/common/floating_nav_bar.dart';
import '../providers/post_provider.dart';
import '../providers/notification_provider.dart';
import 'home/home_screen.dart';
import 'post/create_post_screen.dart';
import 'search/search_screen.dart';
import 'notification/notification_screen.dart';
import 'member/member_screen.dart';
import 'profile/profile_screen.dart';
import 'profile/other_profile_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  final GlobalKey<ProfileScreenState> _profileKey = GlobalKey();
  final GlobalKey<NotificationScreenState> _notificationKey = GlobalKey();
  String? _viewingOtherUserId; // Track if viewing another user's profile
  DateTime? _lastBackPressed; // For double-tap to exit

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Load notification count when MainScreen is initialized (after login)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).loadUnreadCount();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reset last back pressed when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _lastBackPressed = null;
    }
  }

  void _handleNavigation(int index) {
    // Jika tap di navbar yang sama, refresh data
    if (index == _currentIndex && _viewingOtherUserId == null) {
      if (index == 0) {
        // Refresh home
        ref.read(postsProvider.notifier).loadPosts();
      } else if (index == 3) {
        // Refresh notifications
        _notificationKey.currentState?.refreshData();
      } else if (index == 4) {
        // Refresh member (no action needed yet)
      } else if (index == 5) {
        // Refresh profile
        _profileKey.currentState?.refreshData();
      }
    } else {
      // When switching to notification tab, mark as read
      if (index == 3) {
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
      _currentIndex = 5; // Profile is now at index 5
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

    // List of screens for navigation (now includes search)
    final List<Widget> screens = [
      HomeScreenContent(
        onViewOtherProfile: _viewOtherProfile,
        onViewOwnProfile: _goToOwnProfile,
      ),
      SearchScreen(
        onViewOtherProfile: _viewOtherProfile,
        onGoToProfile: _goToOwnProfile,
      ),
      CreatePostScreen(onPostSuccess: _goToHome),
      NotificationScreen(
        key: _notificationKey,
        onViewOtherProfile: _viewOtherProfile,
        onGoToProfile: _goToOwnProfile,
        showAppBar: false, // No app bar since it's embedded
      ),
      const MemberScreen(),
      ProfileScreen(key: _profileKey),
    ];

    return WillPopScope(
      onWillPop: () async {
        // If viewing other profile, go back to previous screen (single back)
        if (_viewingOtherUserId != null) {
          _closeOtherProfile();
          return false;
        }

        // If we're in navbar screens (any tab), require double-tap to exit
        // Reset timer when switching tabs
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
            _lastBackPressed = null; // Reset timer when going to home
          });
          return false;
        }

        // We're on home screen (index 0) - require double-tap to exit app
        final now = DateTime.now();
        if (_lastBackPressed == null ||
            now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
          // First press or expired - show confirmation
          _lastBackPressed = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tekan sekali lagi untuk keluar'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return false;
        }
        // Second press within 2 seconds - allow exit
        return true;
      },
      child: Scaffold(
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
      ),
    );
  }
}
