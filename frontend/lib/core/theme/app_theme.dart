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
  final Color panel;
  final Color panelBorder;
  final Color cardTop;
  final Color cardBottom;
  final Color hairline;
  final Color coral;
  final Color coralInk;
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
    required this.panel,
    required this.panelBorder,
    required this.cardTop,
    required this.cardBottom,
    required this.hairline,
    required this.coral,
    required this.coralInk,
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
    panel: AppColors.darkPanel,
    panelBorder: AppColors.darkPanelBorder,
    cardTop: AppColors.darkCard,
    cardBottom: Color(0xFF071B14),
    hairline: AppColors.darkBorder,
    coral: AppColors.coral,
    coralInk: AppColors.coral,
    text: AppColors.darkTextPrimary,
    textDim: AppColors.darkTextSecondary,
    textFaint: AppColors.darkTextTertiary,
    tickIdle: Color(0x3317382C),
    tickActive: AppColors.emerald,
    circleFill: AppColors.darkCard,
    invertedFill: AppColors.darkTextPrimary,
    invertedText: AppColors.darkBg,
    shadow: Color(0x66000000),
  );

  static const UnlostPalette light = UnlostPalette(
    isDark: false,
    bg: AppColors.lightBg,
    panel: AppColors.lightPanel,
    panelBorder: AppColors.lightPanelBorder,
    cardTop: AppColors.lightCard,
    cardBottom: Color(0xFFFAF6EB),
    hairline: AppColors.lightBorder,
    coral: AppColors.coral,
    coralInk: AppColors.coralInk,
    text: AppColors.lightTextPrimary,
    textDim: AppColors.lightTextSecondary,
    textFaint: AppColors.lightTextTertiary,
    tickIdle: Color(0x33E2D6B5),
    tickActive: AppColors.emeraldInk,
    circleFill: AppColors.lightCard,
    invertedFill: AppColors.lightTextPrimary,
    invertedText: AppColors.lightBg,
    shadow: Color(0x1A403212),
  );

  @override
  UnlostPalette copyWith({bool? isDark}) => isDark == true ? dark : (isDark == false ? light : this);

  @override
  UnlostPalette lerp(ThemeExtension<UnlostPalette>? other, double t) {
    if (other is! UnlostPalette) return this;
    return t < 0.5 ? this : other;
  }
}

extension UnlostThemeContext on BuildContext {
  UnlostPalette get palette =>
      Theme.of(this).extension<UnlostPalette>() ?? UnlostPalette.dark;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}

class AppTheme {
  /// Primary font families bundled in assets/fonts/
  static const String fontFamily = 'Inter';
  static const String displayFontFamily = 'Inter';
  static const String monoFontFamily = 'JetBrainsMono';
  static const String brandFontFamily = 'Unbounded';

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
      primary: isDark ? AppColors.emerald : AppColors.emeraldInk,
      onPrimary: isDark ? AppColors.onEmerald : Colors.white,
      secondary: isDark ? AppColors.champagne : AppColors.champagneInk,
      onSecondary: isDark ? AppColors.onChampagne : AppColors.onChampagne,
      error: isDark ? AppColors.error : AppColors.errorInk,
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

    TextStyle ts(double size, FontWeight w, {double ls = 0, Color? c, double? h, String? family}) =>
        TextStyle(
          fontFamily: family ?? fontFamily,
          fontSize: size,
          fontWeight: w,
          letterSpacing: ls,
          color: c ?? p.text,
          height: h,
        );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: p.bg,
      primaryColor: isDark ? AppColors.cerulean : AppColors.ceruleanInk,
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
        titleTextStyle: ts(24, FontWeight.w700, ls: -0.5, family: displayFontFamily),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: 2),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? AppColors.emerald : AppColors.emeraldInk, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? AppColors.error : AppColors.errorInk, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? AppColors.error : AppColors.errorInk, width: 2),
        ),
        hintStyle: ts(14, FontWeight.w400, c: p.textFaint),
        prefixIconColor: p.textDim,
        suffixIconColor: p.textDim,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppColors.emerald : AppColors.emeraldInk,
          foregroundColor: isDark ? AppColors.onEmerald : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const StadiumBorder(),
          textStyle: ts(15, FontWeight.w700, ls: -0.2),
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
          foregroundColor: isDark ? AppColors.emerald : AppColors.emeraldInk,
          shape: const StadiumBorder(),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isDark ? AppColors.emerald : AppColors.emeraldInk,
        foregroundColor: isDark ? AppColors.onEmerald : Colors.white,
        elevation: 0,
        shape: const StadiumBorder(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardSubtle,
        selectedColor: isDark ? AppColors.emerald : AppColors.emeraldInk,
        disabledColor: cardSubtle,
        shape: StadiumBorder(side: BorderSide(color: border, width: 1)),
        labelStyle: ts(12, FontWeight.w600, family: monoFontFamily, ls: 0.6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: p.textDim,
        textColor: p.text,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? (isDark ? AppColors.onEmerald : Colors.white)
              : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? (isDark ? AppColors.emerald : AppColors.emeraldInk)
              : (isDark ? const Color(0xFF17382C) : const Color(0xFFE2D6B5)),
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: isDark ? AppColors.emerald : AppColors.emeraldInk,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: border, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        contentTextStyle: ts(14, FontWeight.w500, c: p.text),
        shape: StadiumBorder(side: BorderSide(color: border, width: 1)),
      ),
      textTheme: base.textTheme.copyWith(
        displayLarge: ts(40, FontWeight.w700, ls: -1.5, family: displayFontFamily),
        displayMedium: ts(32, FontWeight.w700, ls: -1.0, family: displayFontFamily),
        headlineLarge: ts(26, FontWeight.w700, ls: -0.8, family: displayFontFamily),
        headlineMedium: ts(21, FontWeight.w700, ls: -0.5, family: displayFontFamily),
        titleLarge: ts(18, FontWeight.w700, ls: -0.4, family: displayFontFamily),
        titleMedium: ts(15, FontWeight.w600, ls: -0.2),
        bodyLarge: ts(15, FontWeight.w400, h: 1.4),
        bodyMedium: ts(13, FontWeight.w400, c: p.textDim, h: 1.4),
        labelLarge: ts(12, FontWeight.w700, family: monoFontFamily, ls: 0.8),
        labelMedium: ts(11, FontWeight.w600, family: monoFontFamily, ls: 0.8),
        labelSmall: ts(10, FontWeight.w600, family: monoFontFamily, ls: 0.8),
      ),
    );
  }
}
