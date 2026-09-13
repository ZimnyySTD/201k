import 'dart:io';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

class ThemeProvider extends ChangeNotifier {
  String _themeMode = 'white_neumorphism'; // 'white_neumorphism', 'dark_neumorphism', 'dynamic'

  Color _primaryColor = const Color(0xFF6C63FF);
  Color _secondaryColor = const Color(0xFF00B4D8);
  Color _accentColor = const Color(0xFFFF4B4B);

  String get themeMode => _themeMode;
  Color get primaryColor => _primaryColor;
  Color get secondaryColor => _secondaryColor;
  Color get accentColor => _accentColor;

  bool get isDarkMode => _themeMode == 'dark_neumorphism';

  // Neumorphic background color
  Color get backgroundColor {
    if (isDarkMode) {
      return const Color(0xFF1E1E24);
    }
    return const Color(0xFFF2F4F8); // Clean soft white
  }

  // Neumorphic card/surface color
  Color get surfaceColor {
    if (isDarkMode) {
      return const Color(0xFF24242C);
    }
    return const Color(0xFFF6F8FC);
  }

  Color get textColor {
    if (isDarkMode) {
      return const Color(0xFFEAEAEA);
    }
    return const Color(0xFF1A1D20);
  }

  Color get subtextColor {
    if (isDarkMode) {
      return const Color(0xFFA0A5B5);
    }
    return const Color(0xFF7E8494);
  }

  Color get lightShadow {
    if (isDarkMode) {
      return const Color(0xFF2D2D38);
    }
    return Colors.white;
  }

  Color get darkShadow {
    if (isDarkMode) {
      return const Color(0xFF131317);
    }
    return const Color(0xFFD3D8E2);
  }

  void setThemeMode(String mode) {
    _themeMode = mode;
    notifyListeners();
  }

  /// Extracts dominant colors from album cover image
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

      _primaryColor = palette.dominantColor?.color ?? palette.vibrantColor?.color ?? const Color(0xFF6C63FF);
      _secondaryColor = palette.mutedColor?.color ?? palette.lightVibrantColor?.color ?? const Color(0xFF00B4D8);
      _accentColor = palette.vibrantColor?.color ?? palette.lightVibrantColor?.color ?? _primaryColor;

      notifyListeners();
    } catch (e) {
      debugPrint('Error extracting colors from album artwork: $e');
      _resetDefaultColors();
    }
  }

  void _resetDefaultColors() {
    _primaryColor = const Color(0xFF6C63FF);
    _secondaryColor = const Color(0xFF00B4D8);
    _accentColor = const Color(0xFFFF4B4B);
    notifyListeners();
  }
}
