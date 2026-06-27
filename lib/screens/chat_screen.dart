import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/chat_models.dart';
import '../services/chat_service.dart';

const _categories = [
  {'key': 'request', 'label': 'Request Lagu', 'emoji': '🎵', 'desc': 'Minta lagu favorit kamu'},
  {'key': 'salam', 'label': 'Kirim Salam', 'emoji': '👋', 'desc': 'Sapa seseorang di udara'},
  {'key': 'kuis', 'label': 'Ikut Kuis', 'emoji': '🏆', 'desc': 'Jawab kuis & menangkan hadiah'},
  {'key': 'general', 'label': 'Chat', 'emoji': '💬', 'desc': 'Ngobrol sama studio'},
];

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDarkGrey,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceGrey,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'CHAT STUDIO',
          style: AppTheme.retroStyle(fontSize: 10, color: AppTheme.accentOrange),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(height: 4, color: AppTheme.highlightGrey),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          return _CategoryTile(
            emoji: cat['emoji']!,
            label: cat['label']!,
            desc: cat['desc']!,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _ChatThreadScreen(category: cat['key']!),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryTile extends StatefulWidget {
  final String emoji, label, desc;
  final VoidCallback onTap;
  const _CategoryTile({
    required this.emoji,
    required this.label,
    required this.desc,
    required this.onTap,
  });

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardGrey,
          border: Border(
            top: BorderSide(
              color: _pressed ? AppTheme.shadowGrey : AppTheme.highlightGrey,
              width: 2,
            ),
            left: BorderSide(
              color: _pressed ? AppTheme.shadowGrey : AppTheme.highlightGrey,
              width: 2,
            ),
            bottom: BorderSide(
              color: _pressed ? AppTheme.highlightGrey : AppTheme.shadowGrey,
              width: _pressed ? 2 : 6,
            ),
            right: BorderSide(
              color: _pressed ? AppTheme.highlightGrey : AppTheme.shadowGrey,
              width: _pressed ? 2 : 4,
            ),
          ),
        ),
        child: Row(
          children: [
            Text(widget.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: AppTheme.retroStyle(
                      fontSize: 9,
                      color: AppTheme.accentOrange,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.desc,
                    style: AppTheme.bodyStyle(
                      fontSize: 12,
                      color: AppTheme.primaryTeal,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.borderGrey, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Message thread screen
// ─────────────────────────────────────────────

class _ChatThreadScreen extends StatefulWidget {
  final String category;
  const _ChatThreadScreen({required this.category});

  @override
  State<_ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<_ChatThreadScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _supabase = Supabase.instance.client;

  ChatConversation? _conversation;
  List<ChatMessage> _messages = [];
  RealtimeChannel? _channel;
  bool _loading = true;
  bool _sending = false;
  String? _error;

  String get _categoryLabel {
    final cat = _categories.firstWhere((c) => c['key'] == widget.category);
    return '${cat['emoji']} ${cat['label']}';
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        _error = 'Kamu perlu login dulu untuk chat.';
        _loading = false;
      });
      return;
    }

    try {
      final conv = await ChatService.getOrCreateConversation(
        user.id,
        widget.category,
      );
      final msgs = await ChatService.getMessages(conv.id);

      if (!mounted) return;
      setState(() {
        _conversation = conv;
        _messages = msgs;
        _loading = false;
      });
      _subscribeRealtime(conv.id);
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat chat. Coba lagi.';
        _loading = false;
      });
    }
  }

  void _subscribeRealtime(String conversationId) {
    _channel = ChatService.subscribeToMessages(conversationId, (msg) {
      if (!mounted) return;
      setState(() => _messages.add(msg));
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _conversation == null || _sending) return;

    setState(() => _sending = true);
    _controller.clear();
    HapticFeedback.lightImpact();

    try {
      await ChatService.sendMessage(_conversation!.id, body);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim pesan, coba lagi.')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDarkGrey,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceGrey,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _categoryLabel,
          style: AppTheme.bodyStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(height: 4, color: AppTheme.highlightGrey),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessages()),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accentOrange),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: AppTheme.bodyStyle(color: AppTheme.primaryTeal),
          ),
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline, color: AppTheme.borderGrey, size: 40),
            const SizedBox(height: 12),
            Text(
              'Mulai percakapan\ndengan Mara FM Studio!',
              textAlign: TextAlign.center,
              style: AppTheme.bodyStyle(color: AppTheme.primaryTeal, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final prev = index > 0 ? _messages[index - 1] : null;
        final showTime = prev == null ||
            msg.createdAt.difference(prev.createdAt).inMinutes > 10;
        return _MessageBubble(
          message: msg,
          showTime: showTime,
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0
            ? 8
            : MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.cardGrey,
        border: Border(top: BorderSide(color: AppTheme.borderGrey, width: 2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: AppTheme.bodyStyle(fontSize: 14),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Ketik pesan...',
                hintStyle: AppTheme.bodyStyle(
                  fontSize: 13,
                  color: AppTheme.borderGrey,
                ),
                filled: true,
                fillColor: AppTheme.surfaceGrey,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: const BorderSide(color: AppTheme.borderGrey, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: const BorderSide(color: AppTheme.borderGrey, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: const BorderSide(color: AppTheme.accentOrange, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sending ? null : _send,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _sending ? AppTheme.borderGrey : AppTheme.accentOrange,
                border: Border.all(
                  color: _sending ? AppTheme.shadowGrey : AppTheme.shadowOrange,
                  width: 3,
                ),
              ),
              child: _sending
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryTeal,
                        ),
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.black, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showTime;

  const _MessageBubble({required this.message, required this.showTime});

  @override
  Widget build(BuildContext context) {
    final isStudio = message.isFromStudio;
    final timeStr = DateFormat('HH:mm').format(message.createdAt.toLocal());

    return Column(
      crossAxisAlignment:
          isStudio ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        if (showTime)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Text(
                DateFormat('dd MMM HH:mm').format(message.createdAt.toLocal()),
                style: AppTheme.bodyStyle(
                  fontSize: 10,
                  color: AppTheme.borderGrey,
                ),
              ),
            ),
          ),
        Row(
          mainAxisAlignment:
              isStudio ? MainAxisAlignment.start : MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isStudio) ...[
              Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(right: 6, bottom: 2),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryTeal,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    'M',
                    style: AppTheme.retroStyle(
                      fontSize: 9,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
            Flexible(
              child: Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isStudio ? AppTheme.surfaceGrey : AppTheme.accentOrange,
                  border: Border.all(
                    color: isStudio
                        ? AppTheme.borderGrey
                        : AppTheme.shadowOrange,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      message.body,
                      style: AppTheme.bodyStyle(
                        fontSize: 13,
                        color: isStudio ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeStr,
                      style: AppTheme.bodyStyle(
                        fontSize: 10,
                        color: isStudio
                            ? AppTheme.borderGrey
                            : AppTheme.shadowOrange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
