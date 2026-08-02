import 'package:flutter/material.dart';

/// Project Reforge — design system & constants.
class AppColors {
  AppColors._();

  // Backgrounds
  static const Color bgStart = Color(0xFF070B16);
  static const Color bgEnd = Color(0xFF101C38);

  // RPG palette
  static const Color blue = Color(0xFF4F8CFF);
  static const Color blueDeep = Color(0xFF2F6BFF);
  static const Color gold = Color(0xFFFFC93C);
  static const Color goldBright = Color(0xFFFFE07A);
  static const Color green = Color(0xFF2BD67B);
  static const Color red = Color(0xFFFF5B5B);
  static const Color orange = Color(0xFFFF8A3D);
  static const Color purple = Color(0xFFB06BFF);
  static const Color teal = Color(0xFF31D8C7);
  static const Color pink = Color(0xFFFF6BA0);

  // Glass
  static const Color glassBg = Color(0x1FFFFFFF);
  static const Color glassBgStrong = Color(0x2EFFFFFF);
  static const Color glassStroke = Color(0x33FFFFFF);
  static const Color surface = Color(0xFF141C34);

  static const Color textPrimary = Color(0xFFF2F5FF);
  static const Color textSecondary = Color(0xFFA8B3CF);
  static const Color textDim = Color(0xFF6B7691);

  /// Default glass card gradient.
  static final LinearGradient glassBgLinear = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [const Color(0x38FFFFFF), const Color(0x12FFFFFF)],
  );

  /// Widget progress color zones (used by home widget too).
  static Color zoneColor(double pct) {
    if (pct >= 1.0) return goldBright;
    if (pct >= 0.75) return green;
    if (pct >= 0.5) return blue;
    if (pct >= 0.25) return orange;
    return red;
  }
}

class AppText {
  AppText._();

  static const String appName = 'Project Reforge';
  static const String tagline = 'Turn your transformation into a game.';
}

class GameConstants {
  GameConstants._();

  static const int defaultAge = 20;
  static const double defaultHeightCm = 178;
  static const double defaultWeightKg = 110;
  static const double defaultGoalWeightKg = 85;
  static const String defaultName = 'Champion';

  // Mission presets (id -> base config). Adaptive targets computed at runtime.
  static const List<MissionDef> missionDefs = [
    MissionDef('water', 'Hydration', 'Drink your water goal', '💧', 40, 5),
    MissionDef('steps', 'Move', 'Walk your step goal', '🏃', 50, 5),
    MissionDef('protein', 'Protein', 'Hit your protein goal', '🍗', 50, 5),
    MissionDef('calories', 'Fuel', 'Stay within calorie range', '🔥', 40, 5),
    MissionDef('no_sugar', 'No Sugary Drinks', 'Skip sodas & sugary drinks', '🥤', 45, 6),
    MissionDef('workout', 'Workout', 'Complete a workout', '💪', 80, 10),
    MissionDef('sleep', 'Sleep Before Midnight', 'Be asleep before 12 AM', '🌙', 40, 5),
    MissionDef('stretch', 'Stretch', '5 minutes of stretching', '🧘', 25, 3),
    MissionDef('meditate', 'Meditate', '3 minutes of mindfulness', '🕉️', 25, 3),
    MissionDef('photo', 'Progress Photo', 'Take a progress photo', '📸', 20, 3),
    MissionDef('read', 'Read', 'Read for 15 minutes', '📖', 20, 3),
    MissionDef('veggies', 'Eat Veggies', 'Add a serving of vegetables', '🥦', 20, 3),
  ];

  static const int waterPerTapMl = 250;
  static const int xpPerWater = 5;
  static const int xpPerMeal = 10;
  static const int xpPerWorkout = 80;
  static const int xpPerWeightLog = 15;
  static const int xpPerSleepOnTime = 40;
  static const int xpPerPhoto = 20;

  static const double stepsTarget = 8000;
  static const double dailyScoreTarget = 100;
}

class MissionDef {
  final String id;
  final String title;
  final String subtitle;
  final String icon;
  final int xp;
  final int coins;
  const MissionDef(this.id, this.title, this.subtitle, this.icon, this.xp, this.coins);
}
