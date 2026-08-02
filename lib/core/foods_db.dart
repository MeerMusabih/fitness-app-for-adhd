import '../core/models.dart';

/// Project Reforge food database — Pakistani foods + common USDA items.
/// Macros are per 100 g. Items flagged [unitItem] report per-single-unit macros.
class FoodDatabase {
  FoodDatabase._();

  static final Map<String, FoodItem> _byId = {for (final f in all) f.id: f};
  static final List<FoodItem> _searchIndex = _buildSearchIndex();

  static final List<FoodItem> all = [
    // ---------------- Pakistani classics ----------------
    const FoodItem(id: 'biryani_chicken', name: 'Chicken Biryani', calories: 175, protein: 8, carbs: 22, fat: 6, category: 'pakistani', aliases: ['biryani', 'chicken biryani', 'kacchi biryani']),
    const FoodItem(id: 'biryani_beef', name: 'Beef Biryani', calories: 210, protein: 9, carbs: 22, fat: 9, category: 'pakistani', aliases: ['beef biryani', 'yakhni biryani']),
    const FoodItem(id: 'biryani_plate', name: 'Biryani (1 plate)', calories: 175, protein: 8, carbs: 22, fat: 6, category: 'pakistani', aliases: ['plate biryani', 'biryani plate'], unitItem: true, unitWeightG: 400),
    const FoodItem(id: 'karahi_chicken', name: 'Chicken Karahi', calories: 165, protein: 16, carbs: 4, fat: 9, category: 'pakistani', aliases: ['karahi', 'chicken karahi']),
    const FoodItem(id: 'karahi_beef', name: 'Beef Karahi', calories: 210, protein: 15, carbs: 4, fat: 15, category: 'pakistani', aliases: ['beef karahi']),
    const FoodItem(id: 'nihari', name: 'Nihari', calories: 180, protein: 14, carbs: 6, fat: 11, category: 'pakistani', aliases: ['nihari', 'beef nihari']),
    const FoodItem(id: 'haleem', name: 'Haleem', calories: 145, protein: 12, carbs: 15, fat: 4, category: 'pakistani', aliases: ['haleem', 'kakori']),
    const FoodItem(id: 'daal_daal', name: 'Daal (lentils)', calories: 120, protein: 8, carbs: 20, fat: 2, category: 'pakistani', aliases: ['daal', 'dal', 'lentils', 'daal chawal']),
    const FoodItem(id: 'chapati', name: 'Chapati / Roti', calories: 105, protein: 3, carbs: 18, fat: 2, category: 'pakistani', aliases: ['chapati', 'roti', 'phulka', 'taftan roti'], unitItem: true, unitWeightG: 40),
    const FoodItem(id: 'naan', name: 'Naan', calories: 280, protein: 8, carbs: 46, fat: 7, category: 'pakistani', aliases: ['naan', 'garlic naan', 'butter naan'], unitItem: true, unitWeightG: 80),
    const FoodItem(id: 'paratha', name: 'Paratha', calories: 330, protein: 6, carbs: 40, fat: 16, category: 'pakistani', aliases: ['paratha', 'parata', 'parantha', 'alu paratha'], unitItem: true, unitWeightG: 100),
    const FoodItem(id: 'samosa', name: 'Samosa', calories: 190, protein: 4, carbs: 20, fat: 11, category: 'street', aliases: ['samosa', 'samoosa'], unitItem: true, unitWeightG: 50),
    const FoodItem(id: 'samosa_chat', name: 'Samosa Chaat', calories: 250, protein: 6, carbs: 30, fat: 12, category: 'street', aliases: ['samosa chat', 'samosa chaat']),
    const FoodItem(id: 'seekh_kebab', name: 'Seekh Kebab', calories: 220, protein: 16, carbs: 4, fat: 15, category: 'pakistani', aliases: ['seekh kebab', 'kebab', 'seekh kabab'], unitItem: true, unitWeightG: 50),
    const FoodItem(id: 'chicken_tikka', name: 'Chicken Tikka', calories: 145, protein: 21, carbs: 3, fat: 5, category: 'pakistani', aliases: ['tikka', 'chicken tikka', 'tikka boti'], unitItem: true, unitWeightG: 60),
    const FoodItem(id: 'chicken_tikka_boti', name: 'Chicken Tikka Boti', calories: 150, protein: 22, carbs: 3, fat: 5, category: 'pakistani', aliases: ['tikka boti', 'malai boti', 'chicken boti']),
    const FoodItem(id: 'chapli_kebab', name: 'Chapli Kebab', calories: 240, protein: 15, carbs: 8, fat: 17, category: 'pakistani', aliases: ['chapli kebab', 'chapli kabab'], unitItem: true, unitWeightG: 80),
    const FoodItem(id: 'korma_chicken', name: 'Chicken Korma', calories: 220, protein: 15, carbs: 8, fat: 15, category: 'pakistani', aliases: ['korma', 'chicken korma', 'chicken qorma']),
    const FoodItem(id: 'aloo_gosht', name: 'Aloo Gosht', calories: 170, protein: 10, carbs: 12, fat: 9, category: 'pakistani', aliases: ['aloo gosht', 'aloo mutton']),
    const FoodItem(id: 'pulao', name: 'Pulao / Yakhni Pulao', calories: 160, protein: 6, carbs: 22, fat: 5, category: 'pakistani', aliases: ['pulao', 'pulao rice', 'yakhni pulao', 'chicken pulao']),
    const FoodItem(id: 'rice_cooked', name: 'Cooked White Rice', calories: 130, protein: 2.7, carbs: 28, fat: 0.3, category: 'pakistani', aliases: ['rice', 'chawal', 'white rice', 'steamed rice']),
    const FoodItem(id: 'daal_chawal', name: 'Daal Chawal', calories: 140, protein: 6, carbs: 24, fat: 2, category: 'pakistani', aliases: ['daal chawal', 'dal chawal']),
    const FoodItem(id: 'chana_chaat', name: 'Chana Chaat', calories: 180, protein: 6, carbs: 24, fat: 7, category: 'street', aliases: ['chana chaat', 'chanay ki chaat', 'chana chat']),
    const FoodItem(id: 'pakora', name: 'Pakora', calories: 260, protein: 5, carbs: 20, fat: 18, category: 'street', aliases: ['pakora', 'pakora onion', 'bhaji'], unitItem: true, unitWeightG: 35),
    const FoodItem(id: 'jalebi', name: 'Jalebi', calories: 340, protein: 3, carbs: 70, fat: 5, category: 'street', aliases: ['jalebi', 'jilebi'], unitItem: true, unitWeightG: 40),
    const FoodItem(id: 'gulab_jamun', name: 'Gulab Jamun', calories: 320, protein: 4, carbs: 55, fat: 10, category: 'street', aliases: ['gulab jamun'], unitItem: true, unitWeightG: 40),
    const FoodItem(id: 'kheer', name: 'Kheer', calories: 190, protein: 5, carbs: 30, fat: 6, category: 'pakistani', aliases: ['kheer', 'rice pudding'], unitItem: true, unitWeightG: 150),
    const FoodItem(id: 'halwa_poori', name: 'Halwa Poori', calories: 380, protein: 6, carbs: 55, fat: 15, category: 'pakistani', aliases: ['halwa puri', 'halwa poori', 'poori']),
    const FoodItem(id: 'sajji', name: 'Sajji / Balochi Chicken', calories: 190, protein: 20, carbs: 2, fat: 11, category: 'pakistani', aliases: ['sajji', 'balochi sajji']),
    const FoodItem(id: 'dahi_baray', name: 'Dahi Baray', calories: 190, protein: 6, carbs: 24, fat: 8, category: 'street', aliases: ['dahi baray', 'dahi bhalla', 'dahi vada']),
    const FoodItem(id: 'lassi', name: 'Lassi', calories: 120, protein: 4, carbs: 14, fat: 5, category: 'pakistani', aliases: ['lassi', 'sweet lassi', 'mango lassi', 'salted lassi'], unitItem: true, unitWeightG: 250),
    const FoodItem(id: 'tea_milk', name: 'Chai / Doodh Patti', calories: 70, protein: 2, carbs: 8, fat: 3, category: 'pakistani', aliases: ['chai', 'tea', 'doodh patti', 'karak chai', 'chai tea'], unitItem: true, unitWeightG: 150),
    const FoodItem(id: 'coffee_milk', name: 'Coffee with Milk', calories: 60, protein: 2, carbs: 8, fat: 2, category: 'pakistani', aliases: ['coffee', 'cappuccino', 'milk coffee'], unitItem: true, unitWeightG: 200),
    const FoodItem(id: 'cola', name: 'Soda / Cola', calories: 42, protein: 0, carbs: 10.6, fat: 0, category: 'fastfood', aliases: ['coke', 'cola', 'soda', 'soft drink', 'pepsi', '7up', 'sprite'], unitItem: true, unitWeightG: 330),
    const FoodItem(id: 'sugary_drink', name: 'Sugary Drink', calories: 45, protein: 0, carbs: 11, fat: 0, category: 'fastfood', aliases: ['sugary drink', 'juice', 'packaged juice']),

    // ---------------- Fast food / street ----------------
    const FoodItem(id: 'chicken_burger', name: 'Chicken Burger', calories: 520, protein: 22, carbs: 45, fat: 28, category: 'fastfood', aliases: ['burger', 'chicken burger', 'burger'], unitItem: true, unitWeightG: 180),
    const FoodItem(id: 'zinger_burger', name: 'Zinger Burger', calories: 590, protein: 25, carbs: 50, fat: 32, category: 'fastfood', aliases: ['zinger', 'zinger burger', 'kfc zinger'], unitItem: true, unitWeightG: 200),
    const FoodItem(id: 'beef_burger', name: 'Beef Burger', calories: 540, protein: 24, carbs: 42, fat: 30, category: 'fastfood', aliases: ['beef burger', 'mcdonald burger', 'whopper'], unitItem: true, unitWeightG: 190),
    const FoodItem(id: 'pizza_slice', name: 'Pizza Slice', calories: 270, protein: 12, carbs: 32, fat: 11, category: 'fastfood', aliases: ['pizza', 'pizza slice', 'pizza pepperoni'], unitItem: true, unitWeightG: 100),
    const FoodItem(id: 'fries', name: 'French Fries', calories: 312, protein: 4, carbs: 41, fat: 15, category: 'fastfood', aliases: ['fries', 'chips', 'french fries', 'aloo fries'], unitItem: true, unitWeightG: 120),
    const FoodItem(id: 'fried_chicken_piece', name: 'Fried Chicken (1 piece)', calories: 260, protein: 18, carbs: 12, fat: 16, category: 'fastfood', aliases: ['fried chicken', 'kfc', 'chicken piece', 'fried chicken piece'], unitItem: true, unitWeightG: 100),
    const FoodItem(id: 'shawarma', name: 'Shawarma', calories: 350, protein: 18, carbs: 35, fat: 16, category: 'street', aliases: ['shawarma', 'chicken shawarma'], unitItem: true, unitWeightG: 180),
    const FoodItem(id: 'roll_paratha', name: 'Chicken Paratha Roll', calories: 420, protein: 18, carbs: 40, fat: 21, category: 'street', aliases: ['roll', 'paratha roll', 'chicken roll', 'kebab roll'], unitItem: true, unitWeightG: 200),
    const FoodItem(id: 'golgappa', name: 'Golgappa / Pani Puri', calories: 45, protein: 1, carbs: 8, fat: 1, category: 'street', aliases: ['golgappa', 'pani puri', 'phulki'], unitItem: true, unitWeightG: 20),
    const FoodItem(id: 'chowmein', name: 'Chowmein', calories: 220, protein: 6, carbs: 34, fat: 7, category: 'street', aliases: ['chowmein', 'noodles', 'chinese noodles']),
    const FoodItem(id: 'bun_kebab', name: 'Bun Kebab', calories: 300, protein: 10, carbs: 35, fat: 13, category: 'street', aliases: ['bun kebab', 'bun kabab'], unitItem: true, unitWeightG: 120),
    const FoodItem(id: 'halwa', name: 'Sohan Halwa', calories: 400, protein: 6, carbs: 60, fat: 16, category: 'pakistani', aliases: ['sohan halwa', 'halwa'], unitItem: true, unitWeightG: 50),
    const FoodItem(id: 'biscuits', name: 'Biscuits / Cookies', calories: 460, protein: 6, carbs: 66, fat: 19, category: 'fastfood', aliases: ['biscuit', 'cookies', 'cookie', 'peek freans']),
    const FoodItem(id: 'chocolate', name: 'Chocolate Bar', calories: 530, protein: 7, carbs: 58, fat: 30, category: 'fastfood', aliases: ['chocolate', 'kitkat', 'dairy milk', 'snickers'], unitItem: true, unitWeightG: 45),
    const FoodItem(id: 'ice_cream', name: 'Ice Cream', calories: 200, protein: 3, carbs: 24, fat: 11, category: 'fastfood', aliases: ['ice cream', 'kulfi'], unitItem: true, unitWeightG: 100),
    const FoodItem(id: 'cold_drink', name: 'Cold Drink (330ml)', calories: 139, protein: 0, carbs: 35, fat: 0, category: 'fastfood', aliases: ['cold drink', 'carbonated drink'], unitItem: true, unitWeightG: 330),
    const FoodItem(id: 'instant_noodles', name: 'Instant Noodles (1 pack)', calories: 380, protein: 8, carbs: 55, fat: 14, category: 'fastfood', aliases: ['noodle pack', 'ramen', 'knorr noodles', 'maggi'], unitItem: true, unitWeightG: 80),

    // ---------------- Protein / meat ----------------
    const FoodItem(id: 'chicken_breast', name: 'Chicken Breast (cooked)', calories: 165, protein: 31, carbs: 0, fat: 3.6, category: 'usda', aliases: ['chicken breast', 'chicken', 'boneless chicken', 'grilled chicken']),
    const FoodItem(id: 'chicken_leg', name: 'Chicken Leg / Thigh', calories: 210, protein: 24, carbs: 0, fat: 12, category: 'usda', aliases: ['chicken leg', 'chicken thigh', 'chicken drumstick']),
    const FoodItem(id: 'beef_mince', name: 'Beef Mince (cooked)', calories: 250, protein: 26, carbs: 0, fat: 16, category: 'pakistani', aliases: ['beef mince', 'keema', 'qeema', 'mince']),
    const FoodItem(id: 'mutton', name: 'Mutton / Lamb (cooked)', calories: 280, protein: 25, carbs: 0, fat: 20, category: 'pakistani', aliases: ['mutton', 'lamb', 'gosht']),
    const FoodItem(id: 'fish', name: 'Fish (cooked)', calories: 190, protein: 24, carbs: 0, fat: 10, category: 'pakistani', aliases: ['fish', 'fish fry', 'karahi fish', 'mahi']),
    const FoodItem(id: 'egg', name: 'Egg (whole)', calories: 155, protein: 13, carbs: 1, fat: 11, category: 'usda', aliases: ['egg', 'eggs', 'boiled egg', 'fried egg'], unitItem: true, unitWeightG: 50),
    const FoodItem(id: 'egg_white', name: 'Egg White', calories: 52, protein: 11, carbs: 1, fat: 0, category: 'usda', aliases: ['egg white', 'egg whites'], unitItem: true, unitWeightG: 33),
    const FoodItem(id: 'whey_protein', name: 'Whey Protein Shake', calories: 120, protein: 24, carbs: 4, fat: 1, category: 'usda', aliases: ['whey', 'protein shake', 'protein powder', 'prolac'], unitItem: true, unitWeightG: 100),

    // ---------------- Carbs / grains ----------------
    const FoodItem(id: 'oats', name: 'Oats (dry)', calories: 389, protein: 17, carbs: 66, fat: 7, category: 'usda', aliases: ['oats', 'oatmeal', 'quaker oats']),
    const FoodItem(id: 'bread_brown', name: 'Brown Bread (1 slice)', calories: 265, protein: 10, carbs: 44, fat: 3, category: 'usda', aliases: ['bread', 'brown bread', 'toast', 'sandwich bread'], unitItem: true, unitWeightG: 30),
    const FoodItem(id: 'pasta', name: 'Pasta (cooked)', calories: 158, protein: 5.8, carbs: 31, fat: 1, category: 'usda', aliases: ['pasta', 'macaroni', 'spaghetti']),
    const FoodItem(id: 'potato', name: 'Potato (boiled)', calories: 87, protein: 2, carbs: 20, fat: 0.1, category: 'usda', aliases: ['potato', 'aloo', 'potatoes', 'boiled potato'], unitItem: true, unitWeightG: 150),
    const FoodItem(id: 'sweet_potato', name: 'Sweet Potato', calories: 86, protein: 1.6, carbs: 20, fat: 0.1, category: 'usda', aliases: ['sweet potato', 'shakarkandi'], unitItem: true, unitWeightG: 130),

    // ---------------- Fruits / veg ----------------
    const FoodItem(id: 'banana', name: 'Banana', calories: 89, protein: 1.1, carbs: 23, fat: 0.3, category: 'usda', aliases: ['banana', 'kela'], unitItem: true, unitWeightG: 120),
    const FoodItem(id: 'apple', name: 'Apple', calories: 52, protein: 0.3, carbs: 14, fat: 0.2, category: 'usda', aliases: ['apple', 'saib'], unitItem: true, unitWeightG: 180),
    const FoodItem(id: 'mango', name: 'Mango', calories: 60, protein: 0.8, carbs: 15, fat: 0.4, category: 'usda', aliases: ['mango', 'aam', 'chaunsa'], unitItem: true, unitWeightG: 200),
    const FoodItem(id: 'orange', name: 'Orange', calories: 47, protein: 0.9, carbs: 12, fat: 0.1, category: 'usda', aliases: ['orange', 'malta'], unitItem: true, unitWeightG: 130),
    const FoodItem(id: 'mixed_veg', name: 'Mixed Vegetables', calories: 65, protein: 2.8, carbs: 13, fat: 0.3, category: 'usda', aliases: ['vegetables', 'veggies', 'sabzi', 'mixed veg']),

    // ---------------- Dairy ----------------
    const FoodItem(id: 'milk', name: 'Milk (full fat)', calories: 61, protein: 3.2, carbs: 4.8, fat: 3.3, category: 'usda', aliases: ['milk', 'doodh', 'full cream milk'], unitItem: true, unitWeightG: 250),
    const FoodItem(id: 'yogurt', name: 'Yogurt / Dahi', calories: 61, protein: 3.5, carbs: 4.7, fat: 3.3, category: 'pakistani', aliases: ['yogurt', 'dahi', 'curd', 'plain yogurt'], unitItem: true, unitWeightG: 200),
    const FoodItem(id: 'paneer', name: 'Paneer', calories: 265, protein: 18, carbs: 4, fat: 20, category: 'usda', aliases: ['paneer', 'cottage cheese']),
    const FoodItem(id: 'cheese', name: 'Cheese (cheddar)', calories: 402, protein: 25, carbs: 1, fat: 33, category: 'usda', aliases: ['cheese', 'cheddar', 'mozzarella']),

    // ---------------- Snacks ----------------
    const FoodItem(id: 'almonds', name: 'Almonds', calories: 579, protein: 21, carbs: 22, fat: 50, category: 'usda', aliases: ['almonds', 'badam'], unitItem: true, unitWeightG: 28),
    const FoodItem(id: 'peanuts', name: 'Peanuts / Moongfali', calories: 567, protein: 26, carbs: 16, fat: 49, category: 'usda', aliases: ['peanuts', 'moongfali', 'groundnuts']),
    const FoodItem(id: 'roasted_chana', name: 'Roasted Chickpeas', calories: 130, protein: 7, carbs: 20, fat: 3, category: 'street', aliases: ['roasted chana', 'chanay', 'bhuna chana']),
    const FoodItem(id: 'diet_coke', name: 'Diet Soda', calories: 0, protein: 0, carbs: 0, fat: 0, category: 'fastfood', aliases: ['diet coke', 'zero coke', 'diet soda'], unitItem: true, unitWeightG: 330),
    const FoodItem(id: 'water', name: 'Water', calories: 0, protein: 0, carbs: 0, fat: 0, category: 'usda', aliases: ['water', 'pani'], unitItem: true, unitWeightG: 250),
  ];

  static List<FoodItem> _buildSearchIndex() {
    final idx = <FoodItem>[];
    for (final f in all) {
      idx.add(f);
      for (final a in f.aliases) {
        if (!idx.any((x) => x.id == f.id && x.name == a)) {
          idx.add(FoodItem(
            id: f.id,
            name: a,
            calories: f.calories,
            protein: f.protein,
            carbs: f.carbs,
            fat: f.fat,
            category: f.category,
            unitItem: f.unitItem,
            unitWeightG: f.unitWeightG,
          ));
        }
      }
    }
    return idx;
  }

  static FoodItem? byId(String id) => _byId[id];

  static List<FoodItem> search(String query, {int limit = 12}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    final matches = _searchIndex.where((f) {
      if (f.name.toLowerCase().contains(q)) return true;
      return f.aliases.any((a) => a.contains(q));
    }).toList();
    // rank: starts-with first
    matches.sort((a, b) {
      final as = a.name.toLowerCase().startsWith(q) ? 0 : 1;
      final bs = b.name.toLowerCase().startsWith(q) ? 0 : 1;
      if (as != bs) return as - bs;
      return a.name.length.compareTo(b.name.length);
    });
    final seen = <String>{};
    final out = <FoodItem>[];
    for (final f in matches) {
      if (seen.add(f.id)) out.add(f);
      if (out.length >= limit) break;
    }
    return out;
  }

  /// Common foods displayed as quick-log chips.
  static const List<String> quickIds = [
    'biryani_plate',
    'chapati',
    'chicken_breast',
    'egg',
    'paratha',
    'karahi_chicken',
    'daal_daal',
    'rice_cooked',
    'samosa',
    'chicken_tikka',
    'lassi',
    'tea_milk',
    'whey_protein',
    'oats',
    'banana',
    'yogurt',
    'cola',
    'water',
  ];

  static List<FoodItem> get quickFoods =>
      quickIds.map((id) => byId(id)).whereType<FoodItem>().toList();
}
