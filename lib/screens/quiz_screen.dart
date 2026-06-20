import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/hatoppy_widget.dart';

enum _Phase { idle, scanning, quiz, result }

/// 企画書「② はとっぴーの地産地消おつかいクイズ」を再現する画面。
/// スキャン演出 → レジゴーへのカゴ追加演出 → はとっぴーのクイズ → 正誤フィードバック
/// の順に進む。正解した場合のみ Navigator.pop(true) でバッジ獲得を呼び出し元に伝える。
class QuizScreen extends StatefulWidget {
  final ShoppingItem item;
  const QuizScreen({super.key, required this.item});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  _Phase _phase = _Phase.idle;
  bool _isCorrect = false;

  Future<void> _startScan() async {
    setState(() => _phase = _Phase.scanning);
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    setState(() => _phase = _Phase.quiz);
  }

  void _selectChoice(int index) {
    if (_phase != _Phase.quiz) return;
    setState(() {
      _isCorrect = index == widget.item.correctIndex;
      _phase = _Phase.result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      appBar: AppBar(title: Text(item.area)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: switch (_phase) {
            _Phase.idle => _IdleView(item: item, onScan: _startScan),
            _Phase.scanning => const _ScanningView(),
            _Phase.quiz => _QuizView(item: item, onSelect: _selectChoice),
            _Phase.result => _ResultView(
                item: item,
                isCorrect: _isCorrect,
                onNext: () => Navigator.of(context).pop(_isCorrect),
              ),
          },
        ),
      ),
    );
  }
}

class _IdleView extends StatelessWidget {
  final ShoppingItem item;
  final VoidCallback onScan;
  const _IdleView({required this.item, required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        Text(item.emoji, style: const TextStyle(fontSize: 90)),
        const SizedBox(height: 14),
        Text(
          item.name,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreenDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '棚で見つけたら、スマホカメラで\nバーコードをスキャンしよう！',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textDark.withOpacity(0.6)),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onScan,
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text('商品をスキャンする'),
          ),
        ),
      ],
    );
  }
}

class _ScanningView extends StatelessWidget {
  const _ScanningView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primaryGreen),
          SizedBox(height: 18),
          Text(
            'スキャン中…\nレジゴーのカゴに追加しています',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _QuizView extends StatelessWidget {
  final ShoppingItem item;
  final ValueChanged<int> onSelect;
  const _QuizView({required this.item, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.accentYellow,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: const Text(
            '✅ レジゴーのカゴに追加されました！',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        const SizedBox(height: 16),
        HatoppyTalk(message: item.question),
        const SizedBox(height: 22),
        Expanded(
          child: ListView.separated(
            itemCount: item.choices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return OutlinedButton(
                onPressed: () => onSelect(index),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                ),
                child: Text(item.choices[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  final ShoppingItem item;
  final bool isCorrect;
  final VoidCallback onNext;

  const _ResultView({
    required this.item,
    required this.isCorrect,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.4, end: 1.0),
          duration: const Duration(milliseconds: 450),
          curve: Curves.elasticOut,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Icon(
            isCorrect ? Icons.celebration_rounded : Icons.lightbulb_rounded,
            color: isCorrect ? AppColors.accentOrange : AppColors.primaryGreen,
            size: 80,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isCorrect ? 'せいかい！🎉' : 'おしい！',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.primaryGreenDark,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBeige,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            item.explanation,
            textAlign: TextAlign.center,
            style: const TextStyle(height: 1.6, fontSize: 14),
          ),
        ),
        if (isCorrect) ...[
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accentOrange, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item.badgeEmoji, style: const TextStyle(fontSize: 30)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '限定バッジをゲット！',
                      style: TextStyle(fontSize: 11, color: AppColors.textDark),
                    ),
                    Text(
                      item.badgeName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreenDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onNext,
            child: const Text('つぎへ'),
          ),
        ),
      ],
    );
  }
}
