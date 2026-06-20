import 'dart:async';

import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/hatoppy_widget.dart';
import '../services/compass_service.dart';

/// 移動中の「方位磁針画面」。スマホのコンパスセンサーと連携し、
/// 次に向かう棚エリアへの方角を大きな針で示す。
/// 企画書 4-◆安全性への徹底配慮 に合わせ、最下部に常時「ゆっくりあるこう」の警告を出す。
///
/// 方位角は [CompassService.headingStream]（0〜360度・北=0）から取得し、
/// `turns: heading / 360` に変換して針を回す。
/// センサーが取れない・未許可のときは針を北固定（0度）にして読み込み中表示にする。
class CompassScreen extends StatefulWidget {
  /// 次に向かう棚エリア名（例：「お米売り場」）。
  final String targetAreaName;

  /// 「ここに とうちゃく！」を押したときのコールバック。
  final VoidCallback onArrived;

  const CompassScreen({
    super.key,
    required this.targetAreaName,
    required this.onArrived,
  });

  @override
  State<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> {
  /// コンパスセンサーのサービス。
  final CompassService _compassService = CompassService();

  /// 方位角ストリームの購読。dispose で cancel する。
  StreamSubscription<double>? _subscription;

  /// 一定時間センサー値が来ないときにタップ案内へ切り替えるためのタイマー。
  Timer? _waitTimer;

  /// 現在の方位角（0〜360度）。センサー値が来るまでは北固定（0度）。
  double _heading = 0;

  /// センサー値を1度でも受け取れたか。受け取れるまでは読み込み中表示にする。
  bool _hasHeading = false;

  /// 値が来ないので「コンパスをつかう」タップ案内を出す状態か。
  /// 主に iOS（タップ起点でしか権限を出せない）や、センサーが無い端末向け。
  bool _needsTap = false;

  @override
  void initState() {
    super.initState();
    // Android 等は権限不要でそのまま購読開始できる。
    // iOS は権限がタップ起点必須なので、来なければ後でボタンを出す。
    _subscribe();
    _waitTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_hasHeading) setState(() => _needsTap = true);
    });
  }

  /// 方位角ストリームの購読を（再）開始する。
  void _subscribe() {
    _subscription?.cancel();
    _subscription = _compassService.headingStream.listen((heading) {
      if (!mounted) return;
      setState(() {
        _heading = heading;
        _hasHeading = true;
        _needsTap = false;
      });
    });
  }

  /// ユーザーのタップ起点で権限を要求し、購読をやり直す。
  /// iOS Safari はこの「タップ起点」でしかセンサー許可を出せない。
  Future<void> _enableByTap() async {
    await _compassService.requestPermission();
    if (!mounted) return;
    _subscribe();
    // しばらく待っても来なければ、もう一度案内を出す。
    _waitTimer?.cancel();
    _waitTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_hasHeading) setState(() => _needsTap = true);
    });
    setState(() => _needsTap = false);
  }

  @override
  void dispose() {
    _waitTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: HatoppyTalk(
                message: 'つぎは「${widget.targetAreaName}」へ\nむかおう！',
              ),
            ),
            Expanded(
              child: Center(
                child: _CompassDial(
                  heading: _heading,
                  hasHeading: _hasHeading,
                  needsTap: _needsTap,
                  onEnable: _enableByTap,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onArrived,
                  child: const Text('ここに とうちゃく！'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _SlowWalkBar(),
          ],
        ),
      ),
    );
  }
}

/// 中央の大きなコンパス。方位角に応じて針を AnimatedRotation で回す。
/// センサー値が未取得のときは読み込み中メッセージを表示する。
class _CompassDial extends StatelessWidget {
  /// 現在の方位角（0〜360度）。
  final double heading;

  /// センサー値を受け取れているか。
  final bool hasHeading;

  /// タップで権限を出す案内を表示する状態か。
  final bool needsTap;

  /// 「コンパスをつかう」タップ時のコールバック（ユーザー操作起点の権限要求）。
  final VoidCallback onEnable;

  const _CompassDial({
    required this.heading,
    required this.hasHeading,
    required this.needsTap,
    required this.onEnable,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: AppColors.primaryGreen, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: AnimatedRotation(
            // 0〜360度を回転（turns）に変換して針を回す。
            turns: heading / 360,
            duration: const Duration(milliseconds: 400),
            child: const Icon(
              Icons.navigation,
              size: 100,
              color: AppColors.danger,
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (!hasHeading && !needsTap)
          const Text(
            'コンパスをよみこみちゅう…',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        // 値が来ないとき（主に iOS の権限待ち）はタップで許可を出す。
        if (needsTap) ...[
          ElevatedButton.icon(
            onPressed: onEnable,
            icon: const Icon(Icons.explore),
            label: const Text('コンパスをつかう'),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'うごかないときは「ここに とうちゃく！」を\nおして つぎへ すすめるよ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.textDark.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// 画面最下部に常時表示する警告バー。黄色背景でゆっくり歩くことを促す。
class _SlowWalkBar extends StatelessWidget {
  const _SlowWalkBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.accentYellow,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: const Text(
        '🐢 ゆっくりあるこうね',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: AppColors.textDark,
        ),
      ),
    );
  }
}
