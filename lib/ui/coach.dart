import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/models.dart';
import '../core/state.dart';
import 'widgets.dart';

class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  bool _busy = false;

  static const _suggestions = [
    'I ate biryani',
    'Meal ideas',
    'Workout',
    'Healthier alternative for paratha',
    'Grocery list',
    'When will I reach 85kg?',
    'I feel like giving up',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _busy) return;
    _controller.clear();
    setState(() => _busy = true);
    await ref.read(gameProvider).coachSend(text.trim());
    if (mounted) {
      setState(() => _busy = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(gameProvider);
    final messages = c.chatHistory;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [AppColors.gold, AppColors.orange]),
                  ),
                  child: const Center(child: Text('🤖', style: TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Coach Reforge',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w800)),
                    Text('AI trainer · remembers everything · never shames',
                        style: TextStyle(color: AppColors.textDim, fontSize: 11)),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text('${c.streakDays.round()}-day streak',
                      style: const TextStyle(color: AppColors.green, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Expanded(
            child: messages.isEmpty
                ? _EmptyCoach(onPick: _send)
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: messages.length + (_busy ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i >= messages.length) {
                        return const _Typing();
                      }
                      final m = messages[i];
                      return _Bubble(msg: m);
                    },
                  ),
          ),
          if (messages.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SuggestionChips(suggestions: _suggestions, onPick: _send),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Message Coach Reforge…',
                        prefixIcon: Icon(Icons.smart_toy_rounded, color: AppColors.textDim, size: 20),
                        isDense: true,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: _send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    shape: const CircleBorder(),
                    color: AppColors.gold,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _busy ? null : () => _send(_controller.text),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.send_rounded, color: Color(0xFF1A1204), size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage msg;
  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isCoach = msg.role == 'coach';
    return Align(
      alignment: isCoach ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        decoration: BoxDecoration(
          color: isCoach ? AppColors.glassBgStrong : AppColors.blue.withOpacity(0.35),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isCoach ? 4 : 18),
            bottomRight: Radius.circular(isCoach ? 18 : 4),
          ),
        ),
        child: Text(msg.text,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5, height: 1.4)),
      ),
    );
  }
}

class _Typing extends StatelessWidget {
  const _Typing();
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.glassBg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Text('🤖', style: TextStyle(fontSize: 14)),
          SizedBox(width: 8),
          SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold)),
        ]),
      ),
    );
  }
}

class _EmptyCoach extends StatelessWidget {
  final ValueChanged<String> onPick;
  const _EmptyCoach({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 12),
        const Text('🦸', style: TextStyle(fontSize: 56), textAlign: TextAlign.center),
        const SizedBox(height: 10),
        const Text('Coach Reforge',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text(
          'Your personal trainer, nutritionist and accountability partner.\n\n'
          'Log food in plain language, ask for meal ideas, get workout plans, '
          'predict your goal date — and never be shamed, only leveled up.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textDim, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 20),
        const Text('💡 Try:',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        ..._emptySamples.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => onPick(s),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  radius: 14,
                  child: Text(s, style: const TextStyle(color: AppColors.blue, fontSize: 13)),
                ),
              ),
            )),
      ],
    );
  }

  static const _emptySamples = [
    'I ate biryani',
    'What should I eat for fat loss?',
    'Give me a home workout',
    'When will I reach 85 kg?',
    'I ate too much today',
  ];
}

class _SuggestionChips extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onPick;
  const _SuggestionChips({required this.suggestions, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => ActionChip(
          label: Text(suggestions[i], style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
          backgroundColor: AppColors.glassBg,
          side: const BorderSide(color: AppColors.glassStroke),
          onPressed: () => onPick(suggestions[i]),
        ),
      ),
    );
  }
}
