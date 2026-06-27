import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_models.dart';

class ChatService {
  static final _supabase = Supabase.instance.client;

  static Future<ChatConversation> getOrCreateConversation(
    String userId,
    String category,
  ) async {
    final existing = await _supabase
        .from('chat_conversations')
        .select()
        .eq('user_id', userId)
        .eq('category', category)
        .maybeSingle();

    if (existing != null) return ChatConversation.fromJson(existing);

    final created = await _supabase
        .from('chat_conversations')
        .insert({'user_id': userId, 'category': category})
        .select()
        .single();

    return ChatConversation.fromJson(created);
  }

  static Future<List<ChatMessage>> getMessages(String conversationId) async {
    final data = await _supabase
        .from('chat_messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return (data as List)
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> sendMessage(String conversationId, String body) async {
    await _supabase.from('chat_messages').insert({
      'conversation_id': conversationId,
      'sender_type': 'user',
      'body': body,
    });
  }

  static RealtimeChannel subscribeToMessages(
    String conversationId,
    void Function(ChatMessage) onMessage,
  ) {
    return _supabase
        .channel('chat:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: FilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) =>
              onMessage(ChatMessage.fromJson(payload.newRecord)),
        )
        .subscribe();
  }
}
