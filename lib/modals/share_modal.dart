import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/tactile_container.dart';

class ShareModal extends StatefulWidget {
  final String songTitle;
  final String artist;

  const ShareModal({
    super.key,
    required this.songTitle,
    required this.artist,
  });

  @override
  State<ShareModal> createState() => _ShareModalState();
}

class _ShareModalState extends State<ShareModal> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final String initialMessage = "I love this song! Now playing on Mara FM: ${widget.songTitle.toUpperCase()} - ${widget.artist.toUpperCase()} https://mara.fm";
    _controller = TextEditingController(text: initialMessage);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDarkGrey,
        border: const Border(top: BorderSide(color: AppTheme.borderGrey, width: 8)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SHARE',
                  style: AppTheme.retroStyle(fontSize: 16, color: AppTheme.primaryTeal, fontWeight: FontWeight.bold),
                ),
                TactileContainer(
                  onTap: () => Navigator.pop(context),
                  builder: (context, isPressed) => Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.accentOrange,
                      border: Border.all(
                        color: isPressed ? AppTheme.shadowGrey : AppTheme.shadowOrange,
                        width: 2,
                      ),
                    ),
                    child: const Icon(LucideIcons.x, color: Colors.black, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Message Section
            Text(
              'MESSAGE',
              style: AppTheme.retroStyle(fontSize: 12, color: AppTheme.accentOrange, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                border: Border.all(color: AppTheme.borderGrey, width: 2),
              ),
              child: TextField(
                controller: _controller,
                maxLines: 5,
                style: AppTheme.retroStyle(fontSize: 11, color: Colors.white),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(12),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Share Via Section
            Text(
              'SHARE VIA',
              style: AppTheme.retroStyle(fontSize: 12, color: AppTheme.primaryTeal, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Small Social Buttons Row
            Row(
              children: [
                _buildSmallShareButton(
                  icon: LucideIcons.twitter,
                  color: const Color(0xFF1DA1F2),
                  onTap: () {},
                ),
                const SizedBox(width: 8),
                _buildSmallShareButton(
                  icon: LucideIcons.instagram,
                  color: const Color(0xFFE1306C),
                  onTap: () {},
                ),
                const SizedBox(width: 8),
                _buildSmallShareButton(
                  icon: LucideIcons.facebook,
                  color: const Color(0xFF4267B2),
                  onTap: () {},
                ),
                const SizedBox(width: 8),
                _buildSmallShareButton(
                  icon: LucideIcons.share2,
                  color: AppTheme.primaryTeal,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallShareButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: TactileContainer(
        onTap: onTap,
        builder: (context, isPressed) => Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: AppTheme.controlButtonDecoration(
            color: color,
            isPressed: isPressed,
            highlightColor: color.withValues(alpha: 0.8),
            shadowColor: color.withValues(alpha: 0.6),
          ),
          child: Center(
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}
