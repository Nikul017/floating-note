import 'package:flutter/material.dart';

class AppColors {
  // Main app dashboard theme (Premium Slate-Emerald Theme)
  static const Color background = Color(0xFF0B0F19);
  static const Color cardBg = Color(0xFF131926);
  static const Color cardBgGlass = Color(0xCC131926);
  static const Color primary = Color(0xFF10B981); // Vibrant Emerald
  static const Color accent = Color(0xFF34D399);  // Mint/Seafoam Accent
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color border = Color(0xFF222B3E);

  // Curated premium pastel sticky note colors (Hex strings mapped to Flutter Colors)
  static const Map<String, Color> stickyNoteColors = {
    'yellow': Color(0xFFFFF59D),     // Soft warm yellow
    'pink': Color(0xFFF8BBD0),       // Gentle pink
    'mint': Color(0xFFC8E6C9),       // Soothing mint green
    'blue': Color(0xFFB3E5FC),       // Sky blue
    'lavender': Color(0xFFE1BEE7),   // Lavender
    'orange': Color(0xFFFFCC80),     // Soft orange
    'rose': Color(0xFFFFCDD2),       // Soft rose
    'purple': Color(0xFFD1C4E9),     // Soothing purple
    'teal': Color(0xFFB2DFDB),       // Pastel teal
    'green': Color(0xFFDCEDC8),      // Soft green
    'lime': Color(0xFFF0F4C3),       // Pastel lime
    'cream': Color(0xFFFFF9C4),      // Soft cream
    'amber': Color(0xFFFFE082),      // Sunset amber
    'coral': Color(0xFFFFAB91),      // Pastel coral
    'clay': Color(0xFFBCAAA4),       // Pastel clay
    'grey': Color(0xFFCFD8DC),       // Cool slate grey
    'cotton': Color(0xFFF3E5F5),     // Cotton candy
    'sky': Color(0xFFE0F7FA),        // Ice sky
    'emerald': Color(0xFFE8F5E9),    // Pale emerald
    'pistachio': Color(0xFFF1F8E9),  // Pistachio
    'sand': Color(0xFFFFF8E1),       // Desert sand
    'plum': Color(0xFFFCE4EC),       // Plum blossom
    'cocoa': Color(0xFFEFEBE9),      // Warm cocoa
    'charcoal': Color(0xFF263238),   // Dark charcoal
    'indigo': Color(0xFF1A237E),     // Royal indigo
    'maroon': Color(0xFF3E2723),     // Dark coffee
    'dark_mint': Color(0xFF004D40),  // Dark teal
    'glass': Color(0xCC1A1A24),      // Glassmorphic dark
  };

  // Convert Hex string name to Color
  static Color getStickyColor(String colorName) {
    return stickyNoteColors[colorName.toLowerCase()] ?? stickyNoteColors['yellow']!;
  }

  // Get matching text color for a sticky note (so contrast is perfect!)
  static Color getStickyTextColor(String colorName) {
    final name = colorName.toLowerCase();
    if (name == 'charcoal' || name == 'glass' || name == 'indigo' || name == 'maroon' || name == 'dark_mint') {
      return const Color(0xFFECEFF1); // Light text for dark notes
    }
    return const Color(0xFF263238); // Dark text for pastel notes
  }

  // Soft dark-theme card background tint mapped from sticky note color
  static Color getEditorBgTint(String colorName, {double opacity = 0.08}) {
    final baseColor = getStickyColor(colorName);
    final name = colorName.toLowerCase();
    if (name == 'charcoal' || name == 'glass' || name == 'indigo' || name == 'maroon' || name == 'dark_mint') {
      return baseColor.withOpacity(0.4); // Dark notes are already dark, give them higher opacity
    }
    return baseColor.withOpacity(opacity);
  }

  // Get matching outline border color for cards and editors
  static Color getBorderColor(String colorName, {bool isDarkTheme = true}) {
    final baseColor = getStickyColor(colorName);
    final name = colorName.toLowerCase();
    if (name == 'charcoal' || name == 'glass' || name == 'indigo' || name == 'maroon' || name == 'dark_mint') {
      return border;
    }
    return baseColor.withOpacity(isDarkTheme ? 0.3 : 0.6);
  }

  // Soft ambient glow color
  static Color getGlowColor(String colorName) {
    return getStickyColor(colorName).withOpacity(0.18);
  }

  // List of colors for selection in Flutter toolbar
  static List<String> get availableColors => stickyNoteColors.keys.toList();
}
