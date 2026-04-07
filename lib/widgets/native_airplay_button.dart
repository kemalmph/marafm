import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:output_route_selector/output_route_selector.dart';

class NativeAudioSelector extends StatelessWidget {
  final Widget? fallbackChild;

  const NativeAudioSelector({
    super.key,
    this.fallbackChild,
  });

  @override
  Widget build(BuildContext context) {
    final Widget buttonContent = fallbackChild ?? const Icon(LucideIcons.speaker, color: Colors.white, size: 18);
    
    // Use true native AVRoutePickerView on iOS via PlatformView
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          children: [
            // Base visual button
            Container(
              decoration: AppTheme.arcadeButtonDecoration(isPressed: false),
              child: Center(child: buttonContent),
            ),
            // Transparent overlay capturing taps to show the AirPlay sheet
            const Positioned.fill(
              child: IgnorePointer(
                ignoring: false,
                child: UiKitView(
                  viewType: 'native_airplay_button',
                  creationParams: <String, dynamic>{},
                  creationParamsCodec: StandardMessageCodec(),
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // Fallback to output_route_selector on Android (which correctly shows MediaRouter dialog)
    // or if we're on another platform
    if (kIsWeb) {
      return const SizedBox.shrink();
    }
    
    return AudioOutputSelector(
      child: SizedBox(
        width: 40,
        height: 40,
        child: DecoratedBox(
          decoration: AppTheme.arcadeButtonDecoration(isPressed: false),
          child: buttonContent,
        ),
      ),
    );
  }
}
