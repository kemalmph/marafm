import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TactileContainer extends StatefulWidget {
  final Widget Function(BuildContext context, bool isPressed) builder;
  final VoidCallback onTap;

  const TactileContainer({super.key, required this.builder, required this.onTap});

  @override
  State<TactileContainer> createState() => _TactileContainerState();
}

class _TactileContainerState extends State<TactileContainer> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: widget.builder(context, _isPressed),
    );
  }
}
