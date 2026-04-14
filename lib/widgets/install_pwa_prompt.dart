import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:js_interop';
import '../theme/app_theme.dart';

@JS('installPWA')
external JSPromise<JSBoolean> jsInstallPWA();

@JS('isPWAInstalled')
external bool jsIsPWAInstalled();

@JS('hasInstallPrompt')
external bool jsHasInstallPrompt();

class InstallPwaPrompt {
  static const String _storageKey = 'has_seen_install_prompt_v1';

  static Future<void> checkAndShow(BuildContext context) async {
    // Only proceed on Web
    if (!kIsWeb) return;

    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool(_storageKey) ?? false;

    if (hasSeen) return;

    // Check if already installed
    if (jsIsPWAInstalled()) return;

    final platform = defaultTargetPlatform;
    
    if (platform == TargetPlatform.iOS) {
      if (context.mounted) _showIosPrompt(context, prefs);
    } else if (platform == TargetPlatform.android) {
      // For Android, we only show if the browser actually has the prompt ready
      if (jsHasInstallPrompt()) {
        if (context.mounted) _showAndroidPrompt(context, prefs);
      } else {
        // Fallback for Android if the event hasn't fired yet - wait a bit or try later?
        // Usually it fires early. If it's missing, maybe it's already installed or unsupported.
      }
    }
  }

  static void _showIosPrompt(BuildContext context, SharedPreferences prefs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _PromptContainer(
        title: 'INSTALL APP',
        child: Column(
          children: [
            Text(
              "FOR THE BEST EXPERIENCE, INSTALL MARA FM TO YOUR HOME SCREEN.",
              textAlign: TextAlign.center,
              style: AppTheme.bodyStyle(fontSize: 11, color: Colors.white70),
            ),
            const SizedBox(height: 20),
            const _InstructionStep(
              number: "1",
              text: "TAP THE 'SHARE' ICON IN SAFARI BROWSER.",
              icon: LucideIcons.share,
            ),
            const _InstructionStep(
              number: "2",
              text: "SCROLL DOWN AND SELECT 'ADD TO HOME SCREEN'.",
              icon: LucideIcons.plusSquare,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: _RetroButton(
                label: "GOT IT",
                onPressed: () {
                  prefs.setBool(_storageKey, true);
                  Navigator.pop(context);
                },
              ),
            ),
            // Padding for safe area in bottom sheet
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  static void _showAndroidPrompt(BuildContext context, SharedPreferences prefs) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        backgroundColor: Colors.transparent,
        child: _PromptContainer(
          title: 'INSTALL APP',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "WOULD YOU LIKE TO INSTALL MARA FM AS AN APP FOR QUICK ACCESS?",
                textAlign: TextAlign.center,
                style: AppTheme.bodyStyle(fontSize: 11, color: Colors.white70),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _RetroButton(
                      label: "NOT NOW",
                      color: AppTheme.cardGrey,
                      textColor: AppTheme.primaryTeal,
                      borderColor: AppTheme.borderGrey,
                      onPressed: () {
                        prefs.setBool(_storageKey, true);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RetroButton(
                      label: "INSTALL",
                      color: AppTheme.accentOrange,
                      onPressed: () async {
                        try {
                          final success = await jsInstallPWA().toDart;
                          if (success.toDart) {
                            prefs.setBool(_storageKey, true);
                          }
                        } catch (e) {
                          debugPrint('PWA Install Error: $e');
                        }
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromptContainer extends StatelessWidget {
  final String title;
  final Widget child;

  const _PromptContainer({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardGrey,
        border: Border.all(color: AppTheme.borderGrey, width: 4),
        boxShadow: const [AppTheme.arcadeShadow],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: AppTheme.retroStyle(fontSize: 14, color: AppTheme.primaryTeal),
          ),
          const SizedBox(height: 8),
          const Divider(color: AppTheme.borderGrey, thickness: 2),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  final String number;
  final String text;
  final IconData icon;

  const _InstructionStep({required this.number, required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryTeal,
              border: Border.all(color: AppTheme.tealShadow, width: 2),
            ),
            child: Text(
              number,
              style: AppTheme.retroStyle(fontSize: 10, color: Colors.black),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTheme.bodyStyle(fontSize: 11, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, color: AppTheme.accentOrange, size: 20),
        ],
      ),
    );
  }
}

class _RetroButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final Color textColor;
  final Color? borderColor;

  const _RetroButton({
    required this.label,
    required this.onPressed,
    this.color = AppTheme.primaryTeal,
    this.textColor = Colors.black,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: borderColor ?? Colors.black, width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0),
          ],
        ),
        child: Center(
          child: Text(
            label.toUpperCase(),
            style: AppTheme.retroStyle(fontSize: 10, color: textColor),
          ),
        ),
      ),
    );
  }
}
