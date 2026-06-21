import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/point_service.dart';
import '../widgets/sticker_ticket.dart';

/// ポイント確認・シール交換画面。
///
/// おつかい完了後（[earnedPoints] > 0）にも、ホームの「ポイント・シールこうかん」
/// ボタン（[fromHome] = true）からも開ける。
/// 2ポイントで1スタンプ、5スタンプ（＝10ポイント）たまるとシールと交換できる。
/// 累計ポイントは [PointService.loadTotal] で非同期に読み込む。
class PointScreen extends StatefulWidget {
  /// 今回のおつかいで獲得したポイント（ホームから開いたときは 0）。
  final int earnedPoints;

  /// ホームから開いたか（true のときは「今回のポイント」等を出さない）。
  final bool fromHome;

  /// 「ホームにもどる」を押したときのコールバック。
  final VoidCallback onBackToHome;

  const PointScreen({
    super.key,
    this.earnedPoints = 0,
    this.fromHome = false,
    required this.onBackToHome,
  });

  @override
  State<PointScreen> createState() => _PointScreenState();
}

class _PointScreenState extends State<PointScreen> {
  /// 累計ポイント。読み込み完了までは null。
  int? _totalPoints;

  @override
  void initState() {
    super.initState();
    _loadTotal();
  }

  Future<void> _loadTotal() async {
    final total = await PointService.loadTotal();
    if (mounted) setState(() => _totalPoints = total);
  }

  /// シール交換：引換券を見せ、「こうかん完了」を押したら累計から差し引く。
  Future<void> _exchange() async {
    final done = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const StickerTicket(),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('こうかんした！'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('とじる',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );

    if (done == true) {
      final next = await PointService.redeem(); // 累計から10P差し引く
      if (!mounted) return;
      setState(() => _totalPoints = next);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('シールと こうかんしたよ！🎟️')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreenDark,
      body: SafeArea(
        child: _totalPoints == null
            ? const _LoadingView()
            : _buildResult(context, _totalPoints!),
      ),
    );
  }

  Widget _buildResult(BuildContext context, int total) {
    final stamps = PointService.stampsFor(total);
    final canRedeem = PointService.canRedeem(total);
    // 次のスタンプまであと何ポイントか。
    final toNextStamp = PointService.pointsPerStamp - (total % PointService.pointsPerStamp);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Text(
            widget.fromHome ? '🎟️' : '🎉',
            style: const TextStyle(fontSize: 56),
          ),
          Text(
            widget.fromHome ? 'ポイント・シールこうかん' : 'おつかい大成功！',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          if (!widget.fromHome) ...[
            const SizedBox(height: 8),
            const Text(
              '大人にスマホをかえしてね',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
          const SizedBox(height: 24),
          if (!widget.fromHome && widget.earnedPoints > 0) ...[
            _EarnedPointsCard(earnedPoints: widget.earnedPoints),
            const SizedBox(height: 16),
          ],
          _TotalPointsCard(total: total),
          const SizedBox(height: 16),
          // スタンプカード（2ポイントで1こ・5こでシール交換）。
          _StampCard(
            stamps: stamps,
            max: PointService.stampsToRedeem,
            canRedeem: canRedeem,
            toNextStamp: toNextStamp,
          ),
          const SizedBox(height: 20),
          // 交換は10ポイント（5スタンプ）たまったときだけ表示する。
          if (canRedeem)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _exchange,
                icon: const Icon(Icons.card_giftcard_rounded),
                label: const Text('シールとこうかんする'),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: widget.onBackToHome,
              style: OutlinedButton.styleFrom(backgroundColor: Colors.white),
              child: const Text('ホームにもどる'),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 20),
          Text(
            'ポイントをかぞえているよ…',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// 今回獲得したポイントを大きく表示するカード。
class _EarnedPointsCard extends StatelessWidget {
  final int earnedPoints;

  const _EarnedPointsCard({required this.earnedPoints});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'こんかいのポイント',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$earnedPoints',
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: AppColors.accentOrange,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'P',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.accentOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 累計ポイントを表示するカード。
class _TotalPointsCard extends StatelessWidget {
  final int total;

  const _TotalPointsCard({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.cardBeige,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('⭐', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          const Text(
            'ためたポイント',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$total P',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryGreenDark,
            ),
          ),
        ],
      ),
    );
  }
}

/// スタンプカード。2ポイントで1スタンプ、5スタンプでシール交換。
class _StampCard extends StatelessWidget {
  final int stamps;
  final int max;
  final bool canRedeem;
  final int toNextStamp;

  const _StampCard({
    required this.stamps,
    required this.max,
    required this.canRedeem,
    required this.toNextStamp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'スタンプカード（2ポイントで 1こ）',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (int i = 0; i < max; i++) _StampSlot(filled: i < stamps),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            canRedeem
                ? '5こ そろったよ！シールと こうかんできる🎟️'
                : 'あと ${max - stamps} こで シールこうかん（つぎのスタンプまで あと $toNextStamp P）',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.bold,
              color: canRedeem ? AppColors.primaryGreen : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

/// スタンプ1つ分のマス。押されていれば🐤、空なら点線まる。
class _StampSlot extends StatelessWidget {
  final bool filled;
  const _StampSlot({required this.filled});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? AppColors.accentOrange : AppColors.cardBeige,
        border: Border.all(
          color: filled ? AppColors.accentOrange : Colors.black26,
          width: 2,
        ),
      ),
      child: Text(
        filled ? '🕊️' : '',
        style: const TextStyle(fontSize: 22),
      ),
    );
  }
}
