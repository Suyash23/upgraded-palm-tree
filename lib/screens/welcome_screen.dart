import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Added import
import '../logic/game_state.dart'; // Covers GameState and GameMode
import '../themes/color_schemes.dart'; // Added import

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColorScheme scheme = Provider.of<GameState>(context).currentColorScheme; // Access scheme

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Tic Tac Toe'),
        automaticallyImplyLeading: false, // No back button to a previous screen
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings', // Optional: for accessibility
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: Center(
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
            const SizedBox(height: 10),
            Text( // Updated second Text widget
              'Flutter Edition',
              style: TextStyle(
                fontSize: 18,
                color: scheme.secondaryText, // New color from scheme
              ),
            ),
            const SizedBox(height: 60),
            ElevatedButton( // First button
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                textStyle: const TextStyle(fontSize: 18),
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
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                textStyle: const TextStyle(fontSize: 18),
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
          ],
        ),
      ),
    );
  }
}
