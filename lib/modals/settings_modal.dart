import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import 'liked_songs_modal.dart';
import '../widgets/tactile_container.dart';

class SettingsModal extends StatelessWidget {
  const SettingsModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: AppTheme.backgroundDarkGrey,
        border: Border(top: BorderSide(color: AppTheme.borderGrey, width: 8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Modal Header
          _buildHeader(context),
          
          // Modal Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProfileSection(context),
                  const SizedBox(height: 12),
                  _buildConnectSection(),
                  const SizedBox(height: 12),
                  _buildInfoSection('APP INFO', {
                    'VERSION': 'v1.0.8',
                    'DEVELOPER': 'INITIA',
                    'RELEASE': '2026',
                  }),
                  const SizedBox(height: 12),
                  _buildInfoSection('STATION', {
                    'NAME': 'MARA FM',
                    'FREQ': '106.7 FM',
                    'GENRE': 'HOT AC, POP, ROCK, SOUL',
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppTheme.cardGrey,
        border: Border(bottom: BorderSide(color: AppTheme.borderGrey, width: 4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'SETTINGS',
            style: AppTheme.retroStyle(fontSize: 14, color: AppTheme.accentOrange, fontWeight: FontWeight.bold),
          ),
          InkWell(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.accentOrange,
                border: Border.all(color: AppTheme.shadowOrange, width: 2),
              ),
              child: const Icon(LucideIcons.x, color: Colors.black, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return _buildSectionBox(
      'USER PROFILE',
      Column(
        children: [
          _buildInput('NAME', 'ENTER YOUR NAME'),
          const SizedBox(height: 8),
          _buildInput('EMAIL', 'ENTER YOUR EMAIL'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSectionButton('LOGIN', AppTheme.primaryTeal, Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSectionButton('REGISTER', AppTheme.accentOrange, Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TactileContainer(
            onTap: () {
              Navigator.pop(context); // Close settings
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const LikedSongsModal(),
              );
            },
            builder: (context, isPressed) => Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: AppTheme.controlButtonDecoration(
                color: AppTheme.borderGrey,
                isPressed: isPressed,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(LucideIcons.heart, color: AppTheme.accentOrange, size: 16),
                   const SizedBox(width: 8),
                   Text(
                    'LIKED SONGS',
                    style: AppTheme.retroStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectSection() {
    return _buildSectionBox(
      'CONNECT',
      Column(
        children: [
          _buildConnectButton('WHATSAPP', const Color(0xFF25D366)),
          const SizedBox(height: 8),
          _buildConnectButton('INSTAGRAM', const Color(0xFFE1306C)),
          const SizedBox(height: 8),
          _buildConnectButton('SPOTIFY', const Color(0xFF1DB954)),
          const SizedBox(height: 8),
          _buildConnectButton('APPLE MUSIC', const Color(0xFFFA243C)),
        ],
      ),
    );
  }

  Widget _buildSectionBox(String title, Widget content) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardGrey,
        border: Border.all(color: AppTheme.borderGrey, width: 4),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.retroStyle(fontSize: 12, color: AppTheme.primaryTeal, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildInput(String label, String placeholder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.retroStyle(fontSize: 11, color: AppTheme.accentOrange, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            border: Border.all(color: AppTheme.borderGrey, width: 2),
          ),
          child: Text(
            placeholder,
            style: AppTheme.bodyStyle(fontSize: 11, color: AppTheme.borderGrey),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionButton(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(
          color: bgColor == AppTheme.accentOrange ? AppTheme.shadowOrange : AppTheme.borderGrey,
          width: 4,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: AppTheme.retroStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildConnectButton(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.borderGrey,
        border: Border.all(color: AppTheme.cardGrey, width: 4),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.retroStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Icon(LucideIcons.link, color: color, size: 14),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, Map<String, String> info) {
    return _buildSectionBox(
      title,
      Column(
        children: info.entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                e.key,
                style: AppTheme.retroStyle(fontSize: 10, color: AppTheme.primaryTeal, fontWeight: FontWeight.bold),
              ),
              Text(
                e.value,
                style: AppTheme.bodyStyle(fontSize: 10, color: Colors.white),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }
}
