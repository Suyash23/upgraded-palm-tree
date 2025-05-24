import 'package:flutter/material.dart';
import '../logic/game_state.dart'; // Import GameMode

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Tic Tac Toe'),
        automaticallyImplyLeading: false, // No back button to a previous screen
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Super Tic Tac Toe',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent, // Example color
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Flutter Edition',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
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
                Navigator.pushReplacementNamed(
                  context,
                  '/game',
                  arguments: GameMode.humanVsAI,
                );
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
