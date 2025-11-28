import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

// Auth Service Provider
final authServiceProvider = Provider((ref) => AuthService());

// User Service Provider
final userServiceProvider = Provider((ref) => UserService());

// Auth State Provider
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// Current User Provider
final currentUserProvider = StreamProvider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => Stream.value(state.session?.user),
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

// Current User Profile Provider
final currentUserProfileProvider = FutureProvider<UserModel?>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return null;
  
  final userService = ref.watch(userServiceProvider);
  return await userService.getCurrentUserProfile();
});

// Auth Loading State
final authLoadingProvider = StateProvider<bool>((ref) => false);

// Auth Error State
final authErrorProvider = StateProvider<String?>((ref) => null);