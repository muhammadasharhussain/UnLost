// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

/// Mode-aware tokens that don't fit in Material's ColorScheme.
/// Read with `context.palette`.
@immutable
class UnlostPalette extends ThemeExtension<UnlostPalette> {
  final bool isDark;
  final Color bg;
  final Color cardTop;
  final Color cardBottom;
  final Color hairline;
  final Color text;
  final Color textDim;
  final Color textFaint;
  final Color tickIdle;
  final Color tickActive;
  final Color circleFill;
  final Color invertedFill; // selected segment / chip background
  final Color invertedText;
  final Color shadow;

  const UnlostPalette({
    required this.isDark,
    required this.bg,
    required this.cardTop,
    required this.cardBottom,
    required this.hairline,
    required this.text,
    required this.textDim,
    required this.textFaint,
    required this.tickIdle,
    required this.tickActive,
    required this.circleFill,
    required this.invertedFill,
    required this.invertedText,
    required this.shadow,
  });

  static const UnlostPalette dark = UnlostPalette(
    isDark: true,
    bg: AppColors.darkBg,
    cardTop: Color(0xFF2A2A2F),
    cardBottom: Color(0xFF17171B),
    hairline: Color(0x14FFFFFF),
    text: AppColors.darkTextPrimary,
    textDim: AppColors.darkTextSecondary,
    textFaint: AppColors.darkTextTertiary,
    tickIdle: Color(0x40FFFFFF),
    tickActive: Color(0xFFF6F6F3),
    circleFill: Color(0xFF1B1B1F),
    invertedFill: Color(0xFFF6F6F3),
    invertedText: Color(0xFF0E0E11),
    shadow: Color(0x66000000),
  );

  static const UnlostPalette light = UnlostPalette(
    isDark: false,
    bg: AppColors.lightBg,
    cardTop: Color(0xFFFFFFFF),
    cardBottom: Color(0xFFF1F1F5),
    hairline: Color(0x14000000),
    text: AppColors.lightTextPrimary,
    textDim: AppColors.lightTextSecondary,
    textFaint: AppColors.lightTextTertiary,
    tickIdle: Color(0x33000000),
    tickActive: Color(0xFF0E0E11),
    circleFill: Color(0xFFFFFFFF),
    invertedFill: Color(0xFF0E0E11),
    invertedText: Color(0xFFF6F6F3),
    shadow: Color(0x1A1E1E3C),
  );

  @override
  UnlostPalette copyWith({bool? isDark}) => isDark == true ? dark : (isDark == false ? light : this);

  @override
  UnlostPalette lerp(ThemeExtension<UnlostPalette>? other, double t) {
    if (other is! UnlostPalette) return this;
    return t < 0.5 ? this : other;
  }
}

extension UnlostThemeX on BuildContext {
  UnlostPalette get palette =>
      Theme.of(this).extension<UnlostPalette>() ?? UnlostPalette.dark;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}

class AppTheme {
  /// Bundled typeface (assets/fonts, declared in pubspec.yaml).
  /// Set to null to fall back to the platform default.
  static const String? fontFamily = 'InstrumentSans';

  static ThemeData light() => _build(UnlostPalette.light);
  static ThemeData dark() => _build(UnlostPalette.dark);

  static ThemeData _build(UnlostPalette p) {
    final isDark = p.isDark;
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final cardSubtle = isDark ? AppColors.darkCardSubtle : AppColors.lightCardSubtle;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      onSecondary: AppColors.onAccent,
      error: AppColors.error,
      onError: Colors.white,
      surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      onSurface: p.text,
      surfaceContainerHighest: cardSubtle,
      surfaceContainerHigh: card,
      surfaceContainer: card,
      outline: border,
      outlineVariant: border,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamily,
    );

    TextStyle ts(double size, FontWeight w, {double ls = 0, Color? c, double? h}) =>
        TextStyle(fontSize: size, fontWeight: w, letterSpacing: ls, color: c ?? p.text, height: h);

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: p.bg,
      primaryColor: AppColors.primary,
      splashFactory: InkRipple.splashFactory,
      extensions: <ThemeExtension<dynamic>>[p],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: p.text),
        titleTextStyle: ts(22, FontWeight.w500, ls: -0.6),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: p.hairline, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: p.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: p.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: ts(14, FontWeight.w400, c: p.textFaint),
        prefixIconColor: p.textDim,
        suffixIconColor: p.textDim,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const StadiumBorder(),
          textStyle: ts(15, FontWeight.w600, ls: -0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.text,
          elevation: 0,
          side: BorderSide(color: border, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const StadiumBorder(),
          textStyle: ts(15, FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
          shape: const StadiumBorder(),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        elevation: 0,
        shape: StadiumBorder(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardSubtle,
        selectedColor: AppColors.primary,
        disabledColor: cardSubtle,
        shape: const StadiumBorder(side: BorderSide.none),
        labelStyle: ts(13, FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      dividerTheme: DividerThemeData(color: p.hairline, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: p.textDim,
        textColor: p.text,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primary
              : (isDark ? const Color(0xFF3A3A42) : const Color(0xFFC9CAD2)),
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.invertedFill,
        contentTextStyle: ts(14, FontWeight.w500, c: p.invertedText),
        shape: const StadiumBorder(),
      ),
      textTheme: base.textTheme.copyWith(
        displayLarge: ts(40, FontWeight.w500, ls: -1.5),
        displayMedium: ts(32, FontWeight.w500, ls: -1.0),
        headlineLarge: ts(26, FontWeight.w500, ls: -0.8),
        headlineMedium: ts(21, FontWeight.w500, ls: -0.5),
        titleLarge: ts(18, FontWeight.w600, ls: -0.4),
        titleMedium: ts(15, FontWeight.w600, ls: -0.2),
        bodyLarge: ts(15, FontWeight.w400, h: 1.4),
        bodyMedium: ts(13, FontWeight.w400, c: p.textDim, h: 1.4),
        labelLarge: ts(13, FontWeight.w600),
      ),
    );
  }
}
