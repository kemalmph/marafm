import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';

class HistoryModal extends StatelessWidget {
  const HistoryModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.cardGrey,
              border: Border.all(color: AppTheme.borderGrey, width: 8),
              boxShadow: const [AppTheme.arcadeShadow],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modal Header
                _buildHeader(context),
                
                // Modal Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RECENTLY PLAYED',
                          style: AppTheme.retroStyle(fontSize: 12, color: AppTheme.primaryTeal),
                        ),
                        const SizedBox(height: 12),
                        _buildHistoryItem('BLINDING LIGHTS', 'THE WEEKND', '5 MIN AGO'),
                        _buildHistoryItem('LEVITATING', 'DUA LIPA', '12 MIN AGO'),
                        _buildHistoryItem('SAVE YOUR TEARS', 'THE WEEKND', '20 MIN AGO'),
                        _buildHistoryItem('PEACHES', 'JUSTIN BIEBER', '35 MIN AGO'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: AppTheme.surfaceGrey,
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderGrey, width: 4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'HISTORY',
            style: AppTheme.retroStyle(fontSize: 12, color: AppTheme.accentOrange),
          ),
          InkWell(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.accentOrange,
                border: Border.all(color: const Color(0xFFFF7700), width: 2),
              ),
              child: const Icon(LucideIcons.x, color: Colors.black, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String title, String artist, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.borderGrey,
        border: Border.all(color: AppTheme.shadowGrey, width: 4),
        boxShadow: const [AppTheme.miniArcadeShadow],
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.music2, color: AppTheme.primaryTeal, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.retroStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  artist,
                  style: AppTheme.bodyStyle(fontSize: 11, color: AppTheme.primaryTeal),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: AppTheme.retroStyle(fontSize: 10, color: AppTheme.accentOrange),
          ),
        ],
      ),
    );
  }
}
