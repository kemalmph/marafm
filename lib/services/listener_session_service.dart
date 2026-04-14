import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ListenerSessionService {
  ListenerSessionService._();
  static final ListenerSessionService instance = ListenerSessionService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  String? _sessionId;

  Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString('device_id');
    if (id == null) {
      id = 'device_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('device_id', id);
    }
    return id;
  }

  Future<void> startSession(String channelName, String channelType) async {
    try {
      final user = _supabase.auth.currentUser;
      final deviceId = await _getDeviceId();

      final response = await _supabase.from('listener_sessions').insert({
        'user_id': user?.id,        // null for anonymous users
        'channel_name': channelName,
        'channel_type': channelType,
        'platform': 'flutter',
        'device_id': deviceId,
        'is_anonymous': user == null,
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
