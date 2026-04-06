import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color Palette
  static const Color primaryTeal = Color(0xFF53A8B6);
  static const Color tealShadow = Color(0xFF3B7A82);
  static const Color tealHighlight = Color(0xFF7CC4D0);
  static const Color accentOrange = Color(0xFFFFA500);
  static const Color shadowOrange = Color(0xFFFF7700);
  static const Color highlightOrange = Color(0xFFFFCC66);
  static const Color backgroundDarkGrey = Color(0xFF4A4A4A);
  static const Color surfaceGrey = Color(0xFF5A5A5A);
  static const Color cardGrey = Color(0xFF2A2A2A);
  static const Color borderGrey = Color(0xFF3A3A3A);
  static const Color highlightGrey = Color(0xFF6A6A6A);
  static const Color shadowGrey = Color(0xFF1A1A1A);

  // Retro Shadows
  static const BoxShadow arcadeShadow = BoxShadow(
    color: shadowGrey,
    offset: Offset(4, 4),
    blurRadius: 0,
  );

  static const BoxShadow miniArcadeShadow = BoxShadow(
    color: shadowGrey,
    offset: Offset(2, 2),
    blurRadius: 0,
  );

  // Custom Decorations
  static BoxDecoration arcadeButtonDecoration({
    Color color = surfaceGrey,
    bool isPressed = false,
  }) {
    return BoxDecoration(
      color: color,
      border: Border.all(
        color: isPressed ? shadowGrey : highlightGrey,
        width: 4,
      ),
      boxShadow: isPressed ? [] : [arcadeShadow],
    );
  }

  static BoxDecoration controlButtonDecoration({
    required Color color,
    bool isActive = false,
    bool isPressed = false,
    Color? highlightColor,
    Color? shadowColor,
  }) {
    final finalHighlight = highlightColor ?? (color == primaryTeal ? tealHighlight : highlightOrange);
    final finalShadow = shadowColor ?? (color == primaryTeal ? tealShadow : shadowOrange);

    if (isPressed) {
      return BoxDecoration(
        color: color,
        border: Border(
          top: BorderSide(color: Colors.black.withValues(alpha: 0.3), width: 8),
          left: BorderSide(color: Colors.black.withValues(alpha: 0.1), width: 2),
          bottom: BorderSide(color: finalHighlight.withValues(alpha: 0.5), width: 2),
          right: BorderSide(color: finalHighlight.withValues(alpha: 0.5), width: 2),
        ),
      );
    }

    if (isActive) {
      return BoxDecoration(
        color: color,
        border: Border(
          top: BorderSide(color: finalHighlight, width: 2),
          left: BorderSide(color: finalHighlight, width: 2),
          bottom: BorderSide(color: finalShadow, width: 4),
          right: BorderSide(color: finalShadow, width: 2),
        ),
      );
    }
    return BoxDecoration(
      color: color,
      border: const Border(
        top: BorderSide(color: highlightGrey, width: 2),
        left: BorderSide(color: highlightGrey, width: 2),
        bottom: BorderSide(color: shadowGrey, width: 8),
        right: BorderSide(color: shadowGrey, width: 4),
      ),
      boxShadow: const [
        BoxShadow(
          color: shadowGrey,
          offset: Offset(0, 4),
          blurRadius: 0,
        ),
      ],
    );
  }

  static BoxDecoration screenDecoration = BoxDecoration(
    color: Colors.black,
    border: Border.all(
      color: borderGrey,
      width: 8,
    ),
    boxShadow: const [
      BoxShadow(
        color: Colors.black,
        offset: Offset(4, 4),
        blurRadius: 0,
      ),
    ],
  );

  // Theme Data
  static ThemeData get theme {
    final base = ThemeData.dark();
    
    return base.copyWith(
      scaffoldBackgroundColor: Colors.black,
      textTheme: GoogleFonts.pressStart2pTextTheme(base.textTheme).copyWith(
        bodyMedium: GoogleFonts.montserrat(
          textStyle: base.textTheme.bodyMedium,
          color: Colors.white,
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryTeal,
        secondary: accentOrange,
        surface: Colors.black,
      ),
    );
  }

  // Pixelated Text Style (Shortcut)
  static TextStyle retroStyle({
    double fontSize = 12,
    Color color = Colors.white,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return GoogleFonts.pressStart2p(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
    );
  }

  // Modern Body Style (Shortcut)
  static TextStyle bodyStyle({
    double fontSize = 14,
    Color color = Colors.white,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return GoogleFonts.montserrat(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
    );
  }
}
