import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/hatoppy_widget.dart';
import '../services/gemini_service.dart';

enum _Phase { idle, camera, adding, quiz, result }

/// 企画書「② はとっぴーの地産地消おつかいクイズ」を再現する画面。
/// スキャン演出 → ピピットセルフへのカゴ追加演出 → はとっぴーのクイズ → 正誤フィードバック
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

  /// Gemini が生成したクイズ。null のときは ShoppingItem の固定クイズを使う。
  GeneratedQuiz? _quiz;

  // 実際に出題する各要素（Gemini生成 → なければ固定クイズにフォールバック）。
  String get _question => _quiz?.question ?? widget.item.question;
  List<String> get _choices => _quiz?.choices ?? widget.item.choices;
  int get _correctIndex => _quiz?.correctIndex ?? widget.item.correctIndex;
  String get _explanation => _quiz?.explanation ?? widget.item.explanation;

  /// 「商品をスキャンする」→ 実カメラを起動する。
  void _startScan() {
    setState(() => _phase = _Phase.camera);
  }

  /// バーコードを読み取った（または読めずスキップした）ときの処理。
  /// デモではどのバーコードでも先へ進む（本番は code を janCode と照合する想定）。
  Future<void> _onScanned(String? code) async {
    if (_phase != _Phase.camera) return;
    setState(() => _phase = _Phase.adding); // 「カゴに追加」の演出
    // 追加演出の裏で Gemini にクイズ生成を依頼（失敗時は固定クイズ）。
    final gen = await GeminiService.generateQuiz(widget.item);
    if (!mounted) return;
    setState(() {
      _quiz = gen;
      _phase = _Phase.quiz;
    });
  }

  void _selectChoice(int index) {
    if (_phase != _Phase.quiz) return;
    setState(() {
      _isCorrect = index == _correctIndex;
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
            _Phase.camera => _ScannerView(
                onScanned: _onScanned,
                onSkip: () => _onScanned(null),
              ),
            _Phase.adding => const _ScanningView(),
            _Phase.quiz => _QuizView(
                question: _question,
                choices: _choices,
                onSelect: _selectChoice,
              ),
            _Phase.result => _ResultView(
                item: item,
                explanation: _explanation,
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
            'スキャン中…\nピピットセルフのカゴに追加しています',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// 実カメラでバーコードを読み取るビュー（mobile_scanner v7）。
/// ピピットセルフのスキャン体験そのもの。カメラが使えない端末では
/// errorBuilder＋下のボタンで「スキップ」して先へ進める（デモが止まらない）。
class _ScannerView extends StatefulWidget {
  /// バーコードを読み取れたら、その文字列を渡して呼ばれる。
  final ValueChanged<String?> onScanned;

  /// カメラが使えない/読み取れないときに先へ進むためのスキップ。
  final VoidCallback onSkip;

  const _ScannerView({required this.onScanned, required this.onSkip});

  @override
  State<_ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<_ScannerView> {
  /// 多重発火を防ぐフラグ（onDetect は連続で呼ばれるため）。
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final code = capture.barcodes.isNotEmpty
        ? capture.barcodes.first.rawValue
        : null;
    if (code == null || code.isEmpty) return;
    _handled = true;
    widget.onScanned(code);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          '商品のバーコードを\nわくの中にうつしてね',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: MobileScanner(
              onDetect: _onDetect,
              // カメラ権限なし・非対応端末では案内＋スキップを出す。
              errorBuilder: (context, error) =>
                  _ScanErrorView(onSkip: widget.onSkip),
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextButton(
          onPressed: widget.onSkip,
          child: const Text('うまく よみとれない ときは ここをタップ'),
        ),
      ],
    );
  }
}

/// カメラが使えない/権限拒否のときの表示。タップで先へ進める。
class _ScanErrorView extends StatelessWidget {
  final VoidCallback onSkip;
  const _ScanErrorView({required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cardBeige,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.no_photography_rounded,
              size: 48, color: AppColors.textDark),
          const SizedBox(height: 12),
          const Text(
            'カメラが つかえないみたい。\n「つぎへ」で すすめるよ',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, height: 1.5),
          ),
          const SizedBox(height: 14),
          ElevatedButton(onPressed: onSkip, child: const Text('つぎへ すすむ')),
        ],
      ),
    );
  }
}

class _QuizView extends StatelessWidget {
  final String question;
  final List<String> choices;
  final ValueChanged<int> onSelect;
  const _QuizView({
    required this.question,
    required this.choices,
    required this.onSelect,
  });

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
            '✅ ピピットセルフのカゴに追加されました！',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        const SizedBox(height: 16),
        HatoppyTalk(message: question),
        const SizedBox(height: 22),
        Expanded(
          child: ListView.separated(
            itemCount: choices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return OutlinedButton(
                onPressed: () => onSelect(index),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                ),
                child: Text(choices[index]),
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
  final String explanation;
  final bool isCorrect;
  final VoidCallback onNext;

  const _ResultView({
    required this.item,
    required this.explanation,
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
            explanation,
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
