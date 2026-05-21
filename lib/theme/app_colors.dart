import 'package:flutter/material.dart';

class AppColors {
  // Main app dashboard theme (Neo-brutalist high-contrast theme)
  static const Color background = Color(0xFFFFFDF5); // Warm Retro Cream
  static const Color cardBg = Color(0xFFFFFFFF);     // Solid White
  static const Color cardBgGlass = Color(0xCCFFFFFF); // White glass
  static const Color primary = Color(0xFF9DFF38);    // Bold Lime Green
  static const Color accent = Color(0xFF00FFCC);     // Vibrant Neo Cyan
  static const Color textPrimary = Color(0xFF000000); // Solid Black
  static const Color textSecondary = Color(0xFF333333); // Dark Charcoal
  static const Color border = Color(0xFF000000);     // Solid Black Border

  // Curated premium Neo-brutalist sticky note colors (highly saturated pop colors)
  static const Map<String, Color> stickyNoteColors = {
    'yellow': Color(0xFFFFE853),     // Vibrant Neo Yellow
    'pink': Color(0xFFFF85C2),       // Vibrant Bubblegum Pink
    'mint': Color(0xFF5EFFAD),       // Neon Mint
    'blue': Color(0xFF6BE5FF),       // Neon Sky Blue
    'lavender': Color(0xFFD69CFF),   // Neon Lavender
    'orange': Color(0xFFFF9D42),     // Vibrant Neon Orange
    'rose': Color(0xFFFF7A82),       // Vibrant Rose
    'purple': Color(0xFFA58EFF),     // Saturated Purple
    'teal': Color(0xFF42FFD2),       // Neon Teal
    'green': Color(0xFF88FF5E),      // Neon Green
    'lime': Color(0xFFD4FF5E),       // Neon Lime
    'cream': Color(0xFFFFF8BD),      // Neon Cream
    'amber': Color(0xFFFFCE3A),      // Saturated Amber
    'coral': Color(0xFFFF7A5E),      // Vibrant Coral
    'clay': Color(0xFFD9BBA9),       // Saturated Clay
    'grey': Color(0xFFC5D1D6),       // Saturated Cool Slate Grey
    'cotton': Color(0xFFFFC6FA),     // Cotton Candy Pink
    'sky': Color(0xFFB5FAFF),        // Ice Neo Sky
    'emerald': Color(0xFF8CFFB7),    // Neon Emerald
    'pistachio': Color(0xFFD4FFA6),  // Neon Pistachio
    'sand': Color(0xFFFFF2C2),       // Brutalist Sand
    'plum': Color(0xFFFFC0DB),       // Neon Plum
    'cocoa': Color(0xFFE5D5CD),      // Brutalist Cocoa
    'charcoal': Color(0xFF2B2F3A),   // Deep Charcoal (White Text)
    'indigo': Color(0xFF4856FF),     // Vibrant Indigo (White Text)
    'maroon': Color(0xFFFF5252),     // Saturated Red (White Text)
    'dark_mint': Color(0xFF00C292),  // Deep Teal (White Text)
    'glass': Color(0xFFE2E8F0),      // Slate Grey
  };

  // Convert Hex string name to Color
  static Color getStickyColor(String colorName) {
    return stickyNoteColors[colorName.toLowerCase()] ?? stickyNoteColors['yellow']!;
  }

  // Get matching text color for a sticky note (so contrast is perfect!)
  static Color getStickyTextColor(String colorName) {
    final name = colorName.toLowerCase();
    if (name == 'charcoal' || name == 'indigo' || name == 'maroon' || name == 'dark_mint') {
      return const Color(0xFFFFFFFF); // White text for dark notes
    }
    return const Color(0xFF000000); // Black text for brutalist flat cards
  }

  // Soft tint mapped from sticky note color
  static Color getEditorBgTint(String colorName, {double opacity = 0.08}) {
    final baseColor = getStickyColor(colorName);
    final name = colorName.toLowerCase();
    if (name == 'charcoal' || name == 'indigo' || name == 'maroon' || name == 'dark_mint') {
      return baseColor.withOpacity(0.4);
    }
    return baseColor.withOpacity(opacity);
  }

  // Get matching outline border color for cards and editors
  static Color getBorderColor(String colorName, {bool isDarkTheme = true}) {
    return border; // Always return solid black borders for Neo-brutalism!
  }

  // Soft ambient glow color (or flat backing color)
  static Color getGlowColor(String colorName) {
    return Colors.black.withOpacity(0.15); // Flat black backing shadow simulation
  }

  // List of colors for selection in Flutter toolbar
  static List<String> get availableColors => stickyNoteColors.keys.toList();
}
