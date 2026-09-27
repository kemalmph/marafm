import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _oauthRedirect = 'com.kemalhidayat.marafm://login-callback';
const _oauthRedirectWeb = 'https://marafm.com';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String name,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> sendPasswordReset(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'https://studio.marafm.com/auth/reset-password',
    );
  }

  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? _oauthRedirectWeb : _oauthRedirect,
      authScreenLaunchMode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.inAppBrowserView,
    );
  }

  Future<void> signInWithApple() async {
    final rawNonce = _client.auth.generateRawNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw const AuthException('Apple Sign-In failed: missing identity token.');
    }

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );

    // Apple only returns the name on the very first authorization, so persist it now.
    final fullName = [credential.givenName, credential.familyName]
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .join(' ');
    if (fullName.isNotEmpty) {
      await _client.auth.updateUser(UserAttributes(data: {'name': fullName}));
      await updateProfile(name: fullName);
    }
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }

  Future<void> updateProfile({
    String? name,
    String? whatsappNumber,
    String? instagramUsername,
    String? twitterUsername,
    String? gender,
    int? birthYear,
    String? location,
    String? facebookUsername,
    String? tiktokUsername,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (whatsappNumber != null) updates['whatsapp_number'] = whatsappNumber;
    if (instagramUsername != null) updates['instagram_username'] = instagramUsername;
    if (twitterUsername != null) updates['twitter_username'] = twitterUsername;
    if (gender != null) updates['gender'] = gender;
    if (birthYear != null) updates['birth_year'] = birthYear;
    if (location != null) updates['location'] = location;
    if (facebookUsername != null) updates['facebook_username'] = facebookUsername;
    if (tiktokUsername != null) updates['tiktok_username'] = tiktokUsername;

    if (updates.isNotEmpty) {
      await Supabase.instance.client
          .from('profiles')
          .update(updates)
          .eq('id', userId);
    }
  }

  Future<void> deleteAccount() async {
    if (currentUser == null) return;
    await _client.functions.invoke('delete-account');
    await logout();
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final userId = currentUser?.id;
    if (userId == null) return null;
    final response = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return response;
  }
}
