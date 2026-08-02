import '../core/foods_db.dart';
import '../core/models.dart';

/// Natural-language food logging parser.
/// Understands: "2 eggs and 3 chapatis", "half a pizza", "1 chicken burger",
/// "200g chicken breast", "1 plate biryani", "glass of lassi", "I ate biryani".
class FoodParser {
  FoodParser._();

  static const Map<String, double> _numberWords = {
    'a': 1, 'an': 1, 'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
    'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10, 'dozen': 12,
    'few': 2, 'couple': 2, 'some': 1,
  };

  static const Map<String, double> _fractions = {
    'half': 0.5, 'quarter': 0.25, 'third': 0.33, 'two-thirds': 0.66,
    'double': 2.0, 'triple': 3.0, 'full': 1.0,
  };

  static const Map<String, double> _containerGrams = {
    'plate': 400, 'thali': 400, 'bowl': 300, 'cup': 200, 'glass': 250,
    'tumbler': 250, 'piece': 40, 'slice': 30, 'scoop': 30, 'serving': 200,
    'packet': 80, 'pouch': 80, 'can': 330, 'bottle': 500, 'tbsp': 15,
    'chicken': 0, // guard against treating food words as units
  };

  static double _defaultServing(FoodItem f) {
    switch (f.category) {
      case 'pakistani':
        return 200;
      case 'street':
        return 120;
      case 'fastfood':
        return 150;
      default:
        return 100;
    }
  }

  static String _normalize(String s) {
    var t = s.toLowerCase();
    t = t.replaceAll(RegExp(r'[^a-z0-9\s%]'), ' ');
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t;
  }

  static double _numFromWord(String w) {
    if (_numberWords.containsKey(w)) return _numberWords[w]!;
    if (_fractions.containsKey(w)) return _fractions[w]!;
    return -1;
  }

  /// Splits input into segments: "2 eggs and 3 chapatis" -> ["2 eggs","3 chapatis"].
  static List<String> _segments(String s) {
    final parts = s
        .replaceAll(RegExp(r'\b(and|then|also)\b'), ',')
        .split(RegExp(r'[,+;]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return parts;
  }

  /// Longest matching food alias contained in the segment.
  static (FoodItem?, String matchedAlias) _matchFood(String segment, {FoodItem? context}) {
    FoodItem? best;
    int bestLen = 0;
    String bestAlias = '';
    for (final f in FoodDatabase.all) {
      final candidates = {f.name, ...f.aliases};
      for (final a in candidates) {
        final aNorm = _normalize(a);
        if (aNorm.length < 2) continue;
        if (segment.contains(aNorm) && aNorm.length > bestLen) {
          best = f;
          bestLen = aNorm.length;
          bestAlias = aNorm;
        }
      }
    }
    // Fallback to context food (e.g. follow-up "1 plate" after "biryani").
    if (best == null && context != null) {
      return (context, '');
    }
    return (best, bestAlias);
  }

  static List<LoggedFood> parseFoods(String input, {FoodItem? context}) {
    final text = _normalize(input);
    if (text.isEmpty) return [];
    final out = <LoggedFood>[];

    for (final segment in _segments(text)) {
      final (item, _) = _matchFood(segment, context: context);
      if (item == null) continue;

      var quantity = 1.0; // number of units / containers
      var explicitGrams = -1.0;
      var unitWord = '';

      // "200g chicken" | "200 grams" | "0.5 kg" | "250ml"
      final gramMatch = RegExp(r'(\d+(?:\.\d+)?)\s*(g|gm|grams|gram|kg|kgs|ml|mls|liter|litre|liters|ltr)').firstMatch(segment);
      if (gramMatch != null) {
        final v = double.parse(gramMatch.group(1)!);
        final u = gramMatch.group(2)!;
        explicitGrams = u.startsWith('k') ? v * 1000 : v;
      }

      // "1 plate", "half a pizza", "two eggs"
      final wordNumMatch = RegExp(r'(?:^|\s)([a-zA-Z]+(?:-[a-zA-Z]+)?)(?=\s|$)').firstMatch(segment);
      // leading number
      final digitMatch = RegExp(r'^(\d+(?:\.\d+)?)').firstMatch(segment);

      if (digitMatch != null) {
        quantity = double.parse(digitMatch.group(1)!);
      } else if (wordNumMatch != null) {
        final w = _numFromWord(wordNumMatch.group(1)!);
        if (w > 0) quantity = w;
        if (w == 0.5 && wordNumMatch.group(1) == 'half') {
          // "half a plate" handled below by container.
        }
      }

      // container/unit word inside segment
      for (final entry in _containerGrams.entries) {
        if (entry.key == 'chicken') continue;
        if (segment.split(' ').contains(entry.key)) {
          unitWord = entry.key;
          break;
        }
      }
      // "a plate of X" / "half plate of X" without number -> quantity stays

      // compute grams
      double grams;
      if (explicitGrams > 0) {
        grams = explicitGrams;
      } else if (item.unitItem && item.unitWeightG != null) {
        grams = quantity * item.unitWeightG!;
      } else if (unitWord.isNotEmpty) {
        grams = quantity * (_containerGrams[unitWord] ?? 100);
      } else {
        grams = quantity * _defaultServing(item);
      }

      final factor = grams / 100.0;
      out.add(LoggedFood(
        foodId: item.id,
        name: item.name,
        quantity: grams,
        calories: item.calories * factor,
        protein: item.protein * factor,
        carbs: item.carbs * factor,
        fat: item.fat * factor,
      ));
    }
    return out;
  }

  /// Returns foods with no recognizable item (for "not found" handling).
  static List<String> unmatchedSegments(String input, {FoodItem? context}) {
    final text = _normalize(input);
    if (text.isEmpty) return const [];
    final unmatched = <String>[];
    for (final segment in _segments(text)) {
      final (item, _) = _matchFood(segment, context: context);
      if (item == null) unmatched.add(segment);
    }
    return unmatched;
  }

  static double sumCalories(List<LoggedFood> foods) =>
      foods.fold(0.0, (s, f) => s + f.calories);

  /// Number words used for interactive "how much?" questions.
  static const List<String> portionPhrases = [
    '1 plate', 'half plate', '1 bowl', '1 glass', '1 cup', '2 pieces',
    'half piece', '100g', '200g', '1 serving', '1 slice', '1 packet',
  ];
}
