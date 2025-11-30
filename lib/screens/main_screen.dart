import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/common/floating_nav_bar.dart';
import '../providers/post_provider.dart';
import 'home/home_screen.dart';
import 'post/create_post_screen.dart';
import 'profile/profile_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;
  final GlobalKey<ProfileScreenState> _profileKey = GlobalKey();

  void _handleNavigation(int index) {
    // Jika tap di navbar yang sama, refresh data
    if (index == _currentIndex) {
      if (index == 0) {
        // Refresh home
        ref.read(postsProvider.notifier).loadPosts();
      } else if (index == 2) {
        // Refresh profile
        _profileKey.currentState?.refreshData();
      }
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _goToHome() {
    setState(() {
      _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    // List of screens for navigation
    final List<Widget> screens = [
      const HomeScreenContent(),
      CreatePostScreen(onPostSuccess: _goToHome),
      ProfileScreen(key: _profileKey),
    ];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: IndexedStack(index: _currentIndex, children: screens),
      floatingActionButton: FloatingNavBar(
        currentIndex: _currentIndex,
        onTap: _handleNavigation,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
