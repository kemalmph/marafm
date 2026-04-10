import 'package:supabase_flutter/supabase_flutter.dart';

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
