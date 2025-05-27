import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart'; // Import WelcomeScreen
import 'screens/difficulty_screen.dart'; // Import DifficultyScreen
import 'screens/settings_screen.dart'; // Add this import
import 'logic/game_state.dart';
import 'themes/color_schemes.dart'; // Assuming this path

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => GameState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final AppColorScheme scheme = gameState.currentColorScheme;
        return MaterialApp(
          title: 'Super Tic Tac Toe',
          theme: ThemeData(
            // Use a neutral primary swatch or generate one from scheme.accentColor if needed
            // For simplicity, we can keep a default or try to make one.
            // Using a ColorScheme might be more robust for full theming.
            primarySwatch: Colors.blue, // Keep for now, can be refined
            scaffoldBackgroundColor: scheme.scaffoldBackground,
            appBarTheme: AppBarTheme(
              backgroundColor: scheme.appBarBackground,
              titleTextStyle: TextStyle(
                color: scheme.primaryText, // Assuming AppBar title should use primaryText
                fontSize: 20, // Default AppBar title size
                fontWeight: FontWeight.bold, // Default AppBar title weight
              ),
              iconTheme: IconThemeData(color: scheme.primaryText), // For icons like back arrow, settings
            ),
            fontFamily: 'Roboto',
            // You might want to define textTheme and buttonTheme explicitly too
            textTheme: TextTheme(
              bodyLarge: TextStyle(color: scheme.primaryText),
              bodyMedium: TextStyle(color: scheme.primaryText), // Default text color
              titleLarge: TextStyle(color: scheme.primaryText), // For screen titles if not in AppBar
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.buttonBackground,
                foregroundColor: scheme.buttonText,
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: scheme.accentColor, // Use accent for text buttons
              )
            ),
            iconTheme: IconThemeData(
              color: scheme.accentColor, // General icon theme
            ),
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => const WelcomeScreen(),
            '/game': (context) => const HomeScreen(),
            '/difficulty': (context) => const DifficultyScreen(),
            '/settings': (context) => const SettingsScreen(),
          },
        );
      },
    );
  }
}
