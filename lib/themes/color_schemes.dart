import 'package:flutter/material.dart';

class AppColorScheme {
  final Color scaffoldBackground;
  final Color appBarBackground;
  final Color primaryText; // For general text
  final Color secondaryText; // For less prominent text
  final Color accentColor; // For highlights, icons, etc.
  final Color buttonBackground;
  final Color buttonText;
  final Color miniGridColor;
  final Color activeMiniGridColor; // For playable mini-grids
  final Color superGridColor;
  final Color xColor;
  final Color oColor;
  // Winning line colors can be the same as xColor and oColor,
  // or defined separately if they need to be different.
  // For now, assume they will be the same as xColor and oColor.

  const AppColorScheme({
    required this.scaffoldBackground,
    required this.appBarBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.accentColor,
    required this.buttonBackground,
    required this.buttonText,
    required this.miniGridColor,
    required this.activeMiniGridColor,
    required this.superGridColor,
    required this.xColor,
    required this.oColor,
  });
}

class AppColorSchemes {
  static const AppColorScheme defaultScheme = AppColorScheme(
    scaffoldBackground: Color(0xFFFEF8FF),
    appBarBackground: Colors.blue, // Standard Flutter blue
    primaryText: Colors.black,
    secondaryText: Color(0xFF555555), // Dark grey
    accentColor: Colors.blueAccent,
    buttonBackground: Colors.blue,
    buttonText: Colors.white,
    miniGridColor: Color(0xFF007bff), // Blue from MiniGridPainter (non-playable)
    activeMiniGridColor: Color(0xFFDAA520), // Dark Yellow from MiniGridPainter (playable)
    superGridColor: Color(0xFF333333), // Dark grey from SuperGridPainter
    xColor: Color(0xFFFF3860), // Red from XPainter
    oColor: Color(0xFF209CEE), // Blue from OPainter
  );

  static const AppColorScheme scheme2 = AppColorScheme(
    scaffoldBackground: Color(0xFF12BDAC), // Teal background
    appBarBackground: Color(0xFF0D8F83), // Darker shade of background for AppBar
    primaryText: Color(0xFFFFFFFF), // White text for contrast on dark background
    secondaryText: Color(0xFFE0E0E0), // Light grey
    accentColor: Color(0xFFF2EBD3), // A creamy off-white as accent (was O color, but O is light)
    buttonBackground: Color(0xFF064F48), // Dark teal for buttons
    buttonText: Color(0xFFFFFFFF), // White text on dark buttons
    miniGridColor: Color(0xFF0CA192), // Slightly lighter teal for mini-grid
    activeMiniGridColor: Color(0xFF15E8D6), // Vibrant lighter teal for active mini-grid
    superGridColor: Color(0xFF064F48), // Dark teal for super grid lines
    xColor: Color(0xFF545454), // Dark Grey for X
    oColor: Color(0xFFF2EBD3), // Creamy off-white for O
  );

  static const AppColorScheme scheme3 = AppColorScheme(
    scaffoldBackground: Color(0xFF121212), // Dark grey
    appBarBackground: Color(0xFF1E1E1E), // Slightly lighter dark grey
    primaryText: Colors.white,
    secondaryText: Color(0xFFAAAAAA), // Lighter grey for secondary text
    accentColor: Color(0xFF00E676), // Vibrant green (O color) as accent
    buttonBackground: Color(0xFF333333), // Medium-dark grey buttons
    buttonText: Colors.white,
    miniGridColor: Color(0xFF4A4A4A), // Medium grey
    activeMiniGridColor: Color(0xFF6D6D6D), // Lighter grey for active mini grid
    superGridColor: Color(0xFF6E6E6E), // Lighter grey for main grid lines
    xColor: Color(0xFFFF3D00), // Vibrant orange/red
    oColor: Color(0xFF00E676), // Vibrant green
  );
}
