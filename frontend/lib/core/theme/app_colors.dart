// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

/// Design tokens for the "Instrument" look: near-black glass surfaces in dark
/// mode, cool paper-white surfaces in light mode, one lemon accent, and two
/// saturated gradient cards (violet + indigo) that stay the same in both modes.
///
/// Every legacy token name is kept so existing screens keep compiling; only
/// the values changed.
class AppColors {
  // ── Brand ────────────────────────────────────────────────────────────────
  /// Violet. Works as icon / link colour on both light and dark surfaces.
  static const Color primary = Color(0xFF9B52CC);
  static const Color primaryLight = Color(0xFFC58BE6);
  static const Color primaryDark = Color(0xFF6F2A98);
  static const Color primaryGlow = Color(0x339B52CC);

  /// Lemon accent: primary buttons, active dock pill, slider/marker ticks.
  /// Always paired with [onAccent] text (never white on lemon).
  static const Color accent = Color(0xFFF4E22C);
  static const Color accentDeep = Color(0xFFE6CF10);
  static const Color onAccent = Color(0xFF17140A);

  // ── Saturated cards (identical in light + dark) ──────────────────────────
  static const Color violetA = Color(0xFFCB8DDA);
  static const Color violetB = Color(0xFF7A2C96);
  static const Color indigoCore = Color(0xFF0B0A2C);
  static const Color indigoMid = Color(0xFF3A3490);
  static const Color indigoGlow = Color(0xFF6C63C9);

  // ── Light neutrals ───────────────────────────────────────────────────────
  static const Color lightBg = Color(0xFFE9EAEE);
  static const Color lightSurface = Color(0xFFF4F4F6);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardSubtle = Color(0xFFF0F0F3);
  static const Color lightBorder = Color(0xFFDADBE1);
  static const Color lightTextPrimary = Color(0xFF0E0E11);
  static const Color lightTextSecondary = Color(0xFF5B5B66);
  static const Color lightTextTertiary = Color(0xFF8A8A95);

  // ── Dark neutrals ────────────────────────────────────────────────────────
  static const Color darkBg = Color(0xFF09090B);
  static const Color darkSurface = Color(0xFF111114);
  static const Color darkCard = Color(0xFF1B1B1F);
  static const Color darkCardSubtle = Color(0xFF26262B);
  static const Color darkBorder = Color(0xFF2C2C32);
  static const Color darkTextPrimary = Color(0xFFF6F6F3);
  static const Color darkTextSecondary = Color(0xFFA0A0A9);
  static const Color darkTextTertiary = Color(0xFF6E6E78);

  // Legacy "black card" tokens (used by OTP / trust panels)
  static const Color blackCardBg = Color(0xFF111114);
  static const Color blackCardBorder = Color(0xFF2C2C32);

  // ── Semantic status colours ──────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0x1A10B981);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0x1AF59E0B);

  static const Color error = Color(0xFFEF4444);
  static const Color errorBg = Color(0x1AEF4444);

  static const Color info = Color(0xFF6366F1);
  static const Color infoBg = Color(0x1A6366F1);

  static const Color purple = Color(0xFF8B5CF6);
  static const Color purpleBg = Color(0x1A8B5CF6);

  // Hover palette for icons
  static const List<Color> vibrantPalette = [
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
    Color(0xFFF97316),
  ];

  /// Darkens a status colour in light mode so text keeps readable contrast on
  /// its pale tinted background.
  static Color readable(Color c, Brightness b) =>
      b == Brightness.dark ? c : Color.lerp(c, Colors.black, 0.35)!;
}
