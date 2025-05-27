import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Added import
import '../logic/game_state.dart'; // Covers GameState and GameMode
import '../themes/color_schemes.dart'; // Added import
import '../themes/button_styles.dart'; // Added import

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColorScheme scheme = Provider.of<GameState>(context).currentColorScheme; // Access scheme

    return Scaffold(
      // appBar: AppBar(...) // AppBar removed
      body: Stack( // Changed body to Stack
        children: <Widget>[
          Center( // Original content wrapped in Center
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
            Text( // Updated first Text widget
              'Super Tic Tac Toe',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: scheme.accentColor, // New color from scheme
              ),
            ),
            // const SizedBox(height: 10), // Removed
            // Text( // Updated second Text widget // Removed
            //   'Flutter Edition',
            //   style: TextStyle(
            //     fontSize: 18,
            //     color: scheme.secondaryText, // New color from scheme
            //   ),
            // ), // Removed
            const SizedBox(height: 60),
            ElevatedButton( // First button
              style: roundedSquareButtonStyle.copyWith(
                padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 40, vertical: 20)),
                textStyle: MaterialStateProperty.all(const TextStyle(fontSize: 18))
              ),
              onPressed: () { // Correctly defined onPressed
                Navigator.pushReplacementNamed(
                  context,
                  '/game',
                  arguments: GameMode.humanVsHuman,
                );
              },
              child: const Text('Play vs Human'), // Added missing child
            ),
            const SizedBox(height: 20),
            ElevatedButton( // Second button
              style: roundedSquareButtonStyle.copyWith(
                padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 40, vertical: 20)),
                textStyle: MaterialStateProperty.all(const TextStyle(fontSize: 18))
              ),
              onPressed: () {
                // Setting GameMode and AIDifficulty will now be handled by DifficultyScreen
                Navigator.of(context).pushNamed('/difficulty');
              },
              child: const Text('Play vs AI'),
            ),
            // Optionally, add a "How to Play" button later
            // const SizedBox(height: 40),
            // TextButton(
            //   onPressed: () {
            //     // TODO: Show rules dialog or navigate to rules screen
            //   },
            //   child: const Text('How to Play?'),
            // ),
          // Optionally, add a "How to Play" button later
          // const SizedBox(height: 40),
          // TextButton(
          //   onPressed: () {
          //     // TODO: Show rules dialog or navigate to rules screen
          //   },
          //   child: const Text('How to Play?'),
          // ),
              ],
            ),
          ),
          Positioned( // Settings IconButton positioned on top
            top: 16.0,
            right: 16.0,
            child: IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Settings',
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ),
        ],
      ),
    );
  }
}
