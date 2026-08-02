import 'dart:convert';

import 'package:home_widget/home_widget.dart';

/// Bridges game state to the native home screen widget.
class WidgetBridge {
  WidgetBridge._();

  static const widgetName = 'ProjectReforgeWidget';

  static Future<void> pushUpdate({
    required int level,
    required int xpInto,
    required int xpNext,
    required int streak,
    required double currentWeight,
    required double goalWeight,
    required double calories,
    required double calorieGoal,
    required double protein,
    required double proteinGoal,
    required double water,
    required double waterGoal,
    required double steps,
    required double stepsGoal,
    required bool workoutDone,
    required double sleepHours,
    required double completion,
    required String title,
    required String rank,
    required String boss,
    required int mood,
    required int energy,
  }) async {
    final data = jsonEncode({
      'level': level,
      'xpInto': xpInto,
      'xpNext': xpNext,
      'xpPct': xpNext <= 0 ? 0 : (xpInto / xpNext).clamp(0.0, 1.0),
      'streak': streak,
      'weight': currentWeight,
      'goalWeight': goalWeight,
      'calories': calories.round(),
      'calorieGoal': calorieGoal.round(),
      'protein': protein.round(),
      'proteinGoal': proteinGoal.round(),
      'water': water.round(),
      'waterGoal': waterGoal.round(),
      'steps': steps.round(),
      'stepsGoal': stepsGoal.round(),
      'workoutDone': workoutDone,
      'sleepHours': sleepHours,
      'completion': completion.clamp(0.0, 1.0),
      'title': title,
      'rank': rank,
      'boss': boss,
      'mood': mood,
      'energy': energy,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    try {
      await HomeWidget.saveWidgetData<String>('stateJson', data);
      await HomeWidget.updateWidget(
        name: widgetName,
        androidName: 'ProjectReforgeWidgetProvider',
        iOSName: widgetName,
      );
    } catch (_) {}
  }

  /// Registers background interactivity (Android). Fallback: open app with action.
  static Future<void> registerInteractivity(Future<void> Function(String action) handler) async {
    try {
      await HomeWidget.registerInteractivityCallback((action) async {
        await handler(action?.toString() ?? '');
      });
    } catch (_) {}
  }

  /// Action passed when the user taps a widget.
  static Future<String?> launchedAction() async {
    try {
      final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      return uri?.toString();
    } catch (_) {
      return null;
    }
  }
}
