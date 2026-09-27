import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';

// Events
abstract class AuthEvent {}
class AuthCheckRequested extends AuthEvent {}
class AuthLoginRequested extends AuthEvent {
  final String email, password;
  AuthLoginRequested({required this.email, required this.password});
}
class AuthRegisterRequested extends AuthEvent {
  final String email, password, name;
  AuthRegisterRequested({required this.email, required this.password, required this.name});
}
class AuthGoogleLoginRequested extends AuthEvent {}
class AuthAppleLoginRequested extends AuthEvent {}
class AuthPasswordRecoveryDetected extends AuthEvent {}
class AuthForgotPasswordRequested extends AuthEvent {
  final String email;
  AuthForgotPasswordRequested(this.email);
}
class AuthSetNewPasswordRequested extends AuthEvent {
  final String newPassword;
  AuthSetNewPasswordRequested(this.newPassword);
}
class AuthChangePasswordRequested extends AuthEvent {
  final String newPassword;
  AuthChangePasswordRequested(this.newPassword);
}
class AuthLogoutRequested extends AuthEvent {}
class AuthDeleteAccountRequested extends AuthEvent {}
class AuthProfileUpdateRequested extends AuthEvent {
  final String? name, whatsappNumber, instagramUsername, twitterUsername;
  final String? gender, location, facebookUsername, tiktokUsername;
  final int? birthYear;

  AuthProfileUpdateRequested({
    this.name,
    this.whatsappNumber,
    this.instagramUsername,
    this.twitterUsername,
    this.gender,
    this.birthYear,
    this.location,
    this.facebookUsername,
    this.tiktokUsername,
  });
}

// States
abstract class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthForgotPasswordSent extends AuthState {}
class AuthPasswordRecovery extends AuthState {}
class AuthPasswordChanged extends AuthState {}
class AuthAuthenticated extends AuthState {
  final User user;
  final Map<String, dynamic>? profile;
  AuthAuthenticated({required this.user, this.profile});
}
class AuthUnauthenticated extends AuthState {}
class AuthAccountDeleted extends AuthUnauthenticated {}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService = AuthService.instance;
  StreamSubscription? _authSubscription;

  // Resolve synchronously from the persisted session so the UI never
  // flashes "please login" on cold start when the user is already logged in.
  static AuthState _resolveInitialState() {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      return AuthAuthenticated(user: session.user, profile: null);
    }
    return AuthUnauthenticated();
  }

  AuthBloc() : super(_resolveInitialState()) {
    on<AuthCheckRequested>(_onCheck);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthGoogleLoginRequested>(_onGoogleLogin);
    on<AuthAppleLoginRequested>(_onAppleLogin);
    on<AuthPasswordRecoveryDetected>((_, emit) => emit(AuthPasswordRecovery()));
    on<AuthForgotPasswordRequested>(_onForgotPassword);
    on<AuthSetNewPasswordRequested>(_onSetNewPassword);
    on<AuthChangePasswordRequested>(_onChangePassword);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthDeleteAccountRequested>(_onDeleteAccount);
    on<AuthProfileUpdateRequested>(_onUpdateProfile);

    _authSubscription = _authService.authStateChanges.listen((authState) {
      // The Google OAuth redirect does not dismiss the in-app browser sheet on its own.
      if (!kIsWeb && authState.event == AuthChangeEvent.signedIn) {
        closeInAppWebView();
      }
      add(AuthCheckRequested());
    });

    add(AuthCheckRequested());
  }

  Future<void> _onCheck(AuthCheckRequested event, Emitter<AuthState> emit) async {
    if (_authService.isLoggedIn) {
      final profile = await _authService.getProfile();
      emit(AuthAuthenticated(user: _authService.currentUser!, profile: profile));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await _authService.login(
        email: event.email,
        password: event.password,
      );
      if (response.user != null) {
        final profile = await _authService.getProfile();
        emit(AuthAuthenticated(user: response.user!, profile: profile));
      } else {
        emit(AuthError('Login failed. Please try again.'));
      }
    } on AuthException catch (e) {
      if (e.statusCode == '429') {
        emit(AuthError('Too many attempts. Please wait a moment and try again.'));
      } else if (e.message.toLowerCase().contains('invalid') || e.message.toLowerCase().contains('credentials')) {
        emit(AuthError('Wrong email or password.'));
      } else {
        emit(AuthError(e.message));
      }
    } catch (e) {
      emit(AuthError('Login error: ${e.runtimeType}: $e'));
    }
  }

  Future<void> _onRegister(AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await _authService.register(
        email: event.email,
        password: event.password,
        name: event.name,
      );
      if (response.user != null) {
        Map<String, dynamic>? profile;
        for (int i = 0; i < 3; i++) {
          await Future.delayed(const Duration(milliseconds: 600));
          profile = await _authService.getProfile();
          if (profile != null) break;
        }
        emit(AuthAuthenticated(user: response.user!, profile: profile));
      } else {
        emit(AuthError('Registration failed. Please try again.'));
      }
    } on AuthException catch (e) {
      if (e.statusCode == '429') {
        emit(AuthError('Too many attempts. Please wait a moment and try again.'));
      } else {
        emit(AuthError(e.message));
      }
    } catch (e) {
      emit(AuthError('Register error: ${e.runtimeType}: $e'));
    }
  }

  Future<void> _onGoogleLogin(AuthGoogleLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authService.signInWithGoogle();
    } catch (_) {}
    // The sign-in sheet returns immediately and has no dismiss callback, so reset the
    // form in case the user closes it; the auth listener emits AuthAuthenticated on success.
    if (!_authService.isLoggedIn) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAppleLogin(AuthAppleLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authService.signInWithApple();
      // Re-fetch so the profile reflects the name saved after sign-in.
      add(AuthCheckRequested());
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        emit(AuthUnauthenticated());
      } else {
        emit(AuthError('Apple sign-in failed: ${e.message}'));
      }
    } on AuthException catch (e) {
      emit(AuthError('Apple sign-in failed: ${e.message}'));
    } catch (e) {
      emit(AuthError('Apple sign-in failed. Please try again.'));
    }
  }

  Future<void> _onForgotPassword(AuthForgotPasswordRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authService.sendPasswordReset(event.email);
      emit(AuthForgotPasswordSent());
    } catch (e) {
      emit(AuthError('Could not send reset email. Please try again.'));
    }
  }

  Future<void> _onSetNewPassword(AuthSetNewPasswordRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authService.updatePassword(event.newPassword);
      emit(AuthPasswordChanged());
      add(AuthCheckRequested());
    } catch (e) {
      emit(AuthError('Could not update password. Please try again.'));
    }
  }

  Future<void> _onChangePassword(AuthChangePasswordRequested event, Emitter<AuthState> emit) async {
    try {
      await _authService.updatePassword(event.newPassword);
      emit(AuthPasswordChanged());
      add(AuthCheckRequested());
    } catch (e) {
      emit(AuthError('Could not update password. Please try again.'));
    }
  }

  Future<void> _onLogout(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await _authService.logout();
    emit(AuthUnauthenticated());
  }

  Future<void> _onDeleteAccount(AuthDeleteAccountRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authService.deleteAccount();
      emit(AuthAccountDeleted());
    } catch (e) {
      emit(AuthError('Could not delete account. Please try again.'));
    }
  }

  Future<void> _onUpdateProfile(AuthProfileUpdateRequested event, Emitter<AuthState> emit) async {
    await _authService.updateProfile(
      name: event.name,
      whatsappNumber: event.whatsappNumber,
      instagramUsername: event.instagramUsername,
      twitterUsername: event.twitterUsername,
      gender: event.gender,
      birthYear: event.birthYear,
      location: event.location,
      facebookUsername: event.facebookUsername,
      tiktokUsername: event.tiktokUsername,
    );
    add(AuthCheckRequested());
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
