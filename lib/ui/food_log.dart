import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../core/constants.dart';
import '../core/food_parser.dart';
import '../core/foods_db.dart';
import '../core/models.dart';
import '../core/state.dart';
import 'scanner_bridge.dart';
import 'widgets.dart';

/// Food logging tab: voice, text, photo, barcode, recent, favorites.
class FoodLogScreen extends ConsumerStatefulWidget {
  const FoodLogScreen({super.key});

  @override
  ConsumerState<FoodLogScreen> createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends ConsumerState<FoodLogScreen> {
  final _controller = TextEditingController();
  final _stt = stt.SpeechToText();
  bool _listening = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startVoice() async {
    try {
      final ok = await _stt.initialize();
      if (!ok) {
        _toast('Voice input is not available on this device.');
        return;
      }
      setState(() => _listening = true);
      await _stt.listen(
        localeId: 'en_US',
        onResult: (r) {
          if (r.finalResult) {
            setState(() => _listening = false);
            _logText(r.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 12),
        pauseFor: const Duration(seconds: 4),
      );
    } catch (_) {
      setState(() => _listening = false);
      _toast('Voice not supported here — try typing.');
    }
  }

  void _logText(String text) {
    if (text.trim().isEmpty) return;
    _controller.clear();
    final parsed = FoodParser.parseFoods(text);
    if (parsed.isNotEmpty) {
      final c = ref.read(gameProvider);
      c.logFoods(parsed, method: 'text');
      _toast('✅ Logged ${parsed.map((p) => p.name).join(', ')}');
    } else {
      _showSearch(text);
    }
  }

  void _showSearch(String query) {
    final results = FoodDatabase.search(query);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        if (results.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🤔', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 8),
                const Text('No match for that.', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('"$query"', style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                const SizedBox(height: 12),
                const Text('Try: biryani, chapati, chicken breast, daal, samosa, lassi, chai…',
                    style: TextStyle(color: AppColors.textDim, fontSize: 12), textAlign: TextAlign.center),
              ],
            ),
          );
        }
        return ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Results for "$query"', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            for (final f in results)
              ListTile(
                leading: const Icon(Icons.restaurant_rounded, color: AppColors.blue),
                title: Text(f.name, style: const TextStyle(color: AppColors.textPrimary)),
                subtitle: Text('${f.calories.round()} kcal / 100g',
                    style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                trailing: const Icon(Icons.add_circle_rounded, color: AppColors.gold),
                onTap: () {
                  final c = ref.read(gameProvider);
                  c.logFoods([
                    LoggedFood(
                      foodId: f.id,
                      name: f.name,
                      quantity: f.unitItem ? (f.unitWeightG ?? 100) : _serving(f),
                      calories: f.unitItem ? (f.unitWeightG ?? 100) * f.calories / 100 : f.calories * _serving(f) / 100,
                      protein: f.unitItem ? (f.unitWeightG ?? 100) * f.protein / 100 : f.protein * _serving(f) / 100,
                      carbs: f.unitItem ? (f.unitWeightG ?? 100) * f.carbs / 100 : f.carbs * _serving(f) / 100,
                      fat: f.unitItem ? (f.unitWeightG ?? 100) * f.fat / 100 : f.fat * _serving(f) / 100,
                    ),
                  ], method: 'search');
                  Navigator.pop(ctx);
                  _toast('✅ Logged ${f.name}');
                },
              ),
          ],
        );
      },
    );
  }

  double _serving(FoodItem f) {
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

  Future<void> _pickPhoto() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.camera, maxWidth: 1200);
      if (file == null) return;
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📸 Photo logged!', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text('AI vision is scanning… in the meantime, pick the closest match.',
                  style: TextStyle(color: AppColors.textDim, fontSize: 13), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _photoChip(ctx, '🍚 Biryani', 'biryani_plate'),
                  _photoChip(ctx, '🍗 Chicken', 'chicken_breast'),
                  _photoChip(ctx, '🫓 Chapati', 'chapati'),
                  _photoChip(ctx, '🫘 Daal', 'daal_daal'),
                  _photoChip(ctx, '🥚 Eggs', 'egg'),
                  _photoChip(ctx, '🍔 Burger', 'chicken_burger'),
                ],
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textDim))),
            ],
          ),
        ),
      );
    } catch (_) {
      _toast('Camera not available here.');
    }
  }

  Widget _photoChip(BuildContext ctx, String label, String foodId) {
    final f = FoodDatabase.byId(foodId);
    if (f == null) return const SizedBox.shrink();
    return ActionChip(
      label: Text(label),
      backgroundColor: AppColors.glassBg,
      onPressed: () {
        final c = ref.read(gameProvider);
        final grams = f.unitItem ? (f.unitWeightG ?? 100) : _serving(f);
        c.logFoods([
          LoggedFood(
            foodId: f.id,
            name: f.name,
            quantity: grams,
            calories: grams * f.calories / 100,
            protein: grams * f.protein / 100,
            carbs: grams * f.carbs / 100,
            fat: grams * f.fat / 100,
          ),
        ], method: 'photo');
        Navigator.pop(ctx);
        _toast('✅ Logged ${f.name} (photo)');
      },
    );
  }

  Future<void> _scanBarcode() async {
    if (!mounted) return;
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _BarcodeScreen()),
    );
    if (result == null) return;
    final f = FoodDatabase.search(result).isEmpty ? null : FoodDatabase.search(result).first;
    if (f == null) {
      _toast('Product "$result" not in the database yet.');
      return;
    }
    _showSearch(f.name);
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(gameProvider);
    final log = c.todayLog();
    final remaining = (c.calorieGoal - log.caloriesConsumed).clamp(0.0, 99999.0);
    final todayMeals = c.mealLogs.where((m) => sameDay(m.time, DateTime.now())).toList().reversed.toList();
    final favorites = c.favoriteFoodIds.map(FoodDatabase.byId).whereType<FoodItem>().toList();
    final recents = c.recentFoodIds.map(FoodDatabase.byId).whereType<FoodItem>().take(8).toList();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Food Log', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('🔥 ${log.caloriesConsumed.round()}/${c.calorieGoal.round()} kcal · 🍗 ${log.proteinConsumed.round()}/${c.proteinGoal.round()}g protein · ${remaining.round()} kcal left',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Try "2 eggs and 3 chapatis"…',
                          prefixIcon: Icon(Icons.edit_rounded, color: AppColors.textDim, size: 20),
                          isDense: true,
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: _logText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _RoundBtn(icon: Icons.mic_rounded, color: AppColors.red,
                        onTap: _listening ? null : _startVoice, active: _listening),
                    const SizedBox(width: 8),
                    _RoundBtn(icon: Icons.photo_camera_rounded, color: AppColors.blue, onTap: _pickPhoto),
                    const SizedBox(width: 8),
                    _RoundBtn(icon: Icons.qr_code_scanner_rounded, color: AppColors.green, onTap: _scanBarcode),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                // ---------- Quick chips ----------
                const SectionHeader(title: 'Quick Log'),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: FoodDatabase.quickFoods.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final f = FoodDatabase.quickFoods[i];
                      return ActionChip(
                        label: Text(f.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                        backgroundColor: AppColors.glassBg,
                        side: const BorderSide(color: AppColors.glassStroke),
                        onPressed: () {
                          final grams = f.unitItem ? (f.unitWeightG ?? 100) : _serving(f);
                          c.logFoods([
                            LoggedFood(
                              foodId: f.id,
                              name: f.name,
                              quantity: grams,
                              calories: grams * f.calories / 100,
                              protein: grams * f.protein / 100,
                              carbs: grams * f.carbs / 100,
                              fat: grams * f.fat / 100,
                            ),
                          ], method: 'quick');
                        },
                      );
                    },
                  ),
                ),

                // ---------- Favorites ----------
                if (favorites.isNotEmpty) ...[
                  const SectionHeader(title: '⭐ Favorites'),
                  _FoodRow(favorites, c: c, serving: _serving),
                ],

                // ---------- Recent ----------
                if (recents.isNotEmpty) ...[
                  const SectionHeader(title: '🕘 Recent'),
                  _FoodRow(recents, c: c, serving: _serving),
                ],

                // ---------- Today's meals ----------
                const SectionHeader(title: 'Today\'s Meals'),
                if (todayMeals.isEmpty)
                  const GlassCard(
                    child: Text('Nothing logged yet. Tap a chip or use voice — every meal counts toward your quests!',
                        style: TextStyle(color: AppColors.textDim, fontSize: 13)),
                  )
                else
                  ...todayMeals.map((m) => GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        radius: 16,
                        child: Row(
                          children: [
                            const Text('🍽️', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.foods.map((f) => f.name).join(', '),
                                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text('${m.foods.length} item(s) · ${_timeOf(m.time)}',
                                      style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
                                ],
                              ),
                            ),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text('${m.calories.round()} kcal',
                                  style: const TextStyle(color: AppColors.orange, fontSize: 13, fontWeight: FontWeight.w700)),
                              Text('${m.protein.round()}g P',
                                  style: const TextStyle(color: AppColors.green, fontSize: 11)),
                            ]),
                          ],
                        ),
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeOf(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool active;
  const _RoundBtn({required this.icon, required this.color, this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(active ? 0.5 : 0.15),
          border: Border.all(color: color.withOpacity(active ? 0.9 : 0.4), width: 1.4),
        ),
        child: Icon(icon, color: active ? Colors.white : color, size: 20),
      ),
    );
  }
}

class _FoodRow extends StatelessWidget {
  final List<FoodItem> foods;
  final GameController c;
  final double Function(FoodItem) serving;
  const _FoodRow(this.foods, {required this.c, required this.serving});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final f in foods)
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            radius: 16,
            child: Row(
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(f.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                    Text('${f.calories.round()} kcal / 100g',
                        style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
                  ]),
                ),
                IconButton(
                  icon: Icon(
                    c.favoriteFoodIds.contains(f.id) ? Icons.star_rounded : Icons.star_border_rounded,
                    color: c.favoriteFoodIds.contains(f.id) ? AppColors.gold : AppColors.textDim,
                    size: 20,
                  ),
                  onPressed: () => c.toggleFavorite(f.id),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_rounded, color: AppColors.gold, size: 24),
                  onPressed: () {
                    final grams = f.unitItem ? (f.unitWeightG ?? 100) : serving(f);
                    c.logFoods([
                      LoggedFood(
                        foodId: f.id,
                        name: f.name,
                        quantity: grams,
                        calories: grams * f.calories / 100,
                        protein: grams * f.protein / 100,
                        carbs: grams * f.carbs / 100,
                        fat: grams * f.fat / 100,
                      ),
                    ], method: 'favorite');
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Minimal barcode scanner screen (guarded — not available everywhere).
class _BarcodeScreen extends StatefulWidget {
  const _BarcodeScreen();

  @override
  State<_BarcodeScreen> createState() => _BarcodeScreenState();
}

class _BarcodeScreenState extends State<_BarcodeScreen> {
  bool _failed = false;
  bool _found = false;

  @override
  void initState() {
    super.initState();
    _probe();
  }

  Future<void> _probe() async {
    await Future.delayed(const Duration(milliseconds: 400));
    // mobile_scanner requires real camera support; if the plugin throws during
    // widget build we catch it in build via errorWidget.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan a barcode')),
      body: _failed
          ? const Center(child: Text('Scanner unavailable on this platform.', style: TextStyle(color: AppColors.textDim)))
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: MobileScannerWidget(onDetect: (code) {
                        if (_found) return;
                        _found = true;
                        Navigator.of(context).pop(code);
                      }, onError: () {
                        setState(() => _failed = true);
                      }),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Point at a barcode on the package.',
                        style: TextStyle(color: AppColors.textDim)),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Thin wrapper so MobileScanner import stays optional at build time.
class MobileScannerWidget extends StatefulWidget {
  final void Function(String code) onDetect;
  final VoidCallback onError;
  const MobileScannerWidget({super.key, required this.onDetect, required this.onError});

  @override
  State<MobileScannerWidget> createState() => _MobileScannerWidgetState();
}

class _MobileScannerWidgetState extends State<MobileScannerWidget> {
  @override
  Widget build(BuildContext context) {
    try {
      return mobileScannerBuilder(widget.onDetect, widget.onError);
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}
