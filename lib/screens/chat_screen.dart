import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/chat_models.dart';
import '../services/chat_service.dart';

// Only two entry points exposed to users
const _categories = [
  {'key': 'general', 'label': 'Chat', 'emoji': '💬', 'desc': 'Talk to the studio'},
  {'key': 'request', 'label': 'Song Request', 'emoji': '🎵', 'desc': 'Request your favorite song'},
];

// ─────────────────────────────────────────────
// Entry: category picker
// ─────────────────────────────────────────────

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
          'STUDIO CHAT',
          style: AppTheme.retroStyle(fontSize: 12, color: AppTheme.accentOrange),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(height: 4, color: AppTheme.highlightGrey),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          return _CategoryTile(
            emoji: cat['emoji']!,
            label: cat['label']!,
            desc: cat['desc']!,
            onTap: () {
              if (cat['key'] == 'request') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const _RequestFormScreen(),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _ChatThreadScreen(category: cat['key']!),
                  ),
                );
              }
            },
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardGrey,
          border: Border(
            top: BorderSide(color: _pressed ? AppTheme.shadowGrey : AppTheme.highlightGrey, width: 2),
            left: BorderSide(color: _pressed ? AppTheme.shadowGrey : AppTheme.highlightGrey, width: 2),
            bottom: BorderSide(color: _pressed ? AppTheme.highlightGrey : AppTheme.shadowGrey, width: _pressed ? 2 : 6),
            right: BorderSide(color: _pressed ? AppTheme.highlightGrey : AppTheme.shadowGrey, width: _pressed ? 2 : 4),
          ),
        ),
        child: Row(
          children: [
            Text(widget.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: AppTheme.retroStyle(fontSize: 11, color: AppTheme.accentOrange),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.desc,
                    style: AppTheme.bodyStyle(fontSize: 14, color: AppTheme.primaryTeal),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.borderGrey, size: 24),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Request lagu form screen
// ─────────────────────────────────────────────

class _RequestFormScreen extends StatefulWidget {
  const _RequestFormScreen();

  @override
  State<_RequestFormScreen> createState() => _RequestFormScreenState();
}

class _RequestFormScreenState extends State<_RequestFormScreen> {
  final _judul = TextEditingController();
  final _penyanyi = TextEditingController();
  final _untuk = TextEditingController();
  final _pesan = TextEditingController();
  final _supabase = Supabase.instance.client;
  bool _sending = false;

  Future<void> _submit() async {
    if (_judul.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Song title is required.')),
      );
      return;
    }

    setState(() => _sending = true);
    HapticFeedback.mediumImpact();

    final user = _supabase.auth.currentUser;
    if (user == null) {
      setState(() => _sending = false);
      return;
    }

    final body = [
      '🎵 Request: ${_judul.text.trim()}',
      if (_penyanyi.text.trim().isNotEmpty) '🎤 Penyanyi: ${_penyanyi.text.trim()}',
      if (_untuk.text.trim().isNotEmpty) '👤 Untuk: ${_untuk.text.trim()}',
      if (_pesan.text.trim().isNotEmpty) '💬 ${_pesan.text.trim()}',
    ].join('\n');

    try {
      final conv = await ChatService.getOrCreateConversation(user.id, 'request');
      await ChatService.sendMessage(conv.id, body);
      if (!mounted) return;
      // Go directly to the thread after submitting
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const _ChatThreadScreen(category: 'request'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send request. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _judul.dispose();
    _penyanyi.dispose();
    _untuk.dispose();
    _pesan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDarkGrey,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceGrey,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '🎵 SONG REQUEST',
          style: AppTheme.retroStyle(fontSize: 11, color: AppTheme.accentOrange),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(height: 4, color: AppTheme.highlightGrey),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildField('Song Title *', _judul, hint: 'e.g. Tulus - Hati-Hati di Jalan'),
              const SizedBox(height: 16),
              _buildField('Artist', _penyanyi, hint: 'e.g. Tulus'),
              const SizedBox(height: 16),
              _buildField('Dedicated To', _untuk, hint: 'e.g. For Dinda in Cimahi'),
              const SizedBox(height: 16),
              _buildField('Message', _pesan, hint: 'Your message or greeting...', maxLines: 3),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: _sending ? null : _submit,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _sending ? AppTheme.borderGrey : AppTheme.accentOrange,
                    border: Border.all(
                      color: _sending ? AppTheme.shadowGrey : AppTheme.shadowOrange,
                      width: 3,
                    ),
                    boxShadow: _sending
                        ? []
                        : const [BoxShadow(color: AppTheme.shadowOrange, offset: Offset(0, 4), blurRadius: 0)],
                  ),
                  child: _sending
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryTeal),
                          ),
                        )
                      : Text(
                          'SEND REQUEST',
                          textAlign: TextAlign.center,
                          style: AppTheme.retroStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, {String hint = '', int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodyStyle(fontSize: 13, color: AppTheme.primaryTeal, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          style: AppTheme.bodyStyle(fontSize: 15, color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTheme.bodyStyle(fontSize: 14, color: AppTheme.borderGrey),
            filled: true,
            fillColor: AppTheme.cardGrey,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppTheme.borderGrey, width: 2),
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppTheme.borderGrey, width: 2),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppTheme.accentOrange, width: 2),
            ),
          ),
        ),
      ],
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

  String get _categoryLabel => widget.category == 'request' ? '🎵 Request Lagu' : '💬 Chat';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      setState(() { _error = 'You need to log in to chat.'; _loading = false; });
      return;
    }
    try {
      final conv = await ChatService.getOrCreateConversation(user.id, widget.category);
      final msgs = await ChatService.getMessages(conv.id);
      if (!mounted) return;
      setState(() { _conversation = conv; _messages = msgs; _loading = false; });
      _subscribeRealtime(conv.id);
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'Failed to load chat. Please try again.'; _loading = false; });
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
        const SnackBar(content: Text('Failed to send message. Please try again.')),
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
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceGrey,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _categoryLabel,
          style: AppTheme.bodyStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
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
      return const Center(child: CircularProgressIndicator(color: AppTheme.accentOrange));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center, style: AppTheme.bodyStyle(color: AppTheme.primaryTeal, fontSize: 15)),
        ),
      );
    }
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline, color: AppTheme.borderGrey, size: 44),
            const SizedBox(height: 14),
            Text(
              'Start a conversation\nwith Mara FM Studio!',
              textAlign: TextAlign.center,
              style: AppTheme.bodyStyle(color: AppTheme.primaryTeal, fontSize: 15),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final prev = index > 0 ? _messages[index - 1] : null;
        final showTime = prev == null || msg.createdAt.difference(prev.createdAt).inMinutes > 10;
        return _MessageBubble(message: msg, showTime: showTime);
      },
    );
  }

  Widget _buildInputBar() {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: bottomInset > 0 ? bottomInset + 8 : 20,
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
              style: AppTheme.bodyStyle(fontSize: 15),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: AppTheme.bodyStyle(fontSize: 14, color: AppTheme.borderGrey),
                filled: true,
                fillColor: AppTheme.surfaceGrey,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppTheme.borderGrey, width: 2),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppTheme.borderGrey, width: 2),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppTheme.accentOrange, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sending ? null : _send,
            child: Container(
              width: 48,
              height: 48,
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
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryTeal),
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.black, size: 20),
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
      crossAxisAlignment: isStudio ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        if (showTime)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                DateFormat('dd MMM HH:mm').format(message.createdAt.toLocal()),
                style: AppTheme.bodyStyle(fontSize: 11, color: AppTheme.borderGrey),
              ),
            ),
          ),
        Row(
          mainAxisAlignment: isStudio ? MainAxisAlignment.start : MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isStudio) ...[
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 8, bottom: 2),
                decoration: const BoxDecoration(color: AppTheme.primaryTeal, shape: BoxShape.circle),
                child: Center(
                  child: Text('M', style: AppTheme.retroStyle(fontSize: 10, color: Colors.black)),
                ),
              ),
            ],
            Flexible(
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isStudio ? AppTheme.surfaceGrey : AppTheme.accentOrange,
                  border: Border.all(
                    color: isStudio ? AppTheme.borderGrey : AppTheme.shadowOrange,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      message.body,
                      style: AppTheme.bodyStyle(fontSize: 15, color: isStudio ? Colors.white : Colors.black),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeStr,
                      style: AppTheme.bodyStyle(
                        fontSize: 11,
                        color: isStudio ? AppTheme.borderGrey : AppTheme.shadowOrange,
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
