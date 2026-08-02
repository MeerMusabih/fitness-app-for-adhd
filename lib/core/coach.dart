import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/foods_db.dart';
import '../core/food_parser.dart';
import '../core/models.dart';
import '../core/rpg.dart';

/// Coach reply with optional side-effects (food to log, etc.).
class CoachReply {
  final String text;
  final List<LoggedFood> foodsToLog;
  final bool askedPortion;
  final bool celebration;
  final bool encouragement;
  CoachReply({
    required this.text,
    this.foodsToLog = const [],
    this.askedPortion = false,
    this.celebration = false,
    this.encouragement = false,
  });
}

class CoachContext {
  final PlayerProfile profile;
  final double currentWeight;
  final DailyLog todayLog;
  final double calorieGoal;
  final double proteinGoal;
  final int waterGoalMl;
  final List<Quest> todayQuests;
  final List<WeightEntry> weightHistory;
  final int streak;
  final List<ChatMessage> history;
  const CoachContext({
    required this.profile,
    required this.currentWeight,
    required this.todayLog,
    required this.calorieGoal,
    required this.proteinGoal,
    required this.waterGoalMl,
    required this.todayQuests,
    required this.weightHistory,
    required this.streak,
    required this.history,
  });
}

/// Project Reforge AI Coach.
/// Uses a deterministic local engine by default, and can call OpenAI GPT
/// when an API key is configured (see [AiConfig.openAiKey]).
class AiCoach {
  FoodItem? pendingFood;
  String? pendingFoodName;

  static const Map<String, String> _alternatives = {
    'biryani': 'grilled chicken tikka with a small serving of rice — same flavor, half the oil',
    'paratha': 'a whole-wheat chapati or multigrain roti',
    'samosa': 'roasted chana chaat or baked samosas',
    'karahi': 'a lighter chicken karahi with less oil, or a tikka-style dry chicken',
    'nihari': 'a small bowl of nihari with extra lemon, or lean beef soup',
    'haleem': 'a small bowl of haleem (it\'s actually high protein!)',
    'lassi': 'low-fat lassi or plain buttermilk (chaas)',
    'chai': 'chai with one spoon of sugar, or green tea',
    'cola': 'diet soda, or sparkling water with lemon',
    'soda': 'diet soda, or sparkling water with lemon',
    'burger': 'a grilled chicken burger with a whole-grain bun and a side salad',
    'fries': 'baked sweet potato wedges or roasted chickpeas',
    'jalebi': 'a bowl of fruit or a small piece of dark chocolate',
    'gulab jamun': 'Greek yogurt with a little honey',
    'pizza': 'thin-crust vegetable pizza, half the cheese',
    'naan': 'a chapati or roti',
    'fried chicken': 'grilled chicken with skin removed',
    'ice cream': 'frozen yogurt or kheer (small bowl)',
    'cold drink': 'diet drink or sparkling water',
    'instant noodles': 'whole-wheat noodles with extra vegetables and an egg',
  };

  static String _alt(String food) {
    for (final e in _alternatives.entries) {
      if (food.contains(e.key)) return e.value;
    }
    return 'a lighter version with less oil and more vegetables';
  }

  /// Whether an OpenAI key is available for true LLM replies.
  static const bool useLlm = false;

  Future<CoachReply> reply(CoachContext ctx, String message) async {
    if (useLlm) {
      try {
        return await _llmReply(ctx, message);
      } catch (_) {
        // fall through to local engine
      }
    }
    return _localReply(ctx, message);
  }

  Future<CoachReply> _llmReply(CoachContext ctx, String message) async {
    final system = _systemPrompt(ctx);
    final resp = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AiConfig.openAiKey}',
      },
      body: jsonEncode({
        'model': AiConfig.model,
        'messages': [
          {'role': 'system', 'content': system},
          ...ctx.history.map((m) => {'role': m.role == 'coach' ? 'assistant' : 'user', 'content': m.text}).toList(),
          {'role': 'user', 'content': message},
        ],
      }),
    );
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final text = (data['choices'] as List).first['message']['text'] as String;
    return CoachReply(text: text);
  }

  String _systemPrompt(CoachContext ctx) {
    final name = ctx.profile.name;
    return '''
You are "Coach Reforge", a supportive personal trainer and nutritionist in a weight-loss RPG called Project Reforge. The user is $name, a ${ctx.profile.age}-year-old ${ctx.profile.gender} beginner from ${ctx.profile.country}, ${ctx.profile.heightCm}cm tall, currently ${ctx.currentWeight}kg, goal ${ctx.profile.goalWeightKg}kg. They work out at home, no equipment. Pakistani food context.
Today's calorie goal: ${ctx.calorieGoal.round()} kcal, protein ${ctx.proteinGoal.round()}g, water ${ctx.waterGoalMl}ml. Current streak: ${ctx.streak} days.
Be warm, motivational, and brief (under 120 words). Never shame. If they ate something, acknowledge it and give macros + a small next-step. If they describe food, estimate calories. If they ask for meal ideas, give practical Pakistani fat-loss options. If they ask about exercise, explain bodyweight home exercises. If they log unhealthy food, say something like "One meal doesn't ruin your progress. Let's win the next one." Keep it game-like: XP, levels, streaks.
''';
  }

  // ---------------- Local engine ----------------
  CoachReply _localReply(CoachContext ctx, String message) {
    final m = message.toLowerCase().trim();

    // ---- Portion follow-up (e.g. "1 plate" after "I ate biryani") ----
    if (pendingFood != null) {
      final parsed = FoodParser.parseFoods(m, context: pendingFood);
      if (parsed.isNotEmpty) {
        final logged = parsed;
        pendingFood = null;
        final kcal = FoodParser.sumCalories(logged);
        final protein = logged.fold(0.0, (s, f) => s + f.protein);
        final carbs = logged.fold(0.0, (s, f) => s + f.carbs);
        final fat = logged.fold(0.0, (s, f) => s + f.fat);
        final remaining = ctx.calorieGoal - ctx.todayLog.caloriesConsumed - kcal;
        final unit = logged.length == 1 ? '${logged.first.quantity.round()}g' : '${logged.length} items';
        return CoachReply(
          text: '✅ Logged $unit of ${pendingFoodName}.\n\n'
              '🍚 ${kcal.round()} kcal  ·  🍗 ${protein.round()}g protein  ·  🌾 ${carbs.round()}g carbs  ·  🧈 ${fat.round()}g fat\n\n'
              'Remaining calories today: ${remaining.round()} kcal.\n\n'
              '${remaining > 0 ? "You've got room — keep going, warrior! +${(kcal / 10).round()} XP vibe." : "That fills today's budget. Next meal: prioritize protein."}',
          foodsToLog: logged,
          celebration: true,
        );
      }
    }

    // ---- Food logging ----
    final parsed = FoodParser.parseFoods(m);
    final unmatched = FoodParser.unmatchedSegments(m);
    if (parsed.isNotEmpty && unmatched.isEmpty) {
      final kcal = FoodParser.sumCalories(parsed);
      final protein = parsed.fold(0.0, (s, f) => s + f.protein);
      final carbs = parsed.fold(0.0, (s, f) => s + f.carbs);
      final fat = parsed.fold(0.0, (s, f) => s + f.fat);
      final hadExplicitQuantity = RegExp(r'(\d+(?:\.\d+)?)\s*(g|grams?|kg|ml|plate|glass|cup|bowl|piece|slice|packet|can|bottle|tbsp)|\bhalf\b|\ba\b|\ban\b').hasMatch(m);

      if (!hadExplicitQuantity && parsed.length == 1) {
        // "I ate biryani" -> ask how much
        final item = parsed.first;
        pendingFood = FoodDatabase.byId(item.foodId);
        pendingFoodName = item.name;
        return CoachReply(
          text: 'Nice — ${item.name}! 🍽️ How much did you have? Say "1 plate", "half plate", "1 bowl", or "200g".',
          askedPortion: true,
        );
      }

      final remaining = ctx.calorieGoal - ctx.todayLog.caloriesConsumed - kcal;
      final proteinLeft = ctx.proteinGoal - ctx.todayLog.proteinConsumed - protein;
      return CoachReply(
        text: '✅ Logged ${parsed.length} item(s): ${parsed.map((p) => '${p.name} (${p.quantity.round()}g)').join(', ')}.\n\n'
            '🍚 ${kcal.round()} kcal  ·  🍗 ${protein.round()}g protein  ·  🌾 ${carbs.round()}g carbs  ·  🧈 ${fat.round()}g fat\n\n'
            'Remaining: ${remaining.round()} kcal · ${proteinLeft.round()}g protein.\n'
            '${remaining > 0 ? "+${math_max(5, (kcal / 20).round())} XP. Fuel logged, warrior!" : "That's today's budget. Make your next meal mostly protein and veggies."}',
        foodsToLog: parsed,
        celebration: true,
      );
    }

    // ---- Nutrition questions ----
    if (m.contains('calorie') || m.contains('kcal') || (m.contains('how much') && m.contains('protein')) || m.contains('nutrition')) {
      final item = _findFoodIn(m);
      if (item != null) {
        return CoachReply(
          text: 'Nutrition per 100g of ${item.name}:\n\n'
              '🍚 ${item.calories.round()} kcal · 🍗 ${item.protein.round()}g protein · 🌾 ${item.carbs.round()}g carbs · 🧈 ${item.fat.round()}g fat\n\n'
              'One serving (~${item.unitWeightG ?? 200}g) ≈ ${(item.calories * (item.unitWeightG ?? 200) / 100).round()} kcal. Track it in the log!',
        );
      }
      return CoachReply(
        text: 'In general, aim for:\n\n'
            '• 1.6–2.0g protein per kg of body weight\n'
            '• Most carbs around workouts\n'
            '• 25–30g fiber daily (daal, chana, oats)\n\n'
            'Your current targets: ${ctx.calorieGoal.round()} kcal and ${ctx.proteinGoal.round()}g protein today. 💪',
      );
    }

    if (m.contains('protein')) {
      return CoachReply(
        text: 'Protein is your best friend right now! 🍗 High-protein Pakistani picks:\n\n'
            '• Chicken breast/tikka — 31g per 100g\n'
            '• Daal & chana — 8-9g per cup\n'
            '• Eggs — 13g each\n'
            '• Dahi (yogurt) — 3.5g per 100g\n'
            '• Whey shake — 24g\n\n'
            'Target today: ${ctx.proteinGoal.round()}g. You\'re at ${ctx.todayLog.proteinConsumed.round()}g. Keep stacking!',
      );
    }

    if (m.contains('healthier') || m.contains('alternative') || m.contains('instead of') || m.contains('replace')) {
      final item = _findFoodIn(m);
      if (item != null) {
        return CoachReply(text: 'Good question! Instead of ${item.name}, try ${_alt(item.name.toLowerCase())}. Same cravings, fewer calories, more progress. 🎯');
      }
      return CoachReply(text: 'A simple swap rule: replace fried with grilled, sugary with fruit, and heavy oil with 1 spoon. For example, paratha ➜ chapati, samosa ➜ roasted chana, cola ➜ sparkling water. You won\'t even miss it! 🌟');
    }

    // ---- Workout questions ----
    if (m.contains('workout') || m.contains('exercise') || m.contains('push up') || m.contains('squat') || m.contains('how do i') || m.contains('routine')) {
      if (m.contains('push')) {
        return CoachReply(
          text: 'Push-ups: place hands shoulder-width, body straight, lower chest to floor, push back. 🫡\n\n'
              'Beginner plan: 3 sets of knee push-ups (5 reps), rest 60s. Add 1 rep every 2 days.\n\n'
              '• Chest, shoulders, triceps\n'
              '• Do them after waking for a quick boost',
        );
      }
      if (m.contains('squat')) {
        return CoachReply(text: 'Squats: feet shoulder-width, sit back like a chair, thighs parallel, stand up. 🦵\n\nBeginner: 3 sets of 10. Great for legs, knees and burning belly fat. Hold a wall for balance first if needed.');
      }
      if (m.contains('plank')) {
        return CoachReply(text: 'Plank: forearms on floor, body in a straight line, squeeze your core. ⏱️\n\nStart with 20 seconds, build to 60s. 3 rounds. This is the belly-fat killer.');
      }
      return CoachReply(
        text: 'Here\'s a beginner home workout (no equipment, ~20 min):\n\n'
            '1. Warm-up — 3 min marching in place 🔥\n'
            '2. Squats — 3×10 🦵\n'
            '3. Knee push-ups — 3×5 💪\n'
            '4. Wall plank — 3×20s ⏱️\n'
            '5. Lunges — 3×8 each leg 🚶\n'
            '6. Stretch — 3 min 🧘\n\n'
            'Tap "Start Workout" on the dashboard and earn the XP!',
      );
    }

    // ---- Meal ideas ----
    if (m.contains('meal idea') || m.contains('what should i eat') || m.contains('meal plan') || m.contains('recipe') || m.contains('menu') || m.contains('hungry')) {
      return CoachReply(
        text: 'Pakistani fat-loss menu (easy & budget):\n\n'
            '🌅 Breakfast: 2-egg omelette + 1 chapati + chai (less sugar)\n'
            '☀️ Lunch: daal chawal (1 plate) + salad\n'
            '🍢 Snack: roasted chana or dahi\n'
            '🌙 Dinner: chicken tikka / grilled chicken + veggies\n'
            '💧 Hydration: ${ctx.waterGoalMl}ml water\n\n'
            'Total ≈ ${(ctx.calorieGoal - 200).round()} kcal, high protein. Want a grocery list?',
      );
    }

    if (m.contains('grocery') || m.contains('shopping list') || m.contains('store list')) {
      return CoachReply(
        text: '🛒 Budget grocery list:\n\n'
            '• Eggs (2 dozen) 🥚\n'
            '• Chicken breast (1kg) 🍗\n'
            '• Daal / chana (1kg) 🫘\n'
            '• Oats (500g) 🌾\n'
            '• Yogurt (dahi) 🥛\n'
            '• Bananas & apples 🍌\n'
            '• Spinach, tomatoes, onions 🥬\n'
            '• Chapati atta (whole wheat)\n'
            '• Green tea 🍵\n\n'
            'Keeps you on track for under a few thousand PKR.',
      );
    }

    // ---- Prediction / timeline ----
    if (m.contains('when will i') || m.contains('predict') || m.contains('timeline') || m.contains('how long') || m.contains('reach') || m.contains('goal weight')) {
      final date = RpgEngine.predictedGoalDate(ctx.profile, ctx.currentWeight);
      final remaining = ctx.currentWeight - ctx.profile.goalWeightKg;
      final weeks = (remaining / 0.45).ceil();
      return CoachReply(
        text: '📊 Projection (estimate):\n\n'
            'You\'re ${ctx.currentWeight}kg, goal ${ctx.profile.goalWeightKg}kg → ${remaining.toStringAsFixed(1)}kg to go.\n'
            'At a sustainable ~0.5kg/week, you reach your goal in ~$weeks weeks.\n\n'
            '📅 Predicted goal date: ${_fmtDate(date)}\n\n'
            'Consistency beats speed. Every logged meal and workout moves the date closer! ⏳',
      );
    }

    // ---- Weight trend / inconsistent trend ----
    if (m.contains('weight') || m.contains('scale') || m.contains('stuck') || m.contains('plateau')) {
      if (m.contains('stuck') || m.contains('plateau')) {
        return CoachReply(
          text: 'The Plateau is the hardest boss. 🗿 It\'s normal — your body adapts.\n\n'
              'Beat it by:\n'
              '• Adding 2,000 more steps/day\n'
              '• Eating 20g more protein\n'
              '• Sleeping 30 min earlier\n'
              '• One extra water glass\n\n'
              'The scale will move again. Trust the process.',
        );
      }
      if (ctx.weightHistory.length >= 2) {
        final last = ctx.weightHistory.last.kg;
        return CoachReply(
          text: 'Latest weigh-in: ${last}kg (from ${ctx.profile.startWeightKg}kg start).\n\n'
              'Total lost: ${(ctx.profile.startWeightKg - last).toStringAsFixed(1)}kg. That\'s worth real XP! Keep trending down — log weight weekly, same time, morning after bathroom for accuracy. ⚖️',
        );
      }
      return CoachReply(text: 'Log your weight weekly (same day, morning) to see the real trend. 1-2kg swings from water are normal — never judge a single day. ⚖️');
    }

    // ---- Failure / emergency mode ----
    final failureWords = ['fail', 'missed', 'gave up', 'give up', 'cheat', 'overate', 'over ate', 'ate too much', 'binge', 'bad day', 'ruined', 'i ate pizza', 'fast food', 'mcdonald', 'kfc'];
    if (failureWords.any(m.contains)) {
      final parsed2 = FoodParser.parseFoods(m);
      if (parsed2.isNotEmpty) {
        final kcal = FoodParser.sumCalories(parsed2);
        return CoachReply(
          text: 'Logged ${parsed2.length} item(s) (≈${kcal.round()} kcal).\n\n'
              'One meal doesn\'t ruin your progress. Let\'s win the next one. 💛\n\n'
              '• Drink a glass of water\n'
              '• Make your next meal protein + veggies\n'
              '• 10-minute walk resets the momentum\n\n'
              'Your streak and effort are worth more than one plate. Keep going.',
          foodsToLog: parsed2,
          encouragement: true,
        );
      }
      return CoachReply(
        text: 'Hey, no shame here. One missed day is a chapter, not the story. 📖\n\n'
            '• Missed workout? Do 10 squats right now.\n'
            '• Over calories? Drink water and walk.\n'
            '• Broke a streak? Start a new one — they love a comeback.\n\n'
            'Reset is part of the game. Level up with the next move. 💪',
        encouragement: true,
      );
    }

    // ---- Wins / celebration ----
    final winWords = ['did my workout', 'workout done', 'won', 'streak', 'water', 'drank', 'walked', 'hitt', 'good day', 'i did'];
    if (winWords.any(m.contains)) {
      if (m.contains('streak')) {
        return CoachReply(text: '🔥 ${ctx.streak} days on fire! Streaks are the real boss battles — you\'re winning the war of consistency. Every day adds XP to your discipline skill.');
      }
      if (m.contains('water') || m.contains('drank')) {
        return CoachReply(text: '💧 Hydration hero! You\'re at ${ctx.todayLog.waterMl}ml of ${ctx.waterGoalMl}ml. Water is literally flushing fat. Keep the glass full!');
      }
      return CoachReply(text: '🎉 THAT\'S the energy! Every completed action is a level-up chip. Keep stacking wins and your future self will thank you. What\'s next?');
    }

    // ---- Greetings ----
    if (m.contains('hello') || m.contains('hi ') || m == 'hi' || m == 'hello' || m == 'hey' || m.contains('assalam')) {
      return CoachReply(
        text: 'Salam, ${ctx.profile.name}! 🎮 Coach Reforge here.\n\n'
            'Today: ${ctx.calorieGoal.round()} kcal budget, ${ctx.proteinGoal.round()}g protein, ${ctx.waterGoalMl ~/ 1000}L water, ${ctx.streak}-day streak.\n\n'
            'Tell me what you ate, ask for meal ideas, a workout, or how to beat today\'s boss. Let\'s play!',
      );
    }

    // ---- Mood / check-in ----
    if (m.contains('mood') || m.contains('tired') || m.contains('lazy') || m.contains('sad') || m.contains('no motivation')) {
      return CoachReply(
        text: 'Motivation comes and goes — discipline is the level-up. 🎯\n\n'
            'Try the 5-minute rule: do just 5 minutes of walking or stretching. 9 times out of 10 you\'ll keep going.\n\n'
            'Even a tiny action = XP. And remember: Future You is watching, and they\'re proud of you. 💛',
        encouragement: true,
      );
    }

    // ---- Fallback ----
    return CoachReply(
      text: 'Got it! Here\'s what I can help with:\n\n'
          '🍽️ "I ate 2 eggs and 3 chapatis" — log & count macros\n'
          '📋 "Meal ideas" — Pakistani fat-loss menu\n'
          '💪 "Workout" — home, no equipment\n'
          '🛒 "Grocery list" — budget shopping\n'
          '📅 "When will I reach 85kg?" — prediction\n'
          '💊 "Healthier alternative for paratha"\n\n'
          'Try one of those!',
    );
  }

  FoodItem? _findFoodIn(String m) {
    for (final f in FoodDatabase.all) {
      final candidates = {f.name.toLowerCase(), ...f.aliases.map((a) => a.toLowerCase())};
      for (final c in candidates) {
        if (c.length > 2 && m.contains(c)) return f;
      }
    }
    return null;
  }

  static String _fmtDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

/// Placeholder config for the optional OpenAI integration.
class AiConfig {
  static const String openAiKey = ''; // set your key to enable GPT coach
  static const String model = 'gpt-5.5';
}

int math_max(int a, int b) => a > b ? a : b;
