import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/point_service.dart';

/// おつかい完了後の「ポイント確認画面」。
/// 今回獲得したポイントと累計ポイントを表示し、
/// 累計がしきい値に届いていればシール交換できることを伝える。
///
/// 累計ポイントは [PointService.loadTotal] で非同期に読み込む。
/// 読み込み中は CircularProgressIndicator を表示する。
class PointScreen extends StatefulWidget {
  /// 今回のおつかいで獲得したポイント。
  final int earnedPoints;

  /// 「ホームにもどる」を押したときのコールバック。
  final VoidCallback onBackToHome;

  const PointScreen({
    super.key,
    required this.earnedPoints,
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

  /// PointService から累計ポイントを読み込み、setState で反映する。
  Future<void> _loadTotal() async {
    final total = await PointService.loadTotal();
    if (mounted) {
      setState(() => _totalPoints = total);
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
    // しきい値まであと何ポイントか（達成済みなら 0）。
    final remaining = PointService.stickerThreshold - total;
    final reachedThreshold = remaining <= 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 12),
          const Text('🎉', style: TextStyle(fontSize: 56)),
          const Text(
            'おつかい大成功！',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '大人にスマホをかえしてね',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 24),
          _EarnedPointsCard(earnedPoints: widget.earnedPoints),
          const SizedBox(height: 16),
          _TotalPointsCard(total: total),
          const SizedBox(height: 16),
          _StickerBanner(
            reachedThreshold: reachedThreshold,
            remaining: remaining,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: widget.onBackToHome,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
              ),
              child: const Text('ホームにもどる'),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

/// 累計ポイント読み込み中に表示するローディング表示。
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

/// 累計ポイントの状態に応じてシール交換の案内を出すバナー。
/// しきい値以上なら緑で「交換できるよ！」、未満なら残りポイントを表示する。
class _StickerBanner extends StatelessWidget {
  final bool reachedThreshold;
  final int remaining;

  const _StickerBanner({
    required this.reachedThreshold,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    if (reachedThreshold) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          children: [
            Text('🎟️', style: TextStyle(fontSize: 28)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'シールと交換できるよ！',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.accentYellow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Text('🎟️', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'あと$remainingポイントでシール交換！',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
