import 'package:flutter/material.dart';

import 'models/game.dart';
import 'screens/game_detail_screen.dart';
import 'theme/app_colors.dart';

void main() {
  runApp(const GameVaultApp());
}

class GameVaultApp extends StatelessWidget {
  const GameVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GameVault',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          surface: AppColors.background,
        ),
      ),
      home: const GameDetailScreen(game: hollowKnight),
    );
  }
}
