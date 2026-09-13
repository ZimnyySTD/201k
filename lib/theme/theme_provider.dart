import 'dart:io';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

class ThemeProvider extends ChangeNotifier {
  String _themeMode = 'white_neumorphism'; // 'white_neumorphism', 'dark_neumorphism', 'dynamic'

  Color _primaryColor = const Color(0xFF000000);
  Color _secondaryColor = const Color(0xFF333333);
  Color _accentColor = const Color(0xFF000000);

  String get themeMode => _themeMode;
  Color get primaryColor => _primaryColor;
  Color get secondaryColor => _secondaryColor;
  Color get accentColor => _accentColor;

  bool get isDarkMode => _themeMode == 'dark_neumorphism';

  // Pure White or Full Black Neumorphic Background
  Color get backgroundColor {
    if (isDarkMode) {
      return const Color(0xFF121212); // Full sleek black
    }
    return const Color(0xFFFFFFFF); // Pure minimalist white
  }

  // Pure White or Full Black Neumorphic Surface
  Color get surfaceColor {
    if (isDarkMode) {
      return const Color(0xFF181818);
    }
    return const Color(0xFFFFFFFF);
  }

  // Strict Monochrome Text (No colored text in library/home)
  Color get textColor {
    if (isDarkMode) {
      return const Color(0xFFFFFFFF);
    }
    return const Color(0xFF000000);
  }

  Color get subtextColor {
    if (isDarkMode) {
      return const Color(0xFF8E8E93);
    }
    return const Color(0xFF6E6E73);
  }

  Color get lightShadow {
    if (isDarkMode) {
      return const Color(0xFF222222);
    }
    return const Color(0xFFFFFFFF);
  }

  Color get darkShadow {
    if (isDarkMode) {
      return const Color(0xFF080808);
    }
    return const Color(0xFFD1D5DB); // Soft dual neumorphic shadow
  }

  void setThemeMode(String mode) {
    _themeMode = mode;
    notifyListeners();
  }

  /// Extracts dominant colors from album cover image for Now Playing screen
  Future<void> updateAccentFromImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      _resetDefaultColors();
      return;
    }

    try {
      ImageProvider imageProvider;
      if (imagePath.startsWith('http')) {
        imageProvider = NetworkImage(imagePath);
      } else if (imagePath.startsWith('asset:')) {
        imageProvider = AssetImage(imagePath.replaceFirst('asset:', ''));
      } else {
        imageProvider = FileImage(File(imagePath));
      }

      final palette = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 12,
      );

      _primaryColor = palette.dominantColor?.color ?? palette.vibrantColor?.color ?? const Color(0xFF000000);
      _secondaryColor = palette.mutedColor?.color ?? palette.lightVibrantColor?.color ?? const Color(0xFF555555);
      _accentColor = palette.vibrantColor?.color ?? palette.lightVibrantColor?.color ?? _primaryColor;

      notifyListeners();
    } catch (e) {
      debugPrint('Error extracting colors from album artwork: $e');
      _resetDefaultColors();
    }
  }

  void _resetDefaultColors() {
    _primaryColor = isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    _secondaryColor = const Color(0xFF555555);
    _accentColor = isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    notifyListeners();
  }
}
