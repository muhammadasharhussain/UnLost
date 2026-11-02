// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

/// Design tokens for Unlost: Emerald Ink + Champagne palette.
///
/// Dark:
///   bg #04110D, card #0A1F18, border #17382C, emerald #2ECC8F,
///   champagne #F1E1BC, text #F4F1E8
/// Light:
///   bg #F6F0E0, card #FFFDF7, border #E2D6B5, emerald ink #0B3D2E,
///   champagne ink #8A6A1F
///
/// Found = Emerald, Lost = Champagne.
class AppColors {
  // ── Core Brand Tokens ─────────────────────────────────────────────────────
  static const Color emerald = Color(0xFF2ECC8F);
  static const Color emeraldInk = Color(0xFF0B3D2E); // High contrast on light
  static const Color onEmerald = Color(0xFF04110D);

  static const Color champagne = Color(0xFFF1E1BC);
  static const Color champagneInk = Color(0xFF8A6A1F); // High contrast on light
  static const Color onChampagne = Color(0xFF04110D);

  // Semantics: Found = Emerald, Lost = Champagne
  static const Color found = emerald;
  static const Color foundInk = emeraldInk;
  static const Color lost = champagne;
  static const Color lostInk = champagneInk;

  // Primary & Accent mappings
  static const Color primary = emerald;
  static const Color primaryLight = Color(0xFF5FE0A8);
  static const Color primaryDark = emeraldInk;
  static const Color primaryGlow = Color(0x332ECC8F);

  static const Color accent = champagne;
  static const Color accentDeep = champagneInk;
  static const Color onAccent = onChampagne;

  // Aliases for compatibility
  static const Color cerulean = emerald;
  static const Color ceruleanInk = emeraldInk;
  static const Color onCerulean = onEmerald;

  static const Color rose = champagne;
  static const Color roseInk = champagneInk;
  static const Color onRose = onChampagne;

  // ── Gradients & Saturated tokens ──────────────────────────────────────────
  static const Color emeraldGradA = emerald;
  static const Color champagneGradB = champagne;
  static const Color ceruleanGradA = emerald;
  static const Color roseGradB = champagne;

  static const Color darkCore = Color(0xFF04110D);
  static const Color darkMid = Color(0xFF0A1F18);
  static const Color darkGlow = Color(0x332ECC8F);
  static const Color indigoCore = darkCore;
  static const Color indigoMid = darkMid;
  static const Color indigoGlow = darkGlow;

  // ── Action / Attention Token: Coral Ember ─────────────────────────────────
  static const Color coral = Color(0xFFF2765A);       // Dark CTA, badge, marker
  static const Color coralInk = Color(0xFFB8431F);    // Light mode ink CTA/action
  static const Color onCoral = Color(0xFF04110D);     // Dark text on coral buttons (contrast > 10:1)

  // ── Light neutrals & surfaces (3 visibly distinct tiers) ────────────────────
  // 1. Page background: Warm parchment
  static const Color lightBg = Color(0xFFF6F0E0);
  // 2. SectionPanel surface: Clean ivory panel
  static const Color lightPanel = Color(0xFFEDE5D0);
  static const Color lightPanelBorder = Color(0xFFDECFA8);
  // 3. Card surface: Bright crisp cream card inside panel
  static const Color lightCard = Color(0xFFFFFDF7);
  static const Color lightCardHover = Color(0xFFF4ECE0);
  static const Color lightCardSubtle = Color(0xFFF2EAD5);
  static const Color lightSurface = lightCard;
  static const Color lightBorder = Color(0xFFE2D6B5);
  static const Color lightTextPrimary = Color(0xFF141F1A);   // > 13:1 on lightBg
  static const Color lightTextSecondary = Color(0xFF4A554E); // > 5.5:1 on card
  static const Color lightTextTertiary = Color(0xFF6E7972);  // > 4.5:1 on card

  // ── Dark neutrals & surfaces (3 visibly distinct tiers) ─────────────────────
  // 1. Page background: Deepest obsidian green
  static const Color darkBg = Color(0xFF04110D);
  // 2. SectionPanel surface: Midnight forest panel
  static const Color darkPanel = Color(0xFF081813);
  static const Color darkPanelBorder = Color(0xFF143025);
  // 3. Card surface: Elevated card inside panel
  static const Color darkCard = Color(0xFF0D251D);
  static const Color darkCardHover = Color(0xFF123227);
  static const Color darkCardSubtle = Color(0xFF0F2B22);
  static const Color darkSurface = darkCard;
  static const Color darkBorder = Color(0xFF1A4032);
  static const Color darkTextPrimary = Color(0xFFF4F1E8);   // > 15:1 on darkBg
  static const Color darkTextSecondary = Color(0xFFA6B8AE); // > 6.5:1 on card
  static const Color darkTextTertiary = Color(0xFF788D82);  // > 4.5:1 on card

  // Legacy aliases
  static const Color blackCardBg = darkSurface;
  static const Color blackCardBorder = darkBorder;

  // ── Status Tokens ─────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2ECC8F);
  static const Color successInk = Color(0xFF0B3D2E);
  static const Color successBg = Color(0x1A2ECC8F);

  static const Color warning = Color(0xFFE5A93B);
  static const Color warningInk = Color(0xFF8A6A1F);
  static const Color warningBg = Color(0x1AF1E1BC);

  static const Color error = Color(0xFFEF5350);
  static const Color errorInk = Color(0xFFB71C1C);
  static const Color errorBg = Color(0x1AEF5350);

  static const Color info = emerald;
  static const Color infoInk = emeraldInk;
  static const Color infoBg = Color(0x1A2ECC8F);

  static const Color purple = Color(0xFF7C5CF0);
  static const Color purpleBg = Color(0x1A7C5CF0);

  // Vibrant palette for icon backgrounds & accents
  static const List<Color> vibrantPalette = [
    Color(0xFF2ECC8F),
    Color(0xFFF1E1BC),
    Color(0xFF38B6FF),
    Color(0xFF10B981),
    Color(0xFFE5A93B),
    Color(0xFF06B6D4),
  ];

  /// Returns readable ink colour for light mode and bright token for dark mode
  static Color readable(Color c, Brightness b) {
    if (b == Brightness.dark) return c;
    if (c == emerald || c == cerulean) return emeraldInk;
    if (c == champagne || c == rose) return champagneInk;
    if (c == success) return successInk;
    if (c == warning) return warningInk;
    if (c == error) return errorInk;
    return Color.lerp(c, Colors.black, 0.45)!;
  }
}
