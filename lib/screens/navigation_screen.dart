import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/hatoppy_widget.dart';
import 'quiz_screen.dart';
import 'sticker_screen.dart';

/// 企画書の「① AIルートナビシステム」を再現する画面。
/// ・全ルートは見せず、次の棚エリアだけをミッション形式で1つずつ提示
/// ・移動中は加速度センサーの代わりにタイマーで「歩きスマホ防止ロック」を演出
/// ・2件目到達時に「危険箇所ポップアップ」のデモも表示
class NavigationScreen extends StatefulWidget {
  final List<ShoppingItem> items;
  const NavigationScreen({super.key, required this.items});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int _index = 0;
  bool _locked = true;
  bool _hazardShown = false;
  final List<ShoppingItem> _collected = [];

  @override
  void initState() {
    super.initState();
    _revealCurrentMission();
  }

  /// 「歩きスマホ防止ロック」→「次のミッション提示」を演出する。
  Future<void> _revealCurrentMission() async {
    setState(() => _locked = true);
    await Future.delayed(const Duration(milliseconds: 1700));
    if (!mounted) return;
    setState(() => _locked = false);

    if (_index == 1 && !_hazardShown) {
      _hazardShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showHazardAlert());
    }
  }

  void _showHazardAlert() {
    if (!mounted) return;
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
          ),
        ),
      );
    } else {
      setState(() => _index++);
      await _revealCurrentMission();
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.items.length;
    final current = widget.items[_index];

    return Scaffold(
      appBar: AppBar(title: const Text('はとナビ AIルート案内')),
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
              child: _locked
                  ? _WalkLockView(key: const ValueKey('locked'))
                  : _MissionView(
                      key: ValueKey('mission-${current.id}'),
                      item: current,
                      onArrived: _onArrived,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 「歩行中（移動中）」を検知して自動でかかる画面ロックの演出。
/// 実機ではスマホの加速度センサーで歩行を検知する想定。
class _WalkLockView extends StatelessWidget {
  const _WalkLockView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('lock-bg'),
      width: double.infinity,
      color: AppColors.primaryGreenDark,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.phonelink_lock, color: Colors.white, size: 64),
            const SizedBox(height: 16),
            const Text(
              '画面ロック中',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '前を見て歩こう！',
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
            const SizedBox(height: 28),
            const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 40),
            const SizedBox(height: 8),
            const Text(
              'すすむ方向',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// 次の棚エリアを1つだけ提示するミッションカード。
class _MissionView extends StatelessWidget {
  final ShoppingItem item;
  final VoidCallback onArrived;
  const _MissionView({super.key, required this.item, required this.onArrived});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          HatoppyTalk(message: '次は『${item.area}』へ\nむかえ！'),
          const SizedBox(height: 28),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.accentOrange, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item.emoji, style: const TextStyle(fontSize: 72)),
                  const SizedBox(height: 12),
                  Text(
                    item.area,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryGreenDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '「${item.name}」をさがしてね',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textDark.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onArrived,
              icon: const Icon(Icons.flag_rounded),
              label: const Text('棚エリアに到着！'),
            ),
          ),
        ],
      ),
    );
  }
}
