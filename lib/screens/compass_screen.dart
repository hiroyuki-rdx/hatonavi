import 'dart:async';

import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/hatoppy_widget.dart';
import '../services/compass_service.dart';
import '../services/motion_service.dart';
import '../services/speech_service.dart';

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

  /// 走行検知（歩きスマホ・走り回り防止ロック）のサービス。
  final MotionService _motionService = MotionService();

  /// 方位角ストリームの購読。dispose で cancel する。
  StreamSubscription<double>? _subscription;

  /// 走行検知ストリームの購読。dispose で cancel する。
  StreamSubscription<bool>? _motionSub;

  /// 走っている（激しく動いている）間 true。true の間はロック画面を被せる。
  bool _isRunning = false;

  /// 一定時間センサー値が来ないときにタップ案内へ切り替えるためのタイマー。
  Timer? _waitTimer;

  /// 針の連続回転量（turns）。0〜1に折り返さず累積し、針を最短回りで回す。
  double _turns = 0;

  /// 直前に受け取った方位角（最短回りの差分計算用）。
  double _lastHeading = 0;

  /// 最初の方位を受け取ったか（初回は差分ではなく直接セット）。
  bool _hasFirstHeading = false;

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
    _subscribeMotion();
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
        // 0/360 をまたいでも針が最短回りで回るよう、差分を累積する。
        if (!_hasFirstHeading) {
          _hasFirstHeading = true;
          _turns = heading / 360;
        } else {
          double delta = heading - _lastHeading;
          while (delta > 180) delta -= 360;
          while (delta < -180) delta += 360;
          _turns += delta / 360;
        }
        _lastHeading = heading;
        _hasHeading = true;
        _needsTap = false;
      });
    });
  }

  /// 走行検知ストリームの購読を（再）開始する。
  /// センサー非対応・未許可なら何も流れないのでロックは出ない（通常進行）。
  void _subscribeMotion() {
    _motionSub?.cancel();
    _motionSub = _motionService.runningStream.listen((running) {
      if (!mounted) return;
      // 走り始めた瞬間（false→true）に音声でも止めるよう促す。
      // runningStream は状態変化時のみ流れるので、ここで多重再生にならない。
      if (running) {
        SpeechService.speak('とまって！ まえをみて ゆっくりあるこうね');
      }
      setState(() => _isRunning = running);
    });
  }

  /// ユーザーのタップ起点で権限を要求し、購読をやり直す。
  /// iOS Safari はこの「タップ起点」でしかセンサー許可を出せない。
  Future<void> _enableByTap() async {
    // コンパスと走行検知の両方を、ユーザー操作起点でまとめて許可要求する。
    await _compassService.requestPermission();
    await _motionService.requestPermission();
    if (!mounted) return;
    _subscribe();
    _subscribeMotion();
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
    _motionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // NavigationScreen の Scaffold 内に埋め込んで使うため、ここでは
    // Scaffold を持たず Column のみを返す（Scaffold 二重ネスト回避）。
    // 到着ボタンと警告バーが常に画面内に収まるレイアウトにしている。
    // 走行検知中は上から赤いロック画面を被せて「とまって」と促す。
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: HatoppyTalk(
                message: 'つぎは「${widget.targetAreaName}」へ\nむかおう！',
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: _CompassDial(
                    turns: _turns,
                    hasHeading: _hasHeading,
                    needsTap: _needsTap,
                    onEnable: _enableByTap,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onArrived,
                  child: const Text('ここに とうちゃく！'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const _SlowWalkBar(),
          ],
        ),
        if (_isRunning) const Positioned.fill(child: _RunLockOverlay()),
      ],
    );
  }
}

/// 走行検知中に全面を覆う「とまって！」ロック画面。
/// 企画書 4-◆安全性／審査員アドバイス（速度検知でロック）に対応。
class _RunLockOverlay extends StatelessWidget {
  const _RunLockOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.danger.withOpacity(0.96),
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pan_tool_rounded, color: Colors.white, size: 72),
          SizedBox(height: 20),
          Text(
            'とまって！',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'まえをみて\nゆっくりあるこうね',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              height: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// 中央の大きなコンパス。方位角に応じて針を AnimatedRotation で回す。
/// センサー値が未取得のときは読み込み中メッセージを表示する。
class _CompassDial extends StatelessWidget {
  /// 針の連続回転量（turns, 0〜1に折り返さない累積値）。
  final double turns;

  /// センサー値を受け取れているか。
  final bool hasHeading;

  /// タップで権限を出す案内を表示する状態か。
  final bool needsTap;

  /// 「コンパスをつかう」タップ時のコールバック（ユーザー操作起点の権限要求）。
  final VoidCallback onEnable;

  const _CompassDial({
    required this.turns,
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
            // 連続化した turns で最短回りに回す（0/360の折り返しでも自然）。
            turns: turns,
            duration: const Duration(milliseconds: 300),
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
