import 'package:supabase_flutter/supabase_flutter.dart';

class ListenerSessionService {
  ListenerSessionService._();
  static final ListenerSessionService instance = ListenerSessionService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  String? _sessionId;

  Future<void> startSession(String channelName, String channelType) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await _supabase.from('listener_sessions').insert({
        'user_id': user.id,
        'channel_name': channelName,
        'channel_type': channelType,
        'platform': 'flutter',
        'started_at': DateTime.now().toIso8601String(),
      }).select().single();

      _sessionId = response['id'] as String?;
    } catch (e) {
      // Return gracefully on error
    }
  }

  Future<void> endSession() async {
    if (_sessionId == null) return;

    try {
      await _supabase.from('listener_sessions').update({
        'ended_at': DateTime.now().toIso8601String(),
      }).eq('id', _sessionId!);
      
      _sessionId = null;
    } catch (e) {
      // Return gracefully on error
    }
  }

  Future<void> switchChannel(String newChannelName, String channelType) async {
    await endSession();
    await startSession(newChannelName, channelType);
  }
}
