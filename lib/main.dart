import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart'; // Import WelcomeScreen
import 'logic/game_state.dart'; 

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
    return MaterialApp(
      title: 'Super Tic Tac Toe',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      initialRoute: '/', // Optional: explicitly set initial route
      routes: {
        '/': (context) => const WelcomeScreen(), // WelcomeScreen is home
        '/game': (context) => const HomeScreen(),  // Named route for HomeScreen
      },
      // home: const WelcomeScreen(), // Set WelcomeScreen as home if not using initialRoute
    );
  }
}
