import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/services/local_storage_service.dart';

class AuthState {
  const AuthState({
    required this.isLoading,
    required this.isAuthenticated,
    this.userId,
    this.userEmail,
    this.userName,
    this.errorMessage,
  });

  final bool isLoading;
  final bool isAuthenticated;
  final String? userId;
  final String? userEmail;
  final String? userName;
  final String? errorMessage;

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? userId,
    String? userEmail,
    String? userName,
    String? errorMessage,
    bool clearError = false,
    bool clearUserData = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: clearUserData ? null : (userId ?? this.userId),
      userEmail: clearUserData ? null : (userEmail ?? this.userEmail),
      userName: clearUserData ? null : (userName ?? this.userName),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  factory AuthState.initial() {
    return const AuthState(isLoading: true, isAuthenticated: false);
  }
}

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._auth, this._storage) : super(AuthState.initial()) {
    _subscription = _auth.authStateChanges().listen((user) {
      _onAuthChanged(user);
    });
  }

  final FirebaseAuth _auth;
  final LocalStorageService _storage;
  late final StreamSubscription<User?> _subscription;
  static const _googleWebClientId =
      '1057466850338-5mlsf7flt0nd33tl0i9e4622i8c0q9pl.apps.googleusercontent.com';
  GoogleSignIn get _googleSignIn =>
      GoogleSignIn(serverClientId: _googleWebClientId);

  String _profileFileName(String uid) => 'user_profile_${_safeFileKey(uid)}.json';

  String _safeFileKey(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
  }

  void _onAuthChanged(User? user) {
    final resolvedName = _resolveUserName(user);
    state = state.copyWith(
      isLoading: false,
      isAuthenticated: user != null,
      userId: user?.uid,
      userEmail: user?.email,
      userName: resolvedName,
      clearUserData: user == null,
      clearError: true,
    );

    final uid = user?.uid;
    if (uid != null) {
      unawaited(_applySavedName(uid));
    }
  }

  Future<void> _applySavedName(String uid) async {
    try {
      final profile = await _storage.readJsonObject(_profileFileName(uid));
      final savedName = profile['displayName'];
      if (state.userId != uid || savedName is! String) {
        return;
      }

      final trimmed = savedName.trim();
      if (trimmed.isEmpty) {
        return;
      }

      state = state.copyWith(userName: trimmed);
    } catch (_) {
      // Keep auth flow resilient if local storage is unavailable.
    }
  }

  bool updateDisplayName(String name) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      state = state.copyWith(errorMessage: 'No active user found.');
      return false;
    }

    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(errorMessage: 'Name cannot be empty.');
      return false;
    }

    state = state.copyWith(userName: trimmed, clearError: true);
    unawaited(_persistDisplayName(uid, trimmed));
    return true;
  }

  Future<void> _persistDisplayName(String uid, String name) async {
    try {
      await _storage.writeJsonObject(_profileFileName(uid), {
        'displayName': name,
      });
    } catch (_) {
      // Keep UI responsive; persistence failure should not block editing.
    }
  }

  String? _resolveUserName(User? user) {
    if (user == null) {
      return null;
    }

    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName.split(RegExp(r'\s+')).first;
    }

    final email = user.email?.trim();
    if (email == null || email.isEmpty) {
      return null;
    }

    final localPart = email.split('@').first;
    final segments = localPart.split(RegExp(r'[._-]+'));
    final base = segments.firstWhere(
      (segment) => segment.trim().isNotEmpty,
      orElse: () => localPart,
    );

    if (base.isEmpty) {
      return null;
    }

    return '${base[0].toUpperCase()}${base.substring(1).toLowerCase()}';
  }

  Future<bool> signUp({required String email, required String password}) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      state = state.copyWith(errorMessage: 'Email and password are required.');
      return false;
    }

    try {
      await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(errorMessage: _mapAuthError(e));
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(errorMessage: _mapAuthError(e));
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        await _auth.signInWithPopup(GoogleAuthProvider());
        return true;
      }

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        state = state.copyWith(
          errorMessage: 'Google sign-in was cancelled.',
        );
        return false;
      }

      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) {
        state = state.copyWith(
          errorMessage:
              'Google sign-in config is incomplete (missing ID token).',
        );
        return false;
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(errorMessage: _mapAuthError(e));
      return false;
    } on PlatformException catch (e) {
      final message = (e.message ?? '').toLowerCase();
      if (message.contains('apiexception: 10')) {
        state = state.copyWith(
          errorMessage:
              'Google sign-in config error (SHA/package mismatch). Check Firebase fingerprints.',
        );
      } else {
        state = state.copyWith(
          errorMessage: e.message ?? 'Google sign-in failed.',
        );
      }
      return false;
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'Google sign-in failed. Please try again.',
      );
      return false;
    }
  }

  Future<void> signOut() async {
    final user = _auth.currentUser;
    final isGoogleUser =
        user?.providerData.any((p) => p.providerId == 'google.com') ?? false;

    try {
      await _auth.signOut();
    } catch (_) {
      // Keep sign-out path non-fatal for UI; auth stream still governs state.
    }

    if (!kIsWeb && isGoogleUser) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // Ignore Google plugin sign-out edge cases on some emulators/devices.
      }
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String _mapAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'Email already registered.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return error.message ?? 'Authentication failed.';
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final storage = ref.watch(localStorageProvider);
  return AuthNotifier(auth, storage);
});
