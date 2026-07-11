import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentThemeConfig {
  final String id;
  final String name;
  final Color primary;
  final Color gradientEnd;
  final Color highlight;
  final Color background;
  final Color cardBackground;
  final Color textPrimary;
  final Color textSecondary;
  final Color dividerColor;

  const StudentThemeConfig({
    required this.id,
    required this.name,
    required this.primary,
    required this.gradientEnd,
    required this.highlight,
    this.background = const Color(0xFFF9FAFB), // grey[50]
    this.cardBackground = Colors.white,
    this.textPrimary = const Color(0xFF111827), // grey[900]
    this.textSecondary = const Color(0xFF6B7280), // grey[500]
    this.dividerColor = const Color(0xFFE5E7EB), // grey[200]
  });
}

class StudentThemeManager {
  static const String _prefKey = 'student_theme_preference';

  static final List<StudentThemeConfig> availableThemes = [
    const StudentThemeConfig(
      id: 'blue',
      name: 'Blue',
      primary: Color(0xFF2563EB),
      gradientEnd: Color(0xFF1D4ED8),
      highlight: Color(0xFF3B82F6),
    ),
    const StudentThemeConfig(
      id: 'teal',
      name: 'Teal',
      primary: Colors.teal,
      gradientEnd: Color(0xFF00695C),
      highlight: Color(0xFF059669),
    ),
    const StudentThemeConfig(
      id: 'navy',
      name: 'Navy Blue',
      primary: Color(0xFF1E3A8A),
      gradientEnd: Color(0xFF1D4ED8),
      highlight: Color(0xFF3B82F6),
    ),
    const StudentThemeConfig(
      id: 'orange',
      name: 'Orange',
      primary: Color(0xFFEA580C),
      gradientEnd: Color(0xFFF97316),
      highlight: Color(0xFFEAB308),
    ),
    const StudentThemeConfig(
      id: 'crimson',
      name: 'Crimson',
      primary: Color(0xFFBE123C),
      gradientEnd: Color(0xFFE11D48),
      highlight: Color(0xFFF43F5E),
    ),
    const StudentThemeConfig(
      id: 'purple',
      name: 'Purple',
      primary: Color(0xFF7E22CE),
      gradientEnd: Color(0xFF9333EA),
      highlight: Color(0xFFD946EF),
    ),
    const StudentThemeConfig(
      id: 'forest',
      name: 'Forest Green',
      primary: Color(0xFF15803D),
      gradientEnd: Color(0xFF16A34A),
      highlight: Color(0xFF22C55E),
    ),
    // DARK THEME
    const StudentThemeConfig(
      id: 'dark',
      name: 'Dark (Gold)',
      primary: Color(0xFFD4AF37), // Gold
      gradientEnd: Color(0xFFB8860B), // Dark Gold
      highlight: Color(0xFFC0C0C0), // Silver
      background: Color(0xFF000000), // Pure Black
      cardBackground: Color(0xFF171717), // Very Dark Gray for cards
      textPrimary: Colors.white,
      textSecondary: Color(0xFF9CA3AF), // Lighter gray for secondary text
      dividerColor: Color(0xFF333333), // Dark border
    ),
  ];

  static final ValueNotifier<StudentThemeConfig> themeNotifier =
      ValueNotifier<StudentThemeConfig>(availableThemes.first);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeId = prefs.getString(_prefKey);
    if (savedThemeId != null) {
      final match = availableThemes.firstWhere(
        (t) => t.id == savedThemeId,
        orElse: () => availableThemes.first,
      );
      themeNotifier.value = match;
    }
  }

  static Future<void> setTheme(String id) async {
    final match = availableThemes.firstWhere(
      (t) => t.id == id,
      orElse: () => availableThemes.first,
    );
    themeNotifier.value = match;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, match.id);
  }
}
