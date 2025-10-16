// app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // “프로 카메라” 팔레트: 어두운 차콜 + 청록 액센트
  static const _obsidian = Color(0xFF0E1113);
  static const _charcoal = Color(0xFF14181B);
  static const _graphite = Color(0xFF1E2428);
  static const _silver = Color(0xFFBFC7CD);
  static const _accent = Color(0xFF23C4C7);

  static ColorScheme colorSchemeDark = const ColorScheme(
    brightness: Brightness.dark,
    primary: _accent,
    onPrimary: Colors.black,
    secondary: _silver,
    onSecondary: _obsidian,
    error: Color(0xFFFF5C5C),
    onError: Colors.white,
    background: _obsidian,
    onBackground: Colors.white,
    surface: _charcoal,
    onSurface: Colors.white,
  );

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorSchemeDark,
      scaffoldBackgroundColor: _obsidian,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _graphite,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _charcoal,
        selectedItemColor: _accent,
        unselectedItemColor: _silver,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _graphite,
        hintStyle: const TextStyle(color: Colors.white70),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      sliderTheme: const SliderThemeData(
        trackHeight: 3,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _graphite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
        contentTextStyle: const TextStyle(color: Colors.white70),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: _accent),
      ),
      cardTheme: CardThemeData(
        color: _graphite,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // 유리(글래스) 패널
  static BoxDecoration glass({double radius = 12}) => BoxDecoration(
    color: Colors.white.withOpacity(0.06),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: Colors.white.withOpacity(0.08)),
    boxShadow: [
      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 16),
    ],
  );

  // 가는 라벨
  static Widget infoBadge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: Colors.white.withOpacity(0.1)),
    ),
    child: Text(text, style: const TextStyle(fontSize: 11, color: Colors.white70)),
  );
}
