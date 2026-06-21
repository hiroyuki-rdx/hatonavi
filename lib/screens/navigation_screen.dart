import 'dart:math';

import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';
import '../services/speech_service.dart';
import 'compass_screen.dart';
import 'quiz_screen.dart';
import 'sticker_screen.dart';

/// 企画書の「① 巡回順ナビ（順番はAIが提案・ナビ制御はローカル）」を再現する画面。
/// ・全ルートは見せず、次の棚エリアだけをミッション形式で1つずつ提示
/// ・移動中は A作成の [CompassScreen]（方位磁針＋目的地表示＋到着ボタン）で案内する
/// ・2件目到達時に「危険箇所ポップアップ」のデモも表示
class NavigationScreen extends StatefulWidget {
  final List<ShoppingItem> items;
  const NavigationScreen({super.key, required this.items});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int _index = 0;
  bool _hazardShown = false;
  final List<ShoppingItem> _collected = [];

  @override
  void initState() {
    super.initState();
    _maybeShowHazardForCurrentMission();
  }

  /// 2件目（_index == 1）のミッションに入ったとき、一度だけ危険箇所アラートを出す。
  void _maybeShowHazardForCurrentMission() {
    if (_index == 1 && !_hazardShown) {
      _hazardShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showHazardAlert());
    }
  }

  void _showHazardAlert() {
    if (!mounted) return;
    // 画面の赤いダイアログと同時に、音声でも危険を知らせる（権限不要）。
    SpeechService.speak(hazardAlerts[0]);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.danger),
            SizedBox(width: 8),
            Text('あんぜんアラート'),
          ],
        ),
        content: Text(
          hazardAlerts[0],
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('きをつける！'),
          ),
        ],
      ),
    );
  }

  /// CompassScreen の「ここに とうちゃく！」が押されたら呼ばれる。
  /// クイズへ進み、正解ならバッジを集める。最後ならシール画面へ遷移する。
  Future<void> _onArrived() async {
    final currentItem = widget.items[_index];

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => QuizScreen(item: currentItem)),
    );
    if (!mounted) return;

    if (result == true) {
      setState(() => _collected.add(currentItem));
    }

    final isLast = _index >= widget.items.length - 1;
    if (isLast) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => StickerScreen(
            totalItems: widget.items.length,
            collected: _collected,
            // 獲得ポイントは正解数（集めたバッジ数）とする。
            earnedPoints: _collected.length,
          ),
        ),
      );
    } else {
      setState(() => _index++);
      _maybeShowHazardForCurrentMission();
    }
  }

  /// 【途中追加】リストに無い商品を見つけたときの導線（条件分岐：リスト品＝ミッション
  /// 経由 / リスト外＝このボタン経由）。スキャン→ボーナスクイズ→正解なら +1（はっけん
  /// バッジ）として収集に加える。ピピットセルフが元々スキャン式なので途中追加と相性が良い。
  Future<void> _onScanExtra() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const QuizScreen(item: bonusItem)),
    );
    if (!mounted) return;
    if (ok == true) {
      setState(() => _collected.add(bonusItem));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('リストにない商品も はっけん！＋1ポイント🛒'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// 現在地（origin）から次の売り場（target）への方位角を求める。
  ///
  /// ・origin の売り場ID＝最初(_index==0)はスタート、それ以外は1つ前のミッションの売り場。
  /// ・target の売り場ID＝今回のミッションの売り場。
  /// ・座標は storeAreas（x=東/右, y=北/上, 0..100）から引く。
  /// ・方位角は「北(=上)を0度、時計回り」で返す：
  ///     bearing = atan2(dx, dy) * 180/pi   （dx=東方向, dy=北方向）
  ///   atan2 の第1引数に dx(東)、第2引数に dy(北)を渡すことで、
  ///   北を基準に東(右)回りで増える角度＝コンパスの方位角になる。
  /// ・0..360 に正規化して返す。座標が欠落していれば null。
  double? _bearingToCurrentTarget() {
    final originId = _index == 0 ? 'start' : widget.items[_index - 1].areaId;
    final targetId = widget.items[_index].areaId;
    final origin = storeAreas[originId];
    final target = storeAreas[targetId];
    if (origin == null || target == null) return null;

    final dx = target.x - origin.x; // 東(右)方向の差
    final dy = target.y - origin.y; // 北(上)方向の差
    if (dx == 0 && dy == 0) return null; // 同地点なら方角は定義できない

    double bearing = atan2(dx, dy) * 180 / pi;
    bearing %= 360;
    if (bearing < 0) bearing += 360;
    return bearing;
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.items.length;
    final current = widget.items[_index];
    final targetBearing = _bearingToCurrentTarget();

    return Scaffold(
      appBar: AppBar(
        title: const Text('はとナビ おつかいナビ'),
        actions: [
          IconButton(
            tooltip: 'リストにない商品をスキャン',
            icon: const Icon(Icons.add_shopping_cart_rounded),
            onPressed: _onScanExtra,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (_index) / total,
                    minHeight: 10,
                    backgroundColor: Colors.black12,
                    color: AppColors.accentOrange,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'ミッション ${_index + 1} / $total',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreenDark,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              // 各ミッションで CompassScreen を表示。到着ボタンで _onArrived。
              // ミッションが変わるたびに key を変えてコンパスを作り直す。
              child: CompassScreen(
                key: ValueKey('compass-${current.id}'),
                targetAreaName: current.area,
                targetBearingDeg: targetBearing,
                onArrived: _onArrived,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
