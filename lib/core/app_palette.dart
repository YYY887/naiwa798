import 'package:flutter/material.dart';

abstract final class AppPalette {
  static const ink = Color(0xff21364e);
  static const mutedInk = Color(0xff73869a);
  static const primary = Color(0xff2674ce);

  static ThemeData themeFor(bool dark) {
    final colors = AppColors(dark);
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: dark ? Brightness.dark : Brightness.light,
    ).copyWith(surface: colors.surface, onSurface: colors.ink);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: pageColorFor(dark),
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          color: colors.ink,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -.8,
        ),
        titleLarge: TextStyle(
          color: colors.ink,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -.5,
        ),
        titleMedium: TextStyle(
          color: colors.ink,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: colors.ink, fontSize: 15, height: 1.5),
        bodyMedium: TextStyle(color: colors.ink, fontSize: 14, height: 1.5),
        bodySmall: TextStyle(color: colors.muted, fontSize: 12, height: 1.5),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.field,
        hintStyle: TextStyle(color: colors.muted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.accent, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: colors.tint,
          disabledForegroundColor: colors.muted,
          minimumSize: const Size(0, 54),
          elevation: 0,
          shape: shape,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 54),
          shape: shape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.accent,
          minimumSize: const Size(0, 50),
          side: BorderSide(color: colors.border),
          shape: shape,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: dark
            ? const Color(0xffd9eaff)
            : const Color(0xff263e58),
        contentTextStyle: TextStyle(
          color: dark ? ink : Colors.white,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }

  static Color pageColorFor(bool darkMode) =>
      darkMode ? const Color(0xff111b28) : Colors.white;

  static Gradient pageBackgroundFor(bool darkMode) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pageColorFor(darkMode), pageColorFor(darkMode)],
  );
}

class AppColors {
  const AppColors(this.dark);
  final bool dark;
  Color get ink => dark ? const Color(0xffedf5ff) : AppPalette.ink;
  Color get muted => dark ? const Color(0xff9eafc4) : AppPalette.mutedInk;
  Color get accent => dark ? const Color(0xff9bcaff) : AppPalette.primary;
  Color get tint => dark ? const Color(0xff223a54) : const Color(0xffeaf4ff);
  Color get surface => dark ? const Color(0xff1a293b) : Colors.white;
  Color get field => dark ? const Color(0xff213249) : const Color(0xfff6f9fd);
  Color get border => dark ? const Color(0xff2c415b) : const Color(0xffe4edf7);
  Color get danger => dark ? const Color(0xfff1a3ad) : const Color(0xffbf6678);
}
