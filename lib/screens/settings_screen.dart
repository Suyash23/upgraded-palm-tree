import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/game_state.dart'; // Adjust path if necessary
import '../themes/button_styles.dart'; // Added import

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        // leading: IconButton( // Optional: Explicit back button if not using default
        //   icon: const Icon(Icons.arrow_back),
        //   onPressed: () => Navigator.of(context).pop(),
        // ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  Provider.of<GameState>(context, listen: false).setColorScheme(ColorSchemeChoice.scheme1);
                  Navigator.of(context).pop();
                },
                style: roundedSquareButtonStyle,
                child: const Text('Color Scheme 1'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Provider.of<GameState>(context, listen: false).setColorScheme(ColorSchemeChoice.scheme2);
                  Navigator.of(context).pop();
                },
                style: roundedSquareButtonStyle,
                child: const Text('Color Scheme 2'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Provider.of<GameState>(context, listen: false).setColorScheme(ColorSchemeChoice.scheme3);
                  Navigator.of(context).pop();
                },
                style: roundedSquareButtonStyle,
                child: const Text('Color Scheme 3'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
