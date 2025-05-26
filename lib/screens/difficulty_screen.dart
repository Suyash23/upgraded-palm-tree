import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import 'package:flutter/foundation.dart'; // For kDebugMode
import '../logic/game_state.dart';      
import '../logic/ai_difficulty.dart';  // Added import

// Helper class for difficulty details
class DifficultyDetails {
  final String emoji;
  final String name;
  DifficultyDetails(this.emoji, this.name);
}

class DifficultyScreen extends StatefulWidget {
  const DifficultyScreen({super.key});

  @override
  State<DifficultyScreen> createState() => _DifficultyScreenState();
}

class _DifficultyScreenState extends State<DifficultyScreen> {
  double _sliderValue = 1.0; // Default to Medium

  DifficultyDetails _getDifficultyDetails(double value) {
    int roundedValue = value.round(); // Slider snaps to 0, 1, 2, 3
    switch (roundedValue) {
      case 0:
        return DifficultyDetails("🙂", "Easy");
      case 1:
        return DifficultyDetails("🧐", "Medium");
      case 2:
        return DifficultyDetails("😡", "Hard");
      case 3:
        return DifficultyDetails("💀", "Unfair");
      default:
        return DifficultyDetails("🧐", "Medium"); // Default case
    }
  }

  @override
  Widget build(BuildContext context) {
    final details = _getDifficultyDetails(_sliderValue); // Call helper

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select AI Difficulty'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch, // Using stretch for button width as in example
          children: <Widget>[
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Text( // This is the child Text widget for the emoji
                details.emoji,
                key: ValueKey<String>(details.emoji), // Key based on the emoji string
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 100),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              details.name, // Use dynamic name
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 8.0,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
                // Optional: customize colors if needed
                // activeTrackColor: Theme.of(context).colorScheme.primary,
                // inactiveTrackColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                // thumbColor: Theme.of(context).colorScheme.primary,
              ),
              child: Row(
                children: <Widget>[
                  const Spacer(flex: 1),
                  Expanded(
                    flex: 3, // Using flex:3 as per example, adjust if needed
                    child: Slider(
                      value: _sliderValue,
                      min: 0.0,
                      max: 3.0,
                      divisions: 3,
                      label: details.name, // Use dynamic name for label
                      onChanged: (double newValue) {
                        setState(() {
                          _sliderValue = newValue;
                        });
                      },
                    ),
                  ),
                  const Spacer(flex: 1),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Get GameState instance
                final gameState = Provider.of<GameState>(context, listen: false);

                // Set GameMode
                if (kDebugMode) {
                  print("[DifficultyScreen] Setting game mode to humanVsAI");
                }
                gameState.setGameMode(GameMode.humanVsAI);

                // Convert _sliderValue to AIDifficulty enum and set it
                AIDifficulty selectedDifficulty;
                int roundedSliderValue = _sliderValue.round();
                switch (roundedSliderValue) {
                  case 0:
                    selectedDifficulty = AIDifficulty.easy;
                    break;
                  case 1:
                    selectedDifficulty = AIDifficulty.medium;
                    break;
                  case 2:
                    selectedDifficulty = AIDifficulty.hard;
                    break;
                  case 3:
                    selectedDifficulty = AIDifficulty.unfair;
                    break;
                  default:
                    selectedDifficulty = AIDifficulty.medium; // Default
                }
                gameState.setAIDifficulty(selectedDifficulty);

                if (kDebugMode) {
                  print("[DifficultyScreen] currentGameMode after set: ${gameState.currentGameMode}, selectedAIDifficulty: ${gameState.selectedAIDifficulty}");
                }

                // Navigate to the game screen
                // Use pushReplacementNamed to prevent going back to difficulty screen from game screen
                Navigator.of(context).pushReplacementNamed('/game');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0)
              ),
              child: const Text('Start Game', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
